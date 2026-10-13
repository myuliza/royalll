import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/carrito_provider.dart';

/// Línea de una venta (una funda y su cantidad).
class ItemVenta {
  final String productoId;
  final String nombre;
  final String modelo;
  final String categoria;
  final int cantidad;
  final int precioUnitario; // precio final cobrado por unidad (Gs)

  const ItemVenta({
    required this.productoId,
    required this.nombre,
    required this.modelo,
    required this.categoria,
    required this.cantidad,
    required this.precioUnitario,
  });

  int get subtotal => precioUnitario * cantidad;

  factory ItemVenta.fromMap(Map<String, dynamic> data) => ItemVenta(
        productoId: (data['productoId'] ?? '').toString(),
        nombre: (data['nombre'] ?? '').toString(),
        modelo: (data['modelo'] ?? '').toString(),
        categoria: (data['categoria'] ?? '').toString(),
        cantidad: (data['cantidad'] is num) ? (data['cantidad'] as num).toInt() : 0,
        precioUnitario: (data['precio'] is num) ? (data['precio'] as num).toInt() : 0,
      );

  Map<String, dynamic> toMap() => {
        'productoId': productoId,
        'nombre': nombre,
        'modelo': modelo,
        'categoria': categoria,
        'cantidad': cantidad,
        'precio': precioUnitario,
      };
}

/// Venta registrada al confirmar un pedido (colección `ventas`).
///
/// Estructura en Firestore:
/// `{ fecha: Timestamp, items: [{productoId, nombre, modelo, categoria, cantidad, precio}],
///    subtotal, descuento, total, codigoPromocional (o null), cliente, formaPago }`
class Venta {
  final String id;
  final DateTime fecha;
  final List<ItemVenta> items;
  final int subtotal;
  final int descuento;
  final int total;
  final String? codigoPromocional;
  final String cliente;
  final String formaPago;

  const Venta({
    required this.id,
    required this.fecha,
    required this.items,
    required this.subtotal,
    required this.descuento,
    required this.total,
    this.codigoPromocional,
    this.cliente = '',
    this.formaPago = '',
  });

  int get unidades => items.fold(0, (s, i) => s + i.cantidad);

  factory Venta.fromMap(String id, Map<String, dynamic> data) {
    final raw = data['fecha'];
    final fecha = raw is Timestamp
        ? raw.toDate()
        : raw is String
            ? DateTime.tryParse(raw) ?? DateTime.now()
            : DateTime.now(); // serverTimestamp todavía pendiente (escritura local)
    int entero(String k) => (data[k] is num) ? (data[k] as num).toInt() : 0;
    final codigo = (data['codigoPromocional'] ?? '').toString().trim();

    return Venta(
      id: id,
      fecha: fecha,
      items: (data['items'] is List)
          ? (data['items'] as List).whereType<Map>().map((m) => ItemVenta.fromMap(Map<String, dynamic>.from(m))).toList()
          : const [],
      subtotal: entero('subtotal'),
      descuento: entero('descuento'),
      total: entero('total'),
      codigoPromocional: codigo.isEmpty ? null : codigo,
      cliente: (data['cliente'] ?? '').toString(),
      formaPago: (data['formaPago'] ?? '').toString(),
    );
  }

  /// Datos para guardar una venta nueva a partir del carrito (fecha del servidor).
  static Map<String, dynamic> nuevaDesdeCarrito(
    CarritoProvider carrito, {
    required String cliente,
    required String formaPago,
  }) {
    return {
      'fecha': FieldValue.serverTimestamp(),
      'items': [
        for (final i in carrito.items)
          ItemVenta(
            productoId: i.producto.id,
            nombre: i.producto.nombre,
            modelo: i.producto.modelosCompatibles.isNotEmpty ? i.producto.modelosCompatibles.first : '',
            categoria: i.producto.categoria,
            cantidad: i.cantidad,
            precioUnitario: i.producto.precioFinal,
          ).toMap(),
      ],
      'subtotal': carrito.subtotal,
      'descuento': carrito.descuento,
      'total': carrito.total,
      'codigoPromocional': carrito.cuponAplicado?.codigo,
      'cliente': cliente,
      'formaPago': formaPago,
    };
  }
}
