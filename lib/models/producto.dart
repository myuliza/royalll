class Producto {
  final String id;
  final String nombre;
  final String categoria; // 'solido' | 'transparente' | 'personalizada'
  final List<String> modelosCompatibles; // ej: ['iPhone 13', 'iPhone 13 Pro']
  final int precio; // en guaraníes
  final String colorHex; // color de la funda, si aplica
  final bool personalizable;
  final int stock;
  final List<String> fotosUrls;

  Producto({
    required this.id,
    required this.nombre,
    required this.categoria,
    required this.modelosCompatibles,
    required this.precio,
    required this.colorHex,
    required this.personalizable,
    required this.stock,
    required this.fotosUrls,
  });

  factory Producto.fromMap(String id, Map<String, dynamic> data) {
    return Producto(
      id: id,
      nombre: data['nombre'] ?? '',
      categoria: data['categoria'] ?? 'solido',
      modelosCompatibles: List<String>.from(data['modelosCompatibles'] ?? []),
      precio: data['precio'] ?? 0,
      colorHex: data['colorHex'] ?? '#FFFFFF',
      personalizable: data['personalizable'] ?? false,
      stock: data['stock'] ?? 0,
      fotosUrls: List<String>.from(data['fotosUrls'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'categoria': categoria,
      'modelosCompatibles': modelosCompatibles,
      'precio': precio,
      'colorHex': colorHex,
      'personalizable': personalizable,
      'stock': stock,
      'fotosUrls': fotosUrls,
    };
  }

  String get precioFormateado {
    // 25000 -> "25.000 Gs"
    final s = precio.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final posFromEnd = s.length - i;
      buffer.write(s[i]);
      if (posFromEnd > 1 && posFromEnd % 3 == 1) buffer.write('.');
    }
    return '${buffer.toString()} Gs';
  }
}
