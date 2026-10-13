import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Efecto de elevación sutil al pasar el mouse o enfocar con teclado (Tab).
/// En táctil no hay hover: la respuesta al toque la da el InkWell del hijo.
class HoverLift extends StatefulWidget {
  final Widget Function(BuildContext context, bool activo) builder;
  final bool habilitado;

  const HoverLift({super.key, required this.builder, this.habilitado = true});

  @override
  State<HoverLift> createState() => _HoverLiftState();
}

class _HoverLiftState extends State<HoverLift> {
  bool _hover = false;
  bool _foco = false;

  @override
  Widget build(BuildContext context) {
    final activo = widget.habilitado && (_hover || _foco);
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onFocusChange: (f) => setState(() => _foco = f),
        child: AnimatedSlide(
          duration: AppDurations.rapida,
          curve: Curves.easeOut,
          offset: activo ? const Offset(0, -0.012) : Offset.zero,
          child: AnimatedScale(
            duration: AppDurations.rapida,
            curve: Curves.easeOut,
            scale: activo ? 1.015 : 1,
            child: widget.builder(context, activo),
          ),
        ),
      ),
    );
  }
}
