import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:royal_app/providers/busqueda_catalogo.dart';
import 'package:royal_app/providers/carrito_provider.dart';
import 'package:royal_app/providers/empleado_sesion.dart';
import 'package:royal_app/screens/app_shell.dart';
import 'package:royal_app/screens/carrito_screen.dart';
import 'package:royal_app/screens/catalogo_screen.dart';
import 'package:royal_app/screens/empleado_login_screen.dart';
import 'package:royal_app/screens/faq_screen.dart';
import 'package:royal_app/screens/home_screen.dart';
import 'package:royal_app/theme/app_theme.dart';
import 'package:royal_app/theme/theme_controller.dart';

import 'soporte_pruebas.dart';

GoRouter _router(String inicial) {
  final productos = productosDePrueba();
  return GoRouter(
    initialLocation: inicial,
    routes: [
      StatefulShellRoute(
        builder: (_, __, shell) => shell,
        navigatorContainerBuilder: (_, shell, ramas) => AppShell(navigationShell: shell, ramas: ramas),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/inicio', builder: (_, __) => HomeScreen(productosDePrueba: productos)),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/catalogo',
              builder: (_, s) => CatalogoScreen(
                productosDePrueba: productos,
                categoria: s.uri.queryParameters['categoria'],
                modelo: s.uri.queryParameters['modelo'],
                especial: s.uri.queryParameters['especial'],
              ),
            ),
          ]),
          StatefulShellBranch(routes: [GoRoute(path: '/carrito', builder: (_, __) => const CarritoScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/faq', builder: (_, __) => const FaqScreen(sinFirebase: true))]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/empleados', builder: (_, __) => EmpleadoLoginScreen(onIngresoExitoso: () {})),
          ]),
        ],
      ),
    ],
  );
}

Future<void> _montar(WidgetTester tester, String ruta, Size tamano, ThemeMode modo, {bool conCarrito = false}) async {
  await cargarFuentes();
  fijarTamano(tester, tamano);
  final carrito = CarritoProvider();
  if (conCarrito) {
    final ps = productosDePrueba();
    carrito.agregar(ps[1]);
    carrito.agregar(ps[1]);
    carrito.agregar(ps[7]);
    carrito.agregar(ps[2]);
  }
  final tema = ThemeController();
  if (modo == ThemeMode.dark) tema.alternar();

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: carrito),
        ChangeNotifierProvider.value(value: tema),
        ChangeNotifierProvider(create: (_) => EmpleadoSesion.prueba()),
        ChangeNotifierProvider(create: (_) => BusquedaCatalogo()),
      ],
      child: Consumer<ThemeController>(
        builder: (_, t, __) => MaterialApp.router(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: t.modo,
          routerConfig: _router(ruta),
        ),
      ),
    ),
  );
  // Cargar las imágenes de assets (son asincrónicas)
  await tester.runAsync(() async {
    for (final e in tester.widgetList<Image>(find.byType(Image))) {
      await precacheImage(e.image, tester.element(find.byWidget(e)));
    }
  });
  await avanzar(tester);
}

void main() {
  final pantallas = {
    'inicio': '/inicio',
    'catalogo': '/catalogo',
    'carrito': '/carrito',
    'faq': '/faq',
    'acceso': '/empleados',
  };

  for (final modo in [ThemeMode.light, ThemeMode.dark]) {
    for (final t in tamanosVerificados.entries) {
      for (final p in pantallas.entries) {
        testWidgets('${p.key} ${t.key} ${modo.name}: sin overflow', (tester) async {
          await _montar(tester, p.value, t.value, modo, conCarrito: p.key == 'carrito');
          expect(tester.takeException(), isNull);
          await capturar(tester, '${p.key}_${t.key}_${modo.name}');
        });
      }

      testWidgets('detalle ${t.key} ${modo.name}: sin overflow', (tester) async {
        await _montar(tester, '/catalogo', t.value, modo);
        await tester.tap(find.text('Funda iPhone 11 Pro DualTek').first);
        await avanzar(tester, 8);
        expect(find.text('Modelos compatibles'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await capturar(tester, 'detalle_${t.key}_${modo.name}');
      });

      testWidgets('checkout ${t.key} ${modo.name}: sin overflow', (tester) async {
        await _montar(tester, '/carrito', t.value, modo, conCarrito: true);
        await tester.tap(find.text('Continuar al pedido'));
        await avanzar(tester, 8);
        expect(find.text('Confirmar pedido'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await capturar(tester, 'checkout_${t.key}_${modo.name}');
      });
    }
  }

  testWidgets('Catálogo: filtros por URL, filtro rápido y búsqueda global', (tester) async {
    await _montar(tester, '/catalogo?categoria=silicona', const Size(1366, 768), ThemeMode.light);
    expect(find.text('2 de 8 fundas'), findsOneWidget);

    await tester.tap(find.text('Todas'));
    await avanzar(tester);
    await tester.tap(find.text('Ofertas'));
    await avanzar(tester);
    expect(find.text('3 de 8 fundas'), findsOneWidget);

    await tester.tap(find.text('Ofertas'));
    await avanzar(tester);
    await tester.enterText(find.byType(TextField).first, 'rosa');
    await avanzar(tester);
    expect(find.text('1 de 8 fundas'), findsOneWidget);
  });

  testWidgets('Detalle: agregar al carrito cierra el diálogo y suma al contador', (tester) async {
    await _montar(tester, '/catalogo', const Size(1366, 768), ThemeMode.light);
    await tester.tap(find.text('Funda iPhone 11').first);
    await avanzar(tester, 8);
    await tester.tap(find.text('Agregar al carrito'));
    await avanzar(tester, 8);
    expect(find.text('Modelos compatibles'), findsNothing);
    expect(find.text('Funda iPhone 11 agregado al carrito'), findsOneWidget);
  });

  testWidgets('Detalle: producto agotado no se puede agregar', (tester) async {
    await _montar(tester, '/catalogo', const Size(390, 844), ThemeMode.light);
    await tester.enterText(find.byType(TextField).first, '13 transparente');
    await avanzar(tester);
    await tester.tap(find.text('Funda iPhone 13 Transparente'));
    await avanzar(tester, 8);
    final boton = tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Producto agotado'));
    expect(boton.onPressed, isNull);
  });

  testWidgets('Carrito: sumar respeta el stock y eliminar ofrece Deshacer', (tester) async {
    await _montar(tester, '/carrito', const Size(1366, 768), ThemeMode.light, conCarrito: true);
    expect(find.text('4 productos'), findsOneWidget);
    await tester.tap(find.byTooltip('Eliminar').first);
    await avanzar(tester);
    expect(find.text('Deshacer'), findsOneWidget);
    await tester.tap(find.text('Deshacer'));
    await avanzar(tester);
    expect(find.text('4 productos'), findsOneWidget);
  });

  testWidgets('Inicio: la tarjeta Ofertas lleva al catálogo filtrado', (tester) async {
    await _montar(tester, '/inicio', const Size(1366, 768), ThemeMode.light);
    await tester.tap(find.text('Ofertas'));
    await avanzar(tester, 8);
    expect(find.text('3 de 8 fundas'), findsOneWidget);
  });

  for (final ruta in ['/inicio', '/catalogo', '/faq']) {
    testWidgets('Scroll con la rueda del mouse en $ruta sin errores', (tester) async {
      await _montar(tester, ruta, const Size(1366, 768), ThemeMode.light);
      final centro = tester.getCenter(find.byType(AppShell)) + const Offset(100, 100);
      final mouse = TestPointer(1, PointerDeviceKind.mouse);
      await tester.sendEventToBinding(mouse.hover(centro));
      for (var i = 0; i < 5; i++) {
        await tester.sendEventToBinding(mouse.scroll(const Offset(0, 120)));
        await tester.pump(const Duration(milliseconds: 50));
      }
      await avanzar(tester);
      expect(tester.takeException(), isNull);
    });
  }

  for (final tam in [const Size(1366, 768), const Size(390, 844)]) {
    testWidgets('Aviso "agregado al carrito" ${tam.width.toInt()}: se cierra solo, no se acumula y no tapa el pedido',
        (tester) async {
      await _montar(tester, '/carrito', tam, ThemeMode.light, conCarrito: true);
      // El primer ítem tiene 2 de 8 en stock: 6 toques llegan al máximo y los siguientes muestran el aviso
      for (var i = 0; i < 8; i++) {
        await tester.tap(find.byTooltip('Sumar uno').first);
        await tester.pump(const Duration(milliseconds: 150));
      }
      expect(find.textContaining('Stock máximo'), findsOneWidget); // uno solo, sin acumular

      final aviso = tester.getRect(find.textContaining('Stock máximo'));
      final boton = tester.getRect(find.text('Continuar al pedido'));
      expect(aviso.overlaps(boton), isFalse);
      for (final e in find.byTooltip('Sumar uno').evaluate()) {
        expect(aviso.overlaps(tester.getRect(find.byWidget(e.widget))), isFalse);
      }
      if (tam.width >= 600) {
        // Dentro del área de contenido: a la derecha de la barra lateral
        expect(aviso.left, greaterThan(tester.getRect(find.byType(NavigationRail)).right));
      }

      // El pedido se puede continuar inmediatamente
      await tester.tap(find.text('Continuar al pedido'));
      await avanzar(tester, 4);
      expect(find.text('Confirmar pedido'), findsOneWidget);

      // Se cierra solo
      await tester.pump(const Duration(seconds: 3));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.textContaining('Stock máximo'), findsNothing);
    });
  }

  testWidgets('Agregar desde el detalle muestra el aviso y se cierra solo', (tester) async {
    await _montar(tester, '/catalogo', const Size(1366, 768), ThemeMode.light);
    await tester.tap(find.text('Funda iPhone 11').first);
    await avanzar(tester, 8);
    await tester.tap(find.text('Agregar al carrito'));
    await avanzar(tester, 4);
    expect(find.text('Funda iPhone 11 agregado al carrito'), findsOneWidget);
    expect(find.text('Ver carrito'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Funda iPhone 11 agregado al carrito'), findsNothing);
  });

  testWidgets('FAQ: crédito al final del contenido, centrado y con el estilo de las categorías', (tester) async {
    await _montar(tester, '/faq', const Size(1366, 768), ThemeMode.light);
    final credito = find.text('Software desarrollado por Nexus Bye');
    await tester.scrollUntilVisible(credito, 300, scrollable: find.byType(Scrollable).last);
    final estilo = tester.widget<Text>(credito).style!;
    final categoria = tester.widget<Text>(find.text('Envíos')).style!;
    expect(estilo.fontSize, categoria.fontSize);
    expect(estilo.color, categoria.color);
    expect(estilo.fontFamily, categoria.fontFamily);
    expect(estilo.fontWeight, categoria.fontWeight);
    // Debajo del último elemento (tarjeta de WhatsApp) y centrado en el contenido
    expect(tester.getRect(credito).top, greaterThan(tester.getRect(find.text('Contactar por WhatsApp')).bottom));
    final contenido = tester.getRect(find.text('Preguntas frecuentes'));
    expect((tester.getRect(credito).center.dx - (contenido.left + 450)).abs(), lessThan(2));
  });
}
