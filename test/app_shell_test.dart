import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:royal_app/models/producto.dart';
import 'package:royal_app/providers/busqueda_catalogo.dart';
import 'package:royal_app/providers/carrito_provider.dart';
import 'package:royal_app/providers/empleado_sesion.dart';
import 'package:royal_app/screens/app_shell.dart';
import 'package:royal_app/theme/app_theme.dart';
import 'package:royal_app/theme/theme_controller.dart';

/// Página de prueba con estado propio (contador) para verificar que no se pierde.
class _Pagina extends StatefulWidget {
  final String nombre;
  const _Pagina(this.nombre);
  @override
  State<_Pagina> createState() => _PaginaState();
}

class _PaginaState extends State<_Pagina> {
  int _toques = 0;
  @override
  Widget build(BuildContext context) => Center(
        child: TextButton(
          onPressed: () => setState(() => _toques++),
          child: Text('${widget.nombre}: $_toques'),
        ),
      );
}

GoRouter _router() => GoRouter(
      initialLocation: '/inicio',
      routes: [
        StatefulShellRoute(
          builder: (_, __, shell) => shell,
          navigatorContainerBuilder: (_, shell, ramas) => AppShell(navigationShell: shell, ramas: ramas),
          branches: [
            for (final r in ['inicio', 'catalogo', 'carrito', 'faq', 'empleados'])
              StatefulShellBranch(routes: [GoRoute(path: '/$r', builder: (_, __) => _Pagina(r))]),
          ],
        ),
      ],
    );

Producto _producto() => Producto(
      id: 'p1',
      nombre: 'Funda iPhone 15',
      categoria: 'solido',
      modelosCompatibles: const ['iPhone 15'],
      precio: 90000,
      colorHex: '#000000',
      personalizable: false,
      stock: 5,
      fotosUrls: const [],
    );

Future<CarritoProvider> _pump(WidgetTester tester, Size tamano, {bool empleado = false, GoRouter? router}) async {
  tester.view.physicalSize = tamano;
  tester.view.devicePixelRatio = 1;
  final carrito = CarritoProvider();
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: carrito),
        ChangeNotifierProvider(create: (_) => ThemeController()),
        ChangeNotifierProvider(create: (_) => EmpleadoSesion.prueba(esEmpleado: empleado)),
        ChangeNotifierProvider(create: (_) => BusquedaCatalogo()),
      ],
      child: MaterialApp.router(theme: AppTheme.light, darkTheme: AppTheme.dark, routerConfig: router ?? _router()),
    ),
  );
  await tester.pumpAndSettle();
  return carrito;
}

void main() {
  tearDown(() => TestWidgetsFlutterBinding.instance.platformDispatcher.views.first.reset());

  testWidgets('Escritorio: barra lateral extendida con etiquetas; Empleados oculto sin sesión', (tester) async {
    await _pump(tester, const Size(1366, 768));
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(tester.widget<NavigationRail>(find.byType(NavigationRail)).extended, isTrue);
    expect(find.text('Catálogo'), findsOneWidget);
    expect(find.text('Empleados'), findsNothing);
    expect(find.text('Buscar modelo, color o código'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Escritorio: la barra lateral se colapsa a íconos', (tester) async {
    await _pump(tester, const Size(1920, 1080));
    await tester.tap(find.byTooltip('Colapsar menú'));
    await tester.pumpAndSettle();
    expect(tester.widget<NavigationRail>(find.byType(NavigationRail)).extended, isFalse);
  });

  testWidgets('Tablet: rail solo de íconos', (tester) async {
    await _pump(tester, const Size(768, 1024));
    final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
    expect(rail.extended, isFalse);
    expect(find.byTooltip('Colapsar menú'), findsNothing);
  });

  testWidgets('Móvil: barra inferior y buscador como ícono', (tester) async {
    await _pump(tester, const Size(390, 844));
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.byTooltip('Buscar'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Con sesión de empleado aparece la sección Empleados', (tester) async {
    await _pump(tester, const Size(1366, 768), empleado: true);
    expect(find.text('Empleados'), findsOneWidget);
  });

  testWidgets('El carrito muestra el contador en la barra superior y lateral', (tester) async {
    final carrito = await _pump(tester, const Size(1366, 768));
    carrito.agregar(_producto());
    carrito.agregar(_producto());
    await tester.pumpAndSettle();
    expect(find.text('2'), findsNWidgets(2));
  });

  testWidgets('Navegar cambia la URL y al cambiar el tamaño no se pierde la sección ni su estado', (tester) async {
    final router = _router();
    await _pump(tester, const Size(1366, 768), router: router);

    await tester.tap(find.text('Catálogo'));
    await tester.pumpAndSettle();
    expect(router.routerDelegate.currentConfiguration.uri.path, '/catalogo');

    await tester.tap(find.text('catalogo: 0'));
    await tester.pump();
    await tester.tap(find.text('catalogo: 1'));
    await tester.pumpAndSettle();
    expect(find.text('catalogo: 2'), findsOneWidget);

    // Achicar la ventana a móvil y volver a escritorio
    tester.view.physicalSize = const Size(390, 844);
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('catalogo: 2'), findsOneWidget);

    tester.view.physicalSize = const Size(1920, 1080);
    await tester.pumpAndSettle();
    expect(find.text('catalogo: 2'), findsOneWidget);
    expect(router.routerDelegate.currentConfiguration.uri.path, '/catalogo');
  });

  testWidgets('Escribir en el buscador global lleva al catálogo', (tester) async {
    final router = _router();
    await _pump(tester, const Size(1366, 768), router: router);
    await tester.enterText(find.byType(TextField), 'rojo');
    await tester.pumpAndSettle();
    expect(router.routerDelegate.currentConfiguration.uri.path, '/catalogo');
  });

  testWidgets('El candado lleva a Empleados aunque no haya sesión', (tester) async {
    final router = _router();
    await _pump(tester, const Size(390, 844), router: router);
    await tester.tap(find.byTooltip('Acceso empleado'));
    await tester.pumpAndSettle();
    expect(router.routerDelegate.currentConfiguration.uri.path, '/empleados');
    expect(find.text('Empleados'), findsOneWidget); // destino visible mientras se está ahí
  });
}
