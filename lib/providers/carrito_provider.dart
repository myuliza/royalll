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

  int get descuento =>
      _cuponAplicado != null ? _cuponAplicado!.calcularDescuento(subtotal) : 0;

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
