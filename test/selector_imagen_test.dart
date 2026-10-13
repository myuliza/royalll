import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:royal_app/theme/app_theme.dart';
import 'package:royal_app/widgets/selector_imagen_producto.dart';

void main() {
  test('Valida formato y tamaño de la imagen', () {
    expect(validarArchivoImagen('funda.jpg', 1024), isNull);
    expect(validarArchivoImagen('funda.JPEG', 1024), isNull);
    expect(validarArchivoImagen('funda.png', 1024), isNull);
    expect(validarArchivoImagen('funda.webp', 1024), isNull);
    expect(validarArchivoImagen('funda.gif', 1024), contains('JPG, PNG o WEBP'));
    expect(validarArchivoImagen('sin_extension', 1024), contains('Formato no permitido'));
    expect(validarArchivoImagen('grande.jpg', 6 * 1024 * 1024), 'La imagen pesa 6,0 MB. El máximo es 5 MB.');
    expect(validarArchivoImagen('justo.png', 5 * 1024 * 1024), isNull);
    expect(tipoMimeImagen('jpg'), 'image/jpeg');
    expect(tipoMimeImagen('webp'), 'image/webp');
  });

  for (final ancho in [390.0, 1366.0]) {
    testWidgets('Selector "URL" / "Subir desde mi PC" sin overflow en ${ancho.toInt()}', (tester) async {
      tester.view.physicalSize = Size(ancho, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final ctrl = TextEditingController(text: 'https://ejemplo.com/a.jpg');
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: SelectorImagenProducto(
              urlController: ctrl,
              campoUrl: TextField(controller: ctrl, key: const ValueKey('campo-url')),
            ),
          ),
        ),
      ));
      expect(find.text('URL'), findsOneWidget);
      expect(find.text('Subir desde mi PC'), findsOneWidget);
      expect(find.byKey(const ValueKey('campo-url')), findsOneWidget);

      await tester.tap(find.text('Subir desde mi PC'));
      await tester.pumpAndSettle();
      expect(find.text('Elegir imagen…'), findsOneWidget);
      expect(find.text('JPG, PNG o WEBP · hasta 5 MB'), findsOneWidget);
      expect(find.byKey(const ValueKey('campo-url')), findsNothing);
      expect(tester.takeException(), isNull);

      // Volver a URL conserva el valor
      await tester.tap(find.text('URL'));
      await tester.pumpAndSettle();
      expect(ctrl.text, 'https://ejemplo.com/a.jpg');
    });
  }
}
