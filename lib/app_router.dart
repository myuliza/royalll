import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'providers/empleado_sesion.dart';
import 'screens/app_shell.dart';
import 'screens/carrito_screen.dart';
import 'screens/catalogo_screen.dart';
import 'screens/empleado_dashboard_screen.dart';
import 'screens/empleado_login_screen.dart';
import 'screens/faq_screen.dart';
import 'screens/home_screen.dart';

/// Rutas de la app. En web la URL refleja la sección (#/inicio, #/catalogo, …).
GoRouter crearRouter() {
  return GoRouter(
    initialLocation: '/inicio',
    redirect: (context, state) => state.uri.path == '/' ? '/inicio' : null,
    onException: (context, state, router) => router.go('/inicio'),
    routes: [
      StatefulShellRoute(
        builder: (context, state, shell) => shell,
        navigatorContainerBuilder: (context, shell, ramas) => AppShell(navigationShell: shell, ramas: ramas),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/inicio', builder: (_, __) => const HomeScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/catalogo',
              builder: (_, state) => CatalogoScreen(
                categoria: state.uri.queryParameters['categoria'],
                modelo: state.uri.queryParameters['modelo'],
                especial: state.uri.queryParameters['especial'],
              ),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/carrito', builder: (_, __) => const CarritoScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/faq', builder: (_, __) => const FaqScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/empleados', builder: (_, __) => const EmpleadosGate()),
          ]),
        ],
      ),
    ],
  );
}

/// Muestra el panel si hay un empleado con sesión; si no, la pantalla de acceso.
class EmpleadosGate extends StatelessWidget {
  const EmpleadosGate({super.key});

  @override
  Widget build(BuildContext context) {
    final sesion = context.watch<EmpleadoSesion>();
    final Widget hijo;
    if (sesion.cargando) {
      hijo = const Center(child: CircularProgressIndicator());
    } else if (sesion.esEmpleado) {
      hijo = const EmpleadoDashboardScreen(key: ValueKey('panel'));
    } else {
      // La sesión se actualiza sola al ingresar: no hace falta navegar
      hijo = EmpleadoLoginScreen(key: const ValueKey('login'), onIngresoExitoso: () {});
    }
    return AnimatedSwitcher(duration: const Duration(milliseconds: 250), child: hijo);
  }
}
