import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/formatters.dart';

/// Estado visible de un código promocional.
enum EstadoCupon { activo, programado, vencido, agotado, pausado }

extension EstadoCuponInfo on EstadoCupon {
  String get etiqueta => switch (this) {
        EstadoCupon.activo => 'Activo',
        EstadoCupon.programado => 'Programado',
        EstadoCupon.vencido => 'Vencido',
        EstadoCupon.agotado => 'Agotado',
        EstadoCupon.pausado => 'Pausado',
      };
}

/// Alcance del código: todo el carrito, solo ciertas categorías o solo ciertos modelos.
class AlcanceCupon {
  static const todo = 'todo';
  static const categorias = 'categorias';
  static const modelos = 'modelos';
}

/// Código promocional (colección `cupones`, el id del documento es el código).
///
/// Los campos nuevos son opcionales y compatibles con los cupones existentes:
/// `fechaInicio`, `compraMinima`, `activo`, `aplicaA`, `categorias`, `modelos`.
/// `usosMaximos` ausente o null = sin límite de usos.
class Cupon {
  final String codigo;
  final String tipo; // 'porcentaje' | 'monto_fijo'
  final int valor; // % o Gs, según el tipo
  final DateTime vigenciaHasta;
  final DateTime? fechaInicio;
  final int? usosMaximos; // null = sin límite
  final int usosActuales;
  final int compraMinima; // 0 = sin mínimo
  final bool activo;
  final String aplicaA;
  final List<String> categorias;
  final List<String> modelos;

  Cupon({
    required this.codigo,
    required this.tipo,
    required this.valor,
    required this.vigenciaHasta,
    required this.usosMaximos,
    required this.usosActuales,
    this.fechaInicio,
    this.compraMinima = 0,
    this.activo = true,
    this.aplicaA = AlcanceCupon.todo,
    this.categorias = const [],
    this.modelos = const [],
  });

  /// Formato de código: mayúsculas, números, guion o guion bajo, sin espacios (3 a 20).
  static final formatoCodigo = RegExp(r'^[A-Z0-9_-]{3,20}$');

  static String normalizarCodigo(String raw) => raw.trim().toUpperCase().replaceAll(RegExp(r'\s+'), '');

  static DateTime? _fecha(dynamic raw) {
    // Manejo robusto de fechas soportando Timestamp de Firestore, String ISO o DateTime
    if (raw is Timestamp) return raw.toDate();
    if (raw is String) return DateTime.tryParse(raw);
    if (raw is DateTime) return raw;
    return null;
  }

  factory Cupon.fromMap(Map<String, dynamic> data) {
    int? entero(dynamic v) => v is num ? v.toInt() : null;
    List<String> lista(dynamic v) => v is List ? v.map((e) => e.toString()).toList() : const [];

    return Cupon(
      codigo: (data['codigo'] ?? '').toString().toUpperCase().trim(),
      tipo: data['tipo'] ?? 'porcentaje',
      valor: entero(data['valor']) ?? 0,
      vigenciaHasta: _fecha(data['vigenciaHasta']) ?? DateTime.now(),
      fechaInicio: _fecha(data['fechaInicio']),
      usosMaximos: data.containsKey('usosMaximos') ? entero(data['usosMaximos']) : null,
      usosActuales: entero(data['usosActuales']) ?? 0,
      compraMinima: entero(data['compraMinima']) ?? 0,
      activo: data['activo'] is bool ? data['activo'] as bool : true,
      aplicaA: (data['aplicaA'] ?? AlcanceCupon.todo).toString(),
      categorias: lista(data['categorias']),
      modelos: lista(data['modelos']),
    );
  }

  Map<String, dynamic> toMap() => {
        'codigo': codigo,
        'tipo': tipo,
        'valor': valor,
        'vigenciaHasta': Timestamp.fromDate(vigenciaHasta),
        'fechaInicio': fechaInicio == null ? null : Timestamp.fromDate(fechaInicio!),
        'usosMaximos': usosMaximos,
        'compraMinima': compraMinima,
        'activo': activo,
        'aplicaA': aplicaA,
        'categorias': categorias,
        'modelos': modelos,
      };

  EstadoCupon estado([DateTime? ahora]) {
    final t = ahora ?? DateTime.now();
    if (!activo) return EstadoCupon.pausado;
    if (!t.isBefore(vigenciaHasta)) return EstadoCupon.vencido;
    if (usosMaximos != null && usosActuales >= usosMaximos!) return EstadoCupon.agotado;
    if (fechaInicio != null && t.isBefore(fechaInicio!)) return EstadoCupon.programado;
    return EstadoCupon.activo;
  }

  bool get esValido => estado() == EstadoCupon.activo;

  /// Indica si el código aplica a un producto con esa categoría y modelos.
  bool aplicaAProducto(String categoria, List<String> modelosProducto) => switch (aplicaA) {
        AlcanceCupon.categorias => categorias.contains(categoria),
        AlcanceCupon.modelos => modelosProducto.any(modelos.contains),
        _ => true,
      };

  int calcularDescuento(int totalActual) {
    if (totalActual <= 0) return 0;
    if (tipo == 'porcentaje') {
      return (totalActual * valor / 100).round().clamp(0, totalActual);
    }
    return valor.clamp(0, totalActual); // monto fijo (nunca más que lo que aplica)
  }

  String get descripcionDescuento => tipo == 'porcentaje' ? '$valor %' : formatPrice(valor);

  /// Mensaje claro si el código no se puede usar con este carrito; null si es válido.
  String? motivoInvalido({required int subtotal, required int subtotalAplicable, DateTime? ahora}) {
    switch (estado(ahora)) {
      case EstadoCupon.pausado:
        return 'El código $codigo está pausado.';
      case EstadoCupon.vencido:
        return 'El código $codigo venció el ${_fechaCorta(vigenciaHasta.subtract(const Duration(seconds: 1)))}.';
      case EstadoCupon.agotado:
        return 'El código $codigo ya alcanzó su límite de usos.';
      case EstadoCupon.programado:
        return 'El código $codigo es válido desde el ${_fechaCorta(fechaInicio!)}.';
      case EstadoCupon.activo:
        break;
    }
    if (compraMinima > 0 && subtotal < compraMinima) {
      return 'El código $codigo requiere una compra mínima de ${formatPrice(compraMinima)}.';
    }
    if (subtotalAplicable <= 0) {
      return 'El código $codigo no aplica a los productos de tu carrito.';
    }
    return null;
  }

  static String _fechaCorta(DateTime f) =>
      '${f.day.toString().padLeft(2, '0')}/${f.month.toString().padLeft(2, '0')}/${f.year}';
}
