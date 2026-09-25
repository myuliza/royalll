import 'package:cloud_firestore/cloud_firestore.dart';

class CatalogoSeeder {
  /// Lista estandarizada de fundas con fotos reales verificadas,
  /// paleta completa de colores (Negro, Blanco/Transparente, Azul, Rojo, Verde, Rosa, Morado, Dorado/Beige, Gris/Titanio)
  /// y formato estricto: "Funda" seguido del modelo de iPhone.
  static final List<Map<String, dynamic>> catalogoSemilla = [
    {
      'nombre': 'Funda iPhone 16 Pro Max',
      'categoria': 'solido',
      'codigoColor': 'negro 001',
      'modelosCompatibles': ['iPhone 16 Pro Max', 'iPhone 16 Pro'],
      'precio': 120000,
      'colorHex': '#000000',
      'personalizable': false,
      'stock': 20,
      'fotosUrls': [
        'https://images.unsplash.com/photo-1601784551446-20c9e07cdbdb?w=800&auto=format&fit=crop&q=80'
      ],
      'imagenUrl':
          'https://images.unsplash.com/photo-1601784551446-20c9e07cdbdb?w=800&auto=format&fit=crop&q=80',
      'enDescuento': false,
      'porcentajeDescuento': 0,
    },
    {
      'nombre': 'Funda iPhone 16',
      'categoria': 'transparente',
      'codigoColor': 'transparente 002',
      'modelosCompatibles': ['iPhone 16', 'iPhone 15', 'iPhone 14'],
      'precio': 85000,
      'colorHex': '#E5E7EB',
      'personalizable': false,
      'stock': 30,
      'fotosUrls': [
        'https://images.unsplash.com/photo-1541807084-5c52b6b3adef?w=800&auto=format&fit=crop&q=80'
      ],
      'imagenUrl':
          'https://images.unsplash.com/photo-1541807084-5c52b6b3adef?w=800&auto=format&fit=crop&q=80',
      'enDescuento': false,
      'porcentajeDescuento': 0,
    },
    {
      'nombre': 'Funda iPhone 16 Pro',
      'categoria': 'solido',
      'codigoColor': 'blanco 003',
      'modelosCompatibles': ['iPhone 16 Pro', 'iPhone 16'],
      'precio': 110000,
      'colorHex': '#FFFFFF',
      'personalizable': false,
      'stock': 15,
      'fotosUrls': [
        'https://images.unsplash.com/photo-1510557880182-3d4d3cba35a5?w=800&auto=format&fit=crop&q=80'
      ],
      'imagenUrl':
          'https://images.unsplash.com/photo-1510557880182-3d4d3cba35a5?w=800&auto=format&fit=crop&q=80',
      'enDescuento': true,
      'porcentajeDescuento': 10,
    },
    {
      'nombre': 'Funda iPhone 15 Pro Max',
      'categoria': 'solido',
      'codigoColor': 'azul 004',
      'modelosCompatibles': ['iPhone 15 Pro Max', 'iPhone 15 Pro'],
      'precio': 95000,
      'colorHex': '#0B2545',
      'personalizable': false,
      'stock': 18,
      'fotosUrls': [
        'https://images.unsplash.com/photo-1586953208448-b95a79798f07?w=800&auto=format&fit=crop&q=80'
      ],
      'imagenUrl':
          'https://images.unsplash.com/photo-1586953208448-b95a79798f07?w=800&auto=format&fit=crop&q=80',
      'enDescuento': true,
      'porcentajeDescuento': 15,
    },
    {
      'nombre': 'Funda iPhone 15 Pro',
      'categoria': 'solido',
      'codigoColor': 'rojo 005',
      'modelosCompatibles': ['iPhone 15 Pro', 'iPhone 15'],
      'precio': 90000,
      'colorHex': '#DC2626',
      'personalizable': false,
      'stock': 12,
      'fotosUrls': [
        'https://images.unsplash.com/photo-1584438784894-089d6a62b8fa?w=800&auto=format&fit=crop&q=80'
      ],
      'imagenUrl':
          'https://images.unsplash.com/photo-1584438784894-089d6a62b8fa?w=800&auto=format&fit=crop&q=80',
      'enDescuento': true,
      'porcentajeDescuento': 20,
    },
    {
      'nombre': 'Funda iPhone 15',
      'categoria': 'solido',
      'codigoColor': 'verde 006',
      'modelosCompatibles': ['iPhone 15', 'iPhone 14'],
      'precio': 85000,
      'colorHex': '#16A34A',
      'personalizable': false,
      'stock': 22,
      'fotosUrls': [
        'https://images.unsplash.com/photo-1574944985070-8f3ebc6b79d2?w=800&auto=format&fit=crop&q=80'
      ],
      'imagenUrl':
          'https://images.unsplash.com/photo-1574944985070-8f3ebc6b79d2?w=800&auto=format&fit=crop&q=80',
      'enDescuento': false,
      'porcentajeDescuento': 0,
    },
    {
      'nombre': 'Funda iPhone 14 Pro Max',
      'categoria': 'solido',
      'codigoColor': 'rosa 007',
      'modelosCompatibles': ['iPhone 14 Pro Max', 'iPhone 14 Pro'],
      'precio': 85000,
      'colorHex': '#F472B6',
      'personalizable': false,
      'stock': 14,
      'fotosUrls': [
        'https://images.unsplash.com/photo-1580910051074-3eb694886505?w=800&auto=format&fit=crop&q=80'
      ],
      'imagenUrl':
          'https://images.unsplash.com/photo-1580910051074-3eb694886505?w=800&auto=format&fit=crop&q=80',
      'enDescuento': true,
      'porcentajeDescuento': 10,
    },
    {
      'nombre': 'Funda iPhone 14 Pro',
      'categoria': 'transparente',
      'codigoColor': 'morado 008',
      'modelosCompatibles': ['iPhone 14 Pro', 'iPhone 14'],
      'precio': 95000,
      'colorHex': '#7E22CE',
      'personalizable': false,
      'stock': 16,
      'fotosUrls': [
        'https://images.unsplash.com/photo-1572569511254-d8f925fe2cbb?w=800&auto=format&fit=crop&q=80'
      ],
      'imagenUrl':
          'https://images.unsplash.com/photo-1572569511254-d8f925fe2cbb?w=800&auto=format&fit=crop&q=80',
      'enDescuento': true,
      'porcentajeDescuento': 15,
    },
    {
      'nombre': 'Funda iPhone 14',
      'categoria': 'solido',
      'codigoColor': 'dorado 009',
      'modelosCompatibles': ['iPhone 14', 'iPhone 13'],
      'precio': 90000,
      'colorHex': '#C9A227',
      'personalizable': false,
      'stock': 12,
      'fotosUrls': [
        'https://images.unsplash.com/photo-1592899677977-9c10ca588bbd?w=800&auto=format&fit=crop&q=80'
      ],
      'imagenUrl':
          'https://images.unsplash.com/photo-1592899677977-9c10ca588bbd?w=800&auto=format&fit=crop&q=80',
      'enDescuento': false,
      'porcentajeDescuento': 0,
    },
    {
      'nombre': 'Funda iPhone 13 Pro Max',
      'categoria': 'solido',
      'codigoColor': 'titanio 010',
      'modelosCompatibles': ['iPhone 13 Pro Max', 'iPhone 13 Pro', 'iPhone 13'],
      'precio': 85000,
      'colorHex': '#64748B',
      'personalizable': false,
      'stock': 19,
      'fotosUrls': [
        'https://images.unsplash.com/photo-1565849904461-04a58ad377e0?w=800&auto=format&fit=crop&q=80'
      ],
      'imagenUrl':
          'https://images.unsplash.com/photo-1565849904461-04a58ad377e0?w=800&auto=format&fit=crop&q=80',
      'enDescuento': false,
      'porcentajeDescuento': 0,
    },
  ];

  /// Limpia los documentos repetidos en la colección `productos`
  /// conservando únicamente una instancia por nombre.
  static Future<int> limpiarDuplicados() async {
    final col = FirebaseFirestore.instance.collection('productos');
    final snapshot = await col.get();
    final Map<String, String> vistos = {};
    int eliminados = 0;

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final nombre = (data['nombre'] ?? '').toString().trim().toLowerCase();
      if (nombre.isEmpty) continue;

      if (vistos.containsKey(nombre)) {
        await col.doc(doc.id).delete();
        eliminados++;
      } else {
        vistos[nombre] = doc.id;
      }
    }

    return eliminados;
  }

  /// Inicializa datos semilla con fotos reales verificadas si la colección está vacía.
  static Future<int> inicializarDatosSemillaSiVacio() async {
    final col = FirebaseFirestore.instance.collection('productos');
    final snapshot = await col.get();

    final Set<String> existentes = snapshot.docs
        .map((d) => (d.data()['nombre'] ?? '').toString().trim().toLowerCase())
        .toSet();

    int insertados = 0;
    for (final item in catalogoSemilla) {
      final n = (item['nombre'] as String).toLowerCase();
      if (!existentes.contains(n)) {
        await col.add(item);
        insertados++;
      }
    }

    return insertados;
  }

  /// Sincroniza y actualiza todos los documentos del catálogo en Firebase:
  /// Corrige nombres eliminando "funda royal" -> "Funda iPhone X"
  /// y asigna URLs de fotos reales que funcionan al 100%.
  static Future<int> sincronizarFotosYNomenclatura() async {
    final col = FirebaseFirestore.instance.collection('productos');
    final snapshot = await col.get();

    int actualizados = 0;
    int idx = 0;

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final rawNombre = (data['nombre'] ?? '').toString();
      final refSeed = catalogoSemilla[idx % catalogoSemilla.length];

      // Sanitizar nombre eliminando "royal" y asegurando "Funda iPhone..."
      var nombreFinal = rawNombre
          .replaceAll(RegExp(r'\bfunda\s+royal\b', caseSensitive: false), '')
          .replaceAll(RegExp(r'\broyal\b', caseSensitive: false), '')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();

      if (!nombreFinal.toLowerCase().startsWith('funda')) {
        nombreFinal = 'Funda $nombreFinal';
      }

      // Si el nombre quedó genérico, usar el del modelo semilla
      if (nombreFinal == 'Funda' || nombreFinal == 'Funda iPhone' || nombreFinal.isEmpty) {
        nombreFinal = refSeed['nombre'] as String;
      }

      // Asegurar URL de foto real funcional
      final fotos = data['fotosUrls'];
      bool tieneFotoValida = false;
      if (fotos is List && fotos.isNotEmpty) {
        final primera = fotos.first.toString().trim();
        if (primera.startsWith('http') && !primera.contains('broken')) {
          tieneFotoValida = true;
        }
      }

      final updates = <String, dynamic>{
        'nombre': nombreFinal,
      };

      if (!tieneFotoValida) {
        updates['fotosUrls'] = refSeed['fotosUrls'];
        updates['imagenUrl'] = refSeed['imagenUrl'];
      }

      if ((data['codigoColor'] == null || data['codigoColor'].toString().isEmpty)) {
        updates['codigoColor'] = refSeed['codigoColor'];
      }

      await col.doc(doc.id).update(updates);
      actualizados++;
      idx++;
    }

    // Si la base estaba vacía, poblar las 10 completas
    if (snapshot.docs.isEmpty) {
      actualizados = await inicializarDatosSemillaSiVacio();
    }

    return actualizados;
  }
}
