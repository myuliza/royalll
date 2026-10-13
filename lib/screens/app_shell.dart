import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/busqueda_catalogo.dart';
import '../providers/carrito_provider.dart';
import '../providers/empleado_sesion.dart';
import '../theme/app_theme.dart';
import '../theme/breakpoints.dart';
import '../widgets/royal_logo.dart';
import '../widgets/theme_toggle_button.dart';

/// Índices de las secciones (ramas del router).
class Seccion {
  static const inicio = 0;
  static const catalogo = 1;
  static const carrito = 2;
  static const faq = 3;
  static const empleados = 4;
}

class _Destino {
  final int rama;
  final IconData icono;
  final IconData iconoActivo;
  final String etiqueta;
  const _Destino(this.rama, this.icono, this.iconoActivo, this.etiqueta);
}

const _destinosBase = [
  _Destino(Seccion.inicio, Icons.home_outlined, Icons.home_rounded, 'Inicio'),
  _Destino(Seccion.catalogo, Icons.grid_view_outlined, Icons.grid_view_rounded, 'Catálogo'),
  _Destino(Seccion.carrito, Icons.shopping_bag_outlined, Icons.shopping_bag_rounded, 'Carrito'),
  _Destino(Seccion.faq, Icons.help_outline_rounded, Icons.help_rounded, 'FAQ'),
];
const _destinoEmpleados =
    _Destino(Seccion.empleados, Icons.admin_panel_settings_outlined, Icons.admin_panel_settings_rounded, 'Empleados');

/// Marco de la app: barra superior + barra lateral (escritorio/tablet) o barra inferior (móvil).
/// Cada sección mantiene su propio estado y scroll; cambiar el tamaño de la ventana no lo pierde.
class AppShell extends StatefulWidget {
  final StatefulNavigationShell navigationShell;
  final List<Widget> ramas;

  const AppShell({super.key, required this.navigationShell, required this.ramas});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  bool _railColapsado = false;

  int get _actual => widget.navigationShell.currentIndex;

  void _ir(int rama) {
    FocusManager.instance.primaryFocus?.unfocus();
    // Tocar la sección activa vuelve a su pantalla inicial (como en las apps nativas)
    widget.navigationShell.goBranch(rama, initialLocation: rama == _actual);
  }

  List<_Destino> _destinos(bool esEmpleado) => [
        ..._destinosBase,
        if (esEmpleado || _actual == Seccion.empleados) _destinoEmpleados,
      ];

  @override
  Widget build(BuildContext context) {
    final tipo = Breakpoints.of(context);
    final movil = tipo == TipoPantalla.movil;
    final royal = context.royal;
    final esEmpleado = context.select<EmpleadoSesion, bool>((s) => s.esEmpleado);
    final destinos = _destinos(esEmpleado);
    final seleccionado = destinos.indexWhere((d) => d.rama == _actual);

    final contenido = _RamasAnimadas(actual: _actual, ramas: widget.ramas);

    return Scaffold(
      backgroundColor: royal.barraLateral,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _BarraSuperior(
              tipo: tipo,
              esEmpleado: esEmpleado,
              onIr: _ir,
              seccionActual: _actual,
            ),
            Expanded(
              child: Row(
                children: [
                  if (!movil)
                    KeyedSubtree(
                      key: const ValueKey('barra-lateral'),
                      child: _BarraLateral(
                        destinos: destinos,
                        seleccionado: seleccionado,
                        extendida: tipo == TipoPantalla.escritorio && !_railColapsado,
                        puedeColapsar: tipo == TipoPantalla.escritorio,
                        onColapsar: () => setState(() => _railColapsado = !_railColapsado),
                        onIr: _ir,
                      ),
                    ),
                  Expanded(
                    key: const ValueKey('contenido'),
                    child: ClipRRect(
                      borderRadius: movil
                          ? BorderRadius.zero
                          : const BorderRadius.only(topLeft: Radius.circular(AppRadius.xl)),
                      child: ColoredBox(
                        color: royal.fondo,
                        child: MediaQuery.removePadding(context: context, removeTop: true, child: contenido),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: movil
          ? NavigationBar(
              selectedIndex: seleccionado < 0 ? 0 : seleccionado,
              onDestinationSelected: (i) => _ir(destinos[i].rama),
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              destinations: [
                for (final d in destinos)
                  NavigationDestination(
                    icon: _IconoDestino(destino: d, activo: false),
                    selectedIcon: _IconoDestino(destino: d, activo: true),
                    label: d.etiqueta,
                  ),
              ],
            )
          : null,
    );
  }
}

/// Ícono de destino; el carrito muestra el contador de unidades.
class _IconoDestino extends StatelessWidget {
  final _Destino destino;
  final bool activo;
  final Color? color;

  const _IconoDestino({required this.destino, required this.activo, this.color});

  @override
  Widget build(BuildContext context) {
    final icono = Icon(activo ? destino.iconoActivo : destino.icono, color: color ?? (activo ? AppColors.dorado : null));
    if (destino.rama != Seccion.carrito) return icono;
    final cantidad = context.select<CarritoProvider, int>((c) => c.cantidadTotal);
    return Badge(
      isLabelVisible: cantidad > 0,
      label: Text('$cantidad'),
      backgroundColor: AppColors.dorado,
      textColor: AppColors.azul,
      child: icono,
    );
  }
}

const double _altoLeading = 56; // IconButton (48) + separación (8)

class _BarraLateral extends StatelessWidget {
  final List<_Destino> destinos;
  final int seleccionado;
  final bool extendida;
  final bool puedeColapsar;
  final VoidCallback onColapsar;
  final ValueChanged<int> onIr;

  const _BarraLateral({
    required this.destinos,
    required this.seleccionado,
    required this.extendida,
    required this.puedeColapsar,
    required this.onColapsar,
    required this.onIr,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      extended: extendida,
      minExtendedWidth: 216,
      labelType: NavigationRailLabelType.none,
      selectedIndex: seleccionado < 0 ? null : seleccionado,
      onDestinationSelected: (i) => onIr(destinos[i].rama),
      // Ítems centrados verticalmente; el botón de colapsar (leading) queda fijo arriba
      groupAlignment: 0.0,
      leading: puedeColapsar
          ? Padding(
              padding: const EdgeInsets.only(bottom: _altoLeading - 48),
              child: IconButton(
                tooltip: extendida ? 'Colapsar menú' : 'Expandir menú',
                color: Colors.white70,
                onPressed: onColapsar,
                icon: AnimatedRotation(
                  turns: extendida ? 0 : 0.5,
                  duration: AppDurations.media,
                  child: const Icon(Icons.keyboard_double_arrow_left_rounded),
                ),
              ),
            )
          : const SizedBox(height: AppSpacing.sm),
      // Espacio que equilibra el botón de arriba (+16 por el margen interno superior del rail):
      // el grupo de ítems queda en el centro exacto de la barra
      trailing: SizedBox(height: (puedeColapsar ? _altoLeading : AppSpacing.sm) + 16),
      destinations: [
        for (final d in destinos)
          NavigationRailDestination(
            icon: _IconoDestino(destino: d, activo: false, color: Colors.white70),
            selectedIcon: _IconoDestino(destino: d, activo: true, color: AppColors.azul),
            label: Text(d.etiqueta),
            padding: const EdgeInsets.symmetric(vertical: 2),
          ),
      ],
    );
  }
}

class _BarraSuperior extends StatelessWidget {
  final TipoPantalla tipo;
  final bool esEmpleado;
  final int seccionActual;
  final ValueChanged<int> onIr;

  const _BarraSuperior({
    required this.tipo,
    required this.esEmpleado,
    required this.seccionActual,
    required this.onIr,
  });

  @override
  Widget build(BuildContext context) {
    final movil = tipo == TipoPantalla.movil;
    final escritorio = tipo == TipoPantalla.escritorio;
    final busqueda = context.read<BusquedaCatalogo>();
    final cantidad = context.select<CarritoProvider, int>((c) => c.cantidadTotal);

    return SizedBox(
      height: escritorio ? 72 : 60,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: movil ? AppSpacing.sm : AppSpacing.lg),
        child: Row(
          children: [
            Semantics(
              button: true,
              label: 'Ir al inicio',
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                onTap: () => onIr(Seccion.inicio),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: RoyalLogo(
                    size: escritorio ? 60 : 46,
                    isLight: true,
                    imagePath: 'assets/logo royal.png',
                  ),
                ),
              ),
            ),
            SizedBox(width: escritorio ? 128 : AppSpacing.md),
            if (!movil)
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: _CampoBusqueda(
                      controller: busqueda.controller,
                      onCambio: (v) {
                        if (v.trim().isNotEmpty && seccionActual != Seccion.catalogo) onIr(Seccion.catalogo);
                      },
                    ),
                  ),
                ),
              )
            else
              const Spacer(),
            const SizedBox(width: AppSpacing.sm),
            if (movil)
              IconButton(
                tooltip: 'Buscar',
                color: Colors.white,
                icon: const Icon(Icons.search_rounded),
                onPressed: () {
                  onIr(Seccion.catalogo);
                  WidgetsBinding.instance.addPostFrameCallback((_) => busqueda.focoCatalogo.requestFocus());
                },
              ),
            IconButton(
              tooltip: 'Carrito',
              color: Colors.white,
              onPressed: () => onIr(Seccion.carrito),
              icon: Badge(
                isLabelVisible: cantidad > 0,
                label: Text('$cantidad'),
                backgroundColor: AppColors.dorado,
                textColor: AppColors.azul,
                child: const Icon(Icons.shopping_bag_outlined),
              ),
            ),
            IconButton(
              tooltip: esEmpleado ? 'Panel de empleados' : 'Acceso empleado',
              color: Colors.white,
              onPressed: () => onIr(Seccion.empleados),
              icon: Icon(esEmpleado ? Icons.admin_panel_settings_outlined : Icons.lock_outline, size: 22),
            ),
            const ThemeToggleButton(color: Colors.white),
          ],
        ),
      ),
    );
  }
}

class _CampoBusqueda extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onCambio;

  const _CampoBusqueda({required this.controller, required this.onCambio});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, valor, _) => TextField(
        controller: controller,
        onChanged: onCambio,
        textInputAction: TextInputAction.search,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        cursorColor: AppColors.dorado,
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.08),
          hintText: 'Buscar modelo, color o código',
          hintStyle: const TextStyle(color: Colors.white54, fontSize: 14),
          prefixIcon: const Icon(Icons.search_rounded, color: Colors.white54, size: 20),
          suffixIcon: valor.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Borrar búsqueda',
                  icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 18),
                  onPressed: controller.clear,
                ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            borderSide: const BorderSide(color: AppColors.dorado, width: 1.5),
          ),
        ),
      ),
    );
  }
}

/// Contenedor de las secciones: todas quedan montadas (conservan estado y scroll)
/// y se cruzan con un fundido corto al cambiar de sección.
class _RamasAnimadas extends StatelessWidget {
  final int actual;
  final List<Widget> ramas;

  const _RamasAnimadas({required this.actual, required this.ramas});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        for (var i = 0; i < ramas.length; i++)
          _Rama(key: ValueKey('rama-$i'), activa: i == actual, child: ramas[i]),
      ],
    );
  }
}

class _Rama extends StatelessWidget {
  final bool activa;
  final Widget child;

  const _Rama({super.key, required this.activa, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: activa ? 1 : 0,
      duration: AppDurations.media,
      curve: Curves.easeOut,
      child: AnimatedSlide(
        offset: activa ? Offset.zero : const Offset(0, 0.015),
        duration: AppDurations.media,
        curve: Curves.easeOut,
        child: IgnorePointer(
          ignoring: !activa,
          child: ExcludeFocus(
            excluding: !activa,
            child: ExcludeSemantics(
              excluding: !activa,
              child: TickerMode(enabled: activa, child: child),
            ),
          ),
        ),
      ),
    );
  }
}
