import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:royal_app/models/producto.dart';

/// Tamaños de pantalla que se verifican (sin overflow ni textos cortados).
const tamanosVerificados = <String, Size>{
  '1920x1080': Size(1920, 1080),
  '1366x768': Size(1366, 768),
  '1024x768': Size(1024, 768),
  '768x1024': Size(768, 1024),
  '390x844': Size(390, 844),
};

/// `flutter test --dart-define=CAPTURAS=true` guarda capturas PNG para revisión visual.
const generarCapturas = bool.fromEnvironment('CAPTURAS');
const carpetaCapturas = String.fromEnvironment('CARPETA_CAPTURAS');

bool _fuentesCargadas = false;

/// Carga Poppins y los íconos Material para que las capturas se vean como en la app.
Future<void> cargarFuentes() async {
  if (_fuentesCargadas) return;
  _fuentesCargadas = true;
  final poppins = FontLoader('Poppins');
  for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold']) {
    poppins.addFont(rootBundle.load('assets/fonts/Poppins-$w.ttf'));
  }
  await poppins.load();

  final sdk = Platform.environment['FLUTTER_ROOT'];
  final iconos = File('${sdk ?? ''}/bin/cache/artifacts/material_fonts/materialicons-regular.otf');
  if (sdk != null && iconos.existsSync()) {
    final loader = FontLoader('MaterialIcons')
      ..addFont(Future.value(ByteData.view(iconos.readAsBytesSync().buffer)));
    await loader.load();
  }
}

Future<void> capturar(WidgetTester tester, String nombre) async {
  if (!generarCapturas || carpetaCapturas.isEmpty) return;
  await expectLater(
    find.byType(MaterialApp).first,
    matchesGoldenFile(Uri.file('$carpetaCapturas/$nombre.png')),
  );
}

void fijarTamano(WidgetTester tester, Size tamano) {
  tester.view.physicalSize = tamano;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// Avanza animaciones sin esperar a que terminen las infinitas (esqueletos).
Future<void> avanzar(WidgetTester tester, [int pasos = 6]) async {
  for (var i = 0; i < pasos; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

List<Producto> productosDePrueba() {
  Producto p(String id, String nombre, String cat, String modelo, int precio, String hex, String foto,
          {int stock = 8, int desc = 0, bool pers = false, String codigo = ''}) =>
      Producto(
        id: id,
        nombre: nombre,
        categoria: cat,
        modelosCompatibles: [modelo],
        precio: precio,
        colorHex: hex,
        codigoColor: codigo,
        personalizable: pers,
        stock: stock,
        fotosUrls: ['assets/fundas/$foto'],
        enDescuento: desc > 0,
        porcentajeDescuento: desc,
      );

  return [
    p('1', 'Funda iPhone 11', 'solido', 'iPhone 11', 85000, '#000000', 'funda_iphone_11_negro.jpg', codigo: 'NEGRO NEG'),
    p('2', 'Funda iPhone 11 Pro DualTek', 'dualtek', 'iPhone 11 Pro', 120000, '#64748B',
        'funda_iphone_11_pro_dualtek_gris.jpg', desc: 15),
    p('3', 'Funda iPhone 13 Cuero', 'cuero', 'iPhone 13', 150000, '#7E22CE', 'funda_iphone_13_cuero_lila.jpg',
        pers: true),
    p('4', 'Funda iPhone 13 Silicona', 'silicona', 'iPhone 13', 90000, '#0B2545', 'funda_iphone_13_silicona_azul.jpg'),
    p('5', 'Funda iPhone 13 Transparente', 'transparente', 'iPhone 13', 70000, '#E5E7EB',
        'funda_iphone_13_transparente.jpg', stock: 0),
    p('6', 'Funda iPhone 14 MagSafe', 'magsafe', 'iPhone 14', 135000, '#0B2545', 'funda_iphone_14_magsafe_azul.jpg',
        desc: 20),
    p('7', 'Funda iPhone 17 Pro Max', 'solido', 'iPhone 17 Pro Max', 110000, '#DC2626', 'funda_iphone_11_pro_rojo.jpg'),
    p('8', 'Funda iPhone 18 Pro Max Silicona Edición Especial Extra Larga', 'silicona', 'iPhone 18 Pro Max', 99000,
        '#F472B6', 'funda_iphone_13_silicona_rosa.jpg', desc: 10, codigo: 'ROSA 002'),
  ];
}
