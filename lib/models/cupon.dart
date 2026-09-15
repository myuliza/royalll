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
    return Cupon(
      codigo: data['codigo'] ?? '',
      tipo: data['tipo'] ?? 'porcentaje',
      valor: data['valor'] ?? 0,
      vigenciaHasta: DateTime.parse(data['vigenciaHasta']),
      usosMaximos: data['usosMaximos'] ?? 0,
      usosActuales: data['usosActuales'] ?? 0,
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
