import 'package:cloud_firestore/cloud_firestore.dart';

class Cupon {
  final String codigo;
  final String tipo; // 'porcentaje' | 'monto_fijo'
  final int valor; // % o Gs, según el tipo
  final DateTime vigenciaHasta;
  final int usosMaximos;
  final int usosActuales;

  Cupon({
    required this.codigo,
    required this.tipo,
    required this.valor,
    required this.vigenciaHasta,
    required this.usosMaximos,
    required this.usosActuales,
  });

  factory Cupon.fromMap(Map<String, dynamic> data) {
    DateTime vigencia;
    final rawVigencia = data['vigenciaHasta'];

    // Manejo robusto de fechas soportando Timestamp de Firestore, String ISO o DateTime
    if (rawVigencia is Timestamp) {
      vigencia = rawVigencia.toDate();
    } else if (rawVigencia is String) {
      vigencia = DateTime.tryParse(rawVigencia) ?? DateTime.now();
    } else if (rawVigencia is DateTime) {
      vigencia = rawVigencia;
    } else {
      vigencia = DateTime.now();
    }

    return Cupon(
      codigo: (data['codigo'] ?? '').toString().toUpperCase().trim(),
      tipo: data['tipo'] ?? 'porcentaje',
      valor: (data['valor'] is num) ? (data['valor'] as num).toInt() : 0,
      vigenciaHasta: vigencia,
      usosMaximos: (data['usosMaximos'] is num) ? (data['usosMaximos'] as num).toInt() : 0,
      usosActuales: (data['usosActuales'] is num) ? (data['usosActuales'] as num).toInt() : 0,
    );
  }

  bool get esValido =>
      DateTime.now().isBefore(vigenciaHasta) && usosActuales < usosMaximos;

  int calcularDescuento(int totalActual) {
    if (tipo == 'porcentaje') {
      return (totalActual * valor / 100).round();
    }
    return valor; // monto fijo
  }
}
