import 'package:flutter/foundation.dart';
import '../models/producto.dart';
import '../models/cupon.dart';

class ItemCarrito {
  final Producto producto;
  int cantidad;
  ItemCarrito({required this.producto, this.cantidad = 1});

  int get subtotal => producto.precioFinal * cantidad;
}

class CarritoProvider extends ChangeNotifier {
  final Map<String, ItemCarrito> _items = {};
  Cupon? _cuponAplicado;

  List<ItemCarrito> get items => _items.values.toList();
  int get cantidadTotal => _items.values.fold(0, (s, i) => s + i.cantidad);
  Cupon? get cuponAplicado => _cuponAplicado;

  int get subtotal => _items.values.fold(0, (s, i) => s + i.subtotal);

  /// Subtotal de los productos a los que aplica el código (todo, categorías o modelos).
  int get subtotalAplicable {
    final c = _cuponAplicado;
    if (c == null) return 0;
    return _items.values
        .where((i) => c.aplicaAProducto(i.producto.categoria, i.producto.modelosCompatibles))
        .fold(0, (s, i) => s + i.subtotal);
  }

  /// Motivo por el que el código aplicado dejó de valer (p. ej. se quitó un producto y ya no
  /// llega a la compra mínima). Mientras haya motivo, el descuento es 0.
  String? get avisoCupon => _cuponAplicado?.motivoInvalido(subtotal: subtotal, subtotalAplicable: subtotalAplicable);

  int get descuento => _cuponAplicado != null && avisoCupon == null
      ? _cuponAplicado!.calcularDescuento(subtotalAplicable)
      : 0;

  int get total => (subtotal - descuento).clamp(0, subtotal);

  /// Retorna true si se pudo agregar, o false si el stock es 0 o se excede el disponible.
  bool agregar(Producto producto) {
    if (producto.stock <= 0) {
      return false; // Stock agotado
    }

    final actual = _items[producto.id]?.cantidad ?? 0;
    if (actual >= producto.stock) {
      return false; // No se puede exceder el stock disponible
    }

    if (_items.containsKey(producto.id)) {
      _items[producto.id]!.cantidad++;
    } else {
      _items[producto.id] = ItemCarrito(producto: producto);
    }
    notifyListeners();
    return true;
  }

  void quitar(String productoId) {
    _items.remove(productoId);
    notifyListeners();
  }

  /// Retorna true si se actualizó, false si excede el stock disponible.
  bool actualizarCantidad(String productoId, int cantidad) {
    if (cantidad <= 0) {
      quitar(productoId);
      return true;
    }
    final item = _items[productoId];
    if (item == null) return false;

    if (cantidad > item.producto.stock) {
      return false; // Excede inventario real
    }

    item.cantidad = cantidad;
    notifyListeners();
    return true;
  }

  void aplicarCupon(Cupon cupon) {
    _cuponAplicado = cupon;
    notifyListeners();
  }

  void quitarCupon() {
    _cuponAplicado = null;
    notifyListeners();
  }

  void limpiar() {
    _items.clear();
    _cuponAplicado = null;
    notifyListeners();
  }
}
