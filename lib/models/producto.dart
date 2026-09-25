import '../utils/formatters.dart';

class Producto {
  final String id;
  final String nombre; // Nunca contiene la palabra "Funda"
  final String categoria; // 'solido' | 'transparente' | 'personalizada'
  final List<String> modelosCompatibles; // ej: ['iPhone 13', 'iPhone 13 Pro']
  final int precio; // precio base en guaraníes
  final String colorHex; // color hexadecimal
  final String codigoColor; // Código de modelo/color (ej: "transparente 001", "rojo 002")
  final bool personalizable;
  final int stock;
  final List<String> fotosUrls;
  final bool enDescuento;
  final int porcentajeDescuento;

  Producto({
    required this.id,
    required this.nombre,
    required this.categoria,
    required this.modelosCompatibles,
    required this.precio,
    required this.colorHex,
    this.codigoColor = '',
    required this.personalizable,
    required this.stock,
    required this.fotosUrls,
    this.enDescuento = false,
    this.porcentajeDescuento = 0,
  });

  /// Sanitiza el nombre: elimina cualquier mención de "funda royal" o "royal"
  /// y garantiza que el formato sea estrictamente "Funda" seguido del modelo correspondiente
  /// (ejemplo: "Funda iPhone 13", "Funda iPhone 14 Pro", "Funda iPhone 15 Pro Max").
  static String limpiarNombre(String raw) {
    var limpio = raw
        .replaceAll(RegExp(r'\bfunda\s+royal\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'\broyal\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'\bfunda\s+funda\b', caseSensitive: false), 'Funda')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (limpio.toLowerCase().startsWith('funda ')) {
      limpio = 'Funda ${limpio.substring(6).trim()}';
    } else if (limpio.toLowerCase() == 'funda' || limpio.isEmpty) {
      limpio = 'Funda iPhone';
    } else {
      limpio = 'Funda $limpio';
    }

    return limpio.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Extrae URLs válidas soportando tanto listas 'fotosUrls' como strings 'imagenUrl' / 'fotoUrl'.
  static List<String> _extraerFotos(Map<String, dynamic> data) {
    final List<String> urls = [];
    if (data['fotosUrls'] is List) {
      for (final item in data['fotosUrls']) {
        if (item != null) {
          final s = item.toString().trim();
          if (s.isNotEmpty && (s.startsWith('http://') || s.startsWith('https://'))) {
            urls.add(s);
          }
        }
      }
    }
    if (urls.isEmpty && data['imagenUrl'] != null) {
      final s = data['imagenUrl'].toString().trim();
      if (s.isNotEmpty && (s.startsWith('http://') || s.startsWith('https://'))) {
        urls.add(s);
      }
    }
    if (urls.isEmpty && data['fotoUrl'] != null) {
      final s = data['fotoUrl'].toString().trim();
      if (s.isNotEmpty && (s.startsWith('http://') || s.startsWith('https://'))) {
        urls.add(s);
      }
    }
    return urls;
  }

  factory Producto.fromMap(String id, Map<String, dynamic> data) {
    final rawNombre = (data['nombre'] ?? '').toString();
    final nombreSanitizado = limpiarNombre(rawNombre);

    final codigo = (data['codigoColor'] ?? data['codigo'] ?? '').toString().trim();

    return Producto(
      id: id,
      nombre: nombreSanitizado,
      categoria: (data['categoria'] ?? 'solido').toString().toLowerCase(),
      modelosCompatibles: List<String>.from(data['modelosCompatibles'] ?? []),
      precio: (data['precio'] is num) ? (data['precio'] as num).toInt() : 0,
      colorHex: (data['colorHex'] ?? '#FFFFFF').toString().trim(),
      codigoColor: codigo,
      personalizable: data['personalizable'] ?? false,
      stock: (data['stock'] is num) ? (data['stock'] as num).toInt() : 0,
      fotosUrls: _extraerFotos(data),
      enDescuento: data['enDescuento'] ?? false,
      porcentajeDescuento: (data['porcentajeDescuento'] is num)
          ? (data['porcentajeDescuento'] as num).toInt()
          : 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'categoria': categoria,
      'modelosCompatibles': modelosCompatibles,
      'precio': precio,
      'colorHex': colorHex,
      'codigoColor': codigoColor,
      'personalizable': personalizable,
      'stock': stock,
      'fotosUrls': fotosUrls,
      'imagenUrl': fotoPrincipalUrl,
      'enDescuento': enDescuento,
      'porcentajeDescuento': porcentajeDescuento,
    };
  }

  /// Retorna la URL principal si existe, sanitizada.
  String get fotoPrincipalUrl => fotosUrls.isNotEmpty ? fotosUrls.first : '';

  int get precioFinal {
    if (enDescuento && porcentajeDescuento > 0) {
      final desc = (precio * (porcentajeDescuento / 100)).round();
      return (precio - desc).clamp(0, precio);
    }
    return precio;
  }

  String get precioFormateado => formatPrice(precioFinal);
  String get precioOriginalFormateado => formatPrice(precio);
  String get precioFinalFormateado => formatPrice(precioFinal);
}
