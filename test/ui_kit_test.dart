import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:royal_app/theme/app_theme.dart';
import 'package:royal_app/theme/breakpoints.dart';
import 'package:royal_app/theme/theme_controller.dart';
import 'package:royal_app/widgets/theme_toggle_button.dart';
import 'package:royal_app/widgets/ui/ui.dart';

Widget _muestrario() {
  return SingleChildScrollView(
    child: ContenidoCentrado(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(titulo: 'Inicio', subtitulo: 'Subtítulo de prueba', grande: true),
          SectionHeader(titulo: 'Más populares', accion: 'Ver todo', onAccion: () {}),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 260,
                child: FeatureTile(titulo: 'Colección iPhone', icono: Icons.phone_iphone, contador: '42', onTap: () {}),
              ),
              const SizedBox(
                width: 160,
                child: IconTile(titulo: 'Transparente', icono: Icons.blur_on),
              ),
              const SizedBox(
                width: 260,
                child: StatCard(titulo: 'Ingresos', valor: '1.250.000 Gs', icono: Icons.payments, variacion: 12.5),
              ),
              const SizedBox(
                width: 260,
                child: StatCard(
                  titulo: 'Pedidos',
                  valor: '37',
                  icono: Icons.receipt_long,
                  variacion: -4,
                  degradado: AppColors.degradadoVerde,
                ),
              ),
            ],
          ),
          AppCard(onTap: () {}, child: const Text('Tarjeta base')),
          const EmptyState(icono: Icons.inventory_2_outlined, titulo: 'Sin resultados', mensaje: 'Probá otro filtro.'),
          const EmptyState.error(),
          const SkeletonGrid(cantidad: 4),
        ],
      ),
    ),
  );
}

Future<void> _pump(WidgetTester tester, Size tamano, ThemeMode modo) async {
  tester.view.physicalSize = tamano;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ChangeNotifierProvider(
      create: (_) => ThemeController(),
      child: MaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: modo,
        home: Scaffold(
          appBar: AppBar(actions: const [ThemeToggleButton()]),
          body: _muestrario(),
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  const tamanos = [Size(390, 844), Size(768, 1024), Size(1920, 1080)];

  for (final modo in [ThemeMode.light, ThemeMode.dark]) {
    for (final t in tamanos) {
      testWidgets('Kit UI sin overflow en ${t.width.toInt()}x${t.height.toInt()} (${modo.name})', (tester) async {
        await _pump(tester, t, modo);
        expect(tester.takeException(), isNull);
        expect(find.text('Colección iPhone'), findsOneWidget);
      });
    }
  }

  testWidgets('El botón alterna entre sol (claro) y luna (oscuro)', (tester) async {
    await _pump(tester, const Size(390, 844), ThemeMode.light);
    final ctx = tester.element(find.byType(ThemeToggleButton));
    final tema = Provider.of<ThemeController>(ctx, listen: false);

    expect(find.byIcon(Icons.light_mode_rounded), findsOneWidget);
    await tester.tap(find.byType(ThemeToggleButton));
    await tester.pump(const Duration(milliseconds: 400));
    expect(tema.esOscuro, isTrue);
    expect(find.byIcon(Icons.dark_mode_rounded), findsOneWidget);

    await tester.tap(find.byType(ThemeToggleButton));
    await tester.pump(const Duration(milliseconds: 400));
    expect(tema.esOscuro, isFalse);
    expect(find.byIcon(Icons.light_mode_rounded), findsOneWidget);
  });

  test('Breakpoints', () {
    expect(Breakpoints.deAncho(390), TipoPantalla.movil);
    expect(Breakpoints.deAncho(768), TipoPantalla.tablet);
    expect(Breakpoints.deAncho(1024), TipoPantalla.tablet);
    expect(Breakpoints.deAncho(1366), TipoPantalla.escritorio);
  });
}
