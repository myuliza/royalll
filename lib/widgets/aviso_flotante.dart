import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/breakpoints.dart';

/// Aviso corto del flujo de compra ("X agregado al carrito", "Deshacer", etc.).
///
/// - Se cierra solo (por defecto a los 2,5 s), también si tiene botón de acción.
/// - Aparece arriba a la derecha dentro del área de contenido (debajo de la barra superior),
///   con ancho máximo de 360 px: nunca queda bajo la barra lateral ni tapa el botón de
///   realizar el pedido o los botones de cantidad, que están abajo / a la izquierda.
/// - Antes de mostrar uno nuevo se cierra el anterior, así no se acumulan.
void mostrarAviso(
  BuildContext context,
  String mensaje, {
  String? accion,
  VoidCallback? onAccion,
  IconData icono = Icons.check_circle_rounded,
  Color? color,
  Duration duracion = const Duration(milliseconds: 2500),
}) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  _AvisoActual.cerrar();

  late final OverlayEntry entrada;
  entrada = OverlayEntry(
    builder: (ctx) => _Aviso(
      mensaje: mensaje,
      accion: accion,
      onAccion: onAccion,
      icono: icono,
      color: color ?? AppColors.verdeStock,
      duracion: duracion,
      onCerrado: () {
        if (_AvisoActual.entrada == entrada) _AvisoActual.entrada = null;
        if (entrada.mounted) entrada.remove();
      },
    ),
  );
  _AvisoActual.entrada = entrada;
  overlay.insert(entrada);
}

/// Cierra el aviso visible (si hay uno).
void cerrarAviso() => _AvisoActual.cerrar();

class _AvisoActual {
  static OverlayEntry? entrada;

  static void cerrar() {
    final e = entrada;
    entrada = null;
    if (e != null && e.mounted) e.remove();
  }
}

/// Alto de la barra superior del marco de la app (ver AppShell).
double _altoBarraSuperior(BuildContext context) => Breakpoints.esEscritorio(context) ? 72 : 60;

class _Aviso extends StatefulWidget {
  final String mensaje;
  final String? accion;
  final VoidCallback? onAccion;
  final IconData icono;
  final Color color;
  final Duration duracion;
  final VoidCallback onCerrado;

  const _Aviso({
    required this.mensaje,
    required this.accion,
    required this.onAccion,
    required this.icono,
    required this.color,
    required this.duracion,
    required this.onCerrado,
  });

  @override
  State<_Aviso> createState() => _AvisoState();
}

class _AvisoState extends State<_Aviso> with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(vsync: this, duration: AppDurations.media)..forward();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.duracion, _cerrar);
  }

  Future<void> _cerrar() async {
    _timer?.cancel();
    if (!mounted) return;
    await _anim.reverse();
    widget.onCerrado();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final movil = Breakpoints.esMovil(context);
    final ancho = (media.size.width - 32).clamp(0.0, 360.0);
    final top = media.padding.top + _altoBarraSuperior(context) + 12;
    final royal = context.royal;

    return Positioned(
      top: top,
      right: movil ? 16 : 24,
      width: ancho,
      child: FadeTransition(
        opacity: _anim,
        child: SlideTransition(
          position: Tween(begin: const Offset(0, -0.25), end: Offset.zero)
              .animate(CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic)),
          child: Semantics(
            liveRegion: true,
            child: Material(
              color: context.esOscuro ? AppColors.oscuroSuperficieAlta : AppColors.azul,
              elevation: 8,
              shadowColor: Colors.black54,
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
                child: Row(
                  children: [
                    Icon(widget.icono, color: widget.color, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.mensaje,
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                    if (widget.accion != null)
                      TextButton(
                        style: TextButton.styleFrom(foregroundColor: AppColors.doradoClaro),
                        onPressed: () {
                          widget.onAccion?.call();
                          _cerrar();
                        },
                        child: Text(widget.accion!),
                      ),
                    IconButton(
                      tooltip: 'Cerrar',
                      visualDensity: VisualDensity.compact,
                      iconSize: 18,
                      color: royal.textoAtenuado,
                      icon: const Icon(Icons.close_rounded),
                      onPressed: _cerrar,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
