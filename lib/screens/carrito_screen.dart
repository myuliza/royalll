import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/cupon.dart';
import '../providers/carrito_provider.dart';
import '../theme/app_theme.dart';
import '../theme/breakpoints.dart';
import '../utils/formatters.dart';
import '../widgets/app_product_image.dart';
import '../widgets/ui/ui.dart';
import 'checkout_screen.dart';

class CarritoScreen extends StatefulWidget {
  const CarritoScreen({super.key});

  @override
  State<CarritoScreen> createState() => _CarritoScreenState();
}

class _CarritoScreenState extends State<CarritoScreen> {
  final _cuponController = TextEditingController();
  String? _errorCupon;
  bool _validando = false;

  @override
  void dispose() {
    _cuponController.dispose();
    super.dispose();
  }

  Future<void> _aplicarCupon(CarritoProvider carrito) async {
    final codigo = Cupon.normalizarCodigo(_cuponController.text);
    if (codigo.isEmpty) return;
    setState(() { _validando = true; _errorCupon = null; });

    try {
      final doc = await FirebaseFirestore.instance.collection('cupones').doc(codigo).get();
      if (!doc.exists) {
        setState(() => _errorCupon = 'El código "$codigo" no existe.');
        return;
      }
      final cupon = Cupon.fromMap({'codigo': codigo, ...doc.data()!});
      // Valida estado (activo, vigente, usos), compra mínima y alcance (categorías / modelos)
      final aplicable = carrito.items
          .where((i) => cupon.aplicaAProducto(i.producto.categoria, i.producto.modelosCompatibles))
          .fold(0, (s, i) => s + i.subtotal);
      final motivo = cupon.motivoInvalido(subtotal: carrito.subtotal, subtotalAplicable: aplicable);
      if (motivo != null) {
        setState(() => _errorCupon = motivo);
        return;
      }
      carrito.aplicarCupon(cupon);
      _cuponController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Código ${cupon.codigo} aplicado: -${formatPrice(carrito.descuento)}')),
        );
      }
    } catch (e) {
      setState(() => _errorCupon = 'No se pudo validar el código. Revisá tu conexión.');
    } finally {
      if (mounted) setState(() => _validando = false);
    }
  }

  void _eliminarItem(BuildContext context, CarritoProvider carrito, ItemCarrito item) {
    final producto = item.producto;
    final cantidad = item.cantidad;
    carrito.quitar(producto.id);

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text('${producto.nombre} eliminado del carrito'),
        action: SnackBarAction(
          label: 'Deshacer',
          onPressed: () {
            carrito.agregar(producto);
            if (cantidad > 1) {
              carrito.actualizarCantidad(producto.id, cantidad);
            }
          },
        ),
      ),
    );
  }

  void _restar(BuildContext context, CarritoProvider carrito, ItemCarrito item) {
    if (item.cantidad > 1) {
      carrito.actualizarCantidad(item.producto.id, item.cantidad - 1);
    } else {
      _eliminarItem(context, carrito, item);
    }
  }

  void _sumar(BuildContext context, CarritoProvider carrito, ItemCarrito item) {
    final ok = carrito.actualizarCantidad(item.producto.id, item.cantidad + 1);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Stock máximo de "${item.producto.nombre}" alcanzado (${item.producto.stock} disponibles).'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _continuar() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const CheckoutScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CarritoProvider>(
      builder: (context, carrito, _) {
        final estaVacio = carrito.items.isEmpty;

        return LayoutBuilder(
          builder: (context, constraints) {
            final ancho = constraints.maxWidth;
            final dosColumnas = ancho >= 900;
            final lateral = Breakpoints.paddingLateral(context);

            final encabezado = SectionHeader(
              titulo: 'Tu carrito',
              subtitulo: estaVacio
                  ? 'Todavía no agregaste productos'
                  : '${carrito.cantidadTotal} ${carrito.cantidadTotal == 1 ? 'producto' : 'productos'}',
              grande: true,
            );

            if (estaVacio) {
              return Scaffold(
                body: ListView(
                  padding: EdgeInsets.fromLTRB(lateral, AppSpacing.xl, lateral, AppSpacing.xl),
                  children: [
                    encabezado,
                    EmptyState(
                      icono: Icons.shopping_bag_outlined,
                      titulo: 'Tu carrito está vacío',
                      mensaje: 'Explorá el catálogo y agregá las fundas que te gusten.',
                      accion: 'Ver catálogo',
                      onAccion: () => context.go('/catalogo'),
                    ),
                  ],
                ),
              );
            }

            final lista = <Widget>[
              for (final item in carrito.items)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: _ItemCarritoCard(
                    key: ValueKey(item.producto.id),
                    item: item,
                    compacta: ancho < 520,
                    onRestar: () => _restar(context, carrito, item),
                    onSumar: () => _sumar(context, carrito, item),
                    onEliminar: () => _eliminarItem(context, carrito, item),
                  ),
                ),
            ];

            if (dosColumnas) {
              // Escritorio: lista a la izquierda y resumen fijo a la derecha
              return Scaffold(
                body: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(lateral, AppSpacing.xl, lateral, 0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ListView(
                              padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                              children: [encabezado, ...lista],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xl),
                          SizedBox(
                            width: 360,
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.only(top: 72, bottom: AppSpacing.xl),
                              child: AppCard(
                                padding: const EdgeInsets.all(AppSpacing.xl - 4),
                                child: _Resumen(
                                  carrito: carrito,
                                  campoCupon: _campoCupon(carrito),
                                  onContinuar: _continuar,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }

            // Móvil / ventana angosta: resumen fijo abajo
            return Scaffold(
              body: ListView(
                padding: EdgeInsets.fromLTRB(lateral, AppSpacing.xl, lateral, AppSpacing.lg),
                children: [
                  encabezado,
                  ...lista,
                  const SizedBox(height: AppSpacing.sm),
                  _campoCupon(carrito),
                ],
              ),
              bottomNavigationBar: SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  decoration: BoxDecoration(
                    color: context.royal.superficie,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: _Resumen(carrito: carrito, onContinuar: _continuar),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _campoCupon(CarritoProvider carrito) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextField(
            controller: _cuponController,
            decoration: InputDecoration(
              labelText: 'Código promocional',
              prefixIcon: const Icon(Icons.confirmation_number_outlined),
              errorText: _errorCupon,
              errorMaxLines: 3,
              isDense: true,
            ),
            textCapitalization: TextCapitalization.characters,
            onSubmitted: (_) => _validando ? null : _aplicarCupon(carrito),
          ),
        ),
        const SizedBox(width: 8),
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: OutlinedButton(
            onPressed: _validando ? null : () => _aplicarCupon(carrito),
            child: _validando
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Aplicar'),
          ),
        ),
      ],
    );
  }
}

class _Resumen extends StatelessWidget {
  final CarritoProvider carrito;
  final Widget? campoCupon;
  final VoidCallback onContinuar;

  const _Resumen({required this.carrito, required this.onContinuar, this.campoCupon});

  @override
  Widget build(BuildContext context) {
    final royal = context.royal;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (campoCupon != null) ...[
          Text('Resumen', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: royal.textoPrincipal)),
          const SizedBox(height: AppSpacing.lg),
          campoCupon!,
          const SizedBox(height: AppSpacing.lg),
        ],
        _filaResumen(context, 'Subtotal', carrito.subtotal),
        if (carrito.cuponAplicado != null) ...[
          _filaResumen(
            context,
            'Descuento (${carrito.cuponAplicado!.codigo} · ${carrito.cuponAplicado!.descripcionDescuento})',
            -carrito.descuento,
            color: AppColors.dorado,
            onQuitar: carrito.quitarCupon,
          ),
          if (carrito.avisoCupon != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 16, color: Colors.orange),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      carrito.avisoCupon!,
                      style: const TextStyle(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
        ],
        const Padding(padding: EdgeInsets.symmetric(vertical: 6), child: Divider()),
        _filaResumen(context, 'Total', carrito.total, esTotal: true),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: onContinuar,
          icon: const Icon(Icons.arrow_forward_rounded),
          iconAlignment: IconAlignment.end,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
          label: const Text('Continuar al pedido'),
        ),
      ],
    );
  }

  Widget _filaResumen(BuildContext context, String label, int valor,
      {bool esTotal = false, Color? color, VoidCallback? onQuitar}) {
    final royal = context.royal;
    final formateado = '${valor < 0 ? '-' : ''}${formatPrice(valor.abs())}';
    final estilo = TextStyle(
      fontWeight: esTotal ? FontWeight.w800 : FontWeight.w500,
      fontSize: esTotal ? 18 : 14,
      color: color ?? (esTotal ? royal.textoPrincipal : royal.textoSecundario),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Flexible(child: Text(label, style: estilo, overflow: TextOverflow.ellipsis)),
          if (onQuitar != null)
            IconButton(
              tooltip: 'Quitar código',
              visualDensity: VisualDensity.compact,
              iconSize: 16,
              onPressed: onQuitar,
              icon: const Icon(Icons.close_rounded),
            ),
          const Spacer(),
          Text(formateado, style: estilo),
        ],
      ),
    );
  }
}

class _ItemCarritoCard extends StatelessWidget {
  final ItemCarrito item;
  final bool compacta;
  final VoidCallback onRestar;
  final VoidCallback onSumar;
  final VoidCallback onEliminar;

  const _ItemCarritoCard({
    super.key,
    required this.item,
    required this.compacta,
    required this.onRestar,
    required this.onSumar,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    final royal = context.royal;
    final p = item.producto;
    final colorPrecio = context.esOscuro ? AppColors.doradoClaro : AppColors.azul;

    final selector = _SelectorCantidad(cantidad: item.cantidad, onRestar: onRestar, onSumar: onSumar);
    final subtotal = Text(
      formatPrice(item.subtotal),
      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: colorPrecio),
    );

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: compacta ? 64 : 84,
            height: compacta ? 64 : 84,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: royal.fondoImagen,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: AppProductImage(imageUrl: p.fotoPrincipalUrl, fit: BoxFit.contain),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.nombre,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w700, color: royal.textoPrincipal),
                ),
                const SizedBox(height: 2),
                Text(
                  p.colorLegible.isNotEmpty ? '${p.precioFormateado} c/u • ${p.colorLegible}' : '${p.precioFormateado} c/u',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: royal.textoSecundario),
                ),
                if (compacta) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Row(children: [selector, const Spacer(), subtotal]),
                ],
              ],
            ),
          ),
          if (!compacta) ...[
            const SizedBox(width: AppSpacing.md),
            selector,
            const SizedBox(width: AppSpacing.lg),
            SizedBox(width: 110, child: Align(alignment: Alignment.centerRight, child: subtotal)),
          ],
          IconButton(
            tooltip: 'Eliminar',
            icon: const Icon(Icons.delete_outline),
            onPressed: onEliminar,
          ),
        ],
      ),
    );
  }
}

class _SelectorCantidad extends StatelessWidget {
  final int cantidad;
  final VoidCallback onRestar;
  final VoidCallback onSumar;

  const _SelectorCantidad({required this.cantidad, required this.onRestar, required this.onSumar});

  @override
  Widget build(BuildContext context) {
    final royal = context.royal;
    return Container(
      decoration: BoxDecoration(
        color: royal.superficieAlta,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: royal.borde),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: cantidad > 1 ? 'Restar uno' : 'Eliminar',
            visualDensity: VisualDensity.compact,
            iconSize: 18,
            icon: const Icon(Icons.remove_rounded),
            onPressed: onRestar,
          ),
          AnimatedSwitcher(
            duration: AppDurations.rapida,
            transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
            child: SizedBox(
              key: ValueKey(cantidad),
              width: 28,
              child: Text(
                '$cantidad',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w700, color: royal.textoPrincipal),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Sumar uno',
            visualDensity: VisualDensity.compact,
            iconSize: 18,
            icon: const Icon(Icons.add_rounded),
            onPressed: onSumar,
          ),
        ],
      ),
    );
  }
}
