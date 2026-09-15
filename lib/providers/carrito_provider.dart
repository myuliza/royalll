import 'package:flutter/foundation.dart';
import '../models/producto.dart';
import '../models/cupon.dart';

class ItemCarrito {
  final Producto producto;
  int cantidad;
  ItemCarrito({required this.producto, this.cantidad = 1});

  int get subtotal => producto.precio * cantidad;
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

  void agregar(Producto producto) {
    if (_items.containsKey(producto.id)) {
      _items[producto.id]!.cantidad++;
    } else {
      _items[producto.id] = ItemCarrito(producto: producto);
    }
    notifyListeners();
  }

  void quitar(String productoId) {
    _items.remove(productoId);
    notifyListeners();
  }

  void actualizarCantidad(String productoId, int cantidad) {
    if (cantidad <= 0) {
      quitar(productoId);
      return;
    }
    _items[productoId]?.cantidad = cantidad;
    notifyListeners();
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
