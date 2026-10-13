import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/producto.dart';
import '../providers/carrito_provider.dart';
import '../theme/app_theme.dart';
import '../theme/breakpoints.dart';
import '../utils/visual.dart';
import '../widgets/app_product_image.dart';
import 'catalogo_screen.dart';

/// Abre el detalle de un producto: diálogo de dos columnas en escritorio/tablet
/// y pantalla completa en móvil.
void abrirDetalleProducto(BuildContext context, Producto producto) {
  if (Breakpoints.esMovil(context)) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProductoDetalleScreen(producto: producto)),
    );
    return;
  }
  showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (dialogCtx) => _DialogoDetalle(producto: producto),
  );
}

/// Agrega al carrito con la misma lógica de siempre: respeta el stock, cierra la vista
/// (para seguir comprando) y avisa con un SnackBar con acceso al carrito.
void _agregarAlCarrito(BuildContext context, Producto producto) {
  final exito = context.read<CarritoProvider>().agregar(producto);
  // Capturados antes del pop: el SnackBar sobrevive a esta pantalla
  final messenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context);
  final router = GoRouter.maybeOf(context);
  messenger.hideCurrentSnackBar();
  if (exito) {
    HapticFeedback.lightImpact();
    // Cierre automático al agregar, para seguir comprando
    navigator.pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text('${producto.nombre} agregado al carrito'),
        action: router == null
            ? null
            : SnackBarAction(label: 'Ver carrito', onPressed: () => router.go('/carrito')),
      ),
    );
  } else {
    messenger.showSnackBar(
      const SnackBar(
        content: Text('No es posible agregar más: stock máximo alcanzado.'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}

/// Detalle en pantalla completa (móvil).
class ProductoDetalleScreen extends StatelessWidget {
  final Producto producto;
  const ProductoDetalleScreen({super.key, required this.producto});

  @override
  Widget build(BuildContext context) {
    final agotado = producto.stock <= 0;
    final royal = context.royal;

    return Scaffold(
      appBar: AppBar(
        title: Text(producto.nombre),
        backgroundColor: royal.fondo,
        foregroundColor: royal.textoPrincipal,
        titleTextStyle: TextStyle(
          fontFamily: AppTheme.fontFamily,
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: royal.textoPrincipal,
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: royal.fondoImagen,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                ),
                child: AppProductImage(imageUrl: producto.fotoPrincipalUrl, fit: BoxFit.contain),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: ProductoDetalleInfo(producto: producto),
            ),
          ],
        ),
      ),
      // Acción principal fija abajo, protegida de la barra de navegación del sistema
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: _BotonAgregar(producto: producto, agotado: agotado),
      ),
    );
  }
}

/// Detalle en diálogo (escritorio / tablet).
class _DialogoDetalle extends StatelessWidget {
  final Producto producto;
  const _DialogoDetalle({required this.producto});

  @override
  Widget build(BuildContext context) {
    final royal = context.royal;
    final agotado = producto.stock <= 0;
    final dosColumnas = MediaQuery.sizeOf(context).width >= 760;

    final imagen = Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: royal.fondoImagen,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: AppProductImage(imageUrl: producto.fotoPrincipalUrl, fit: BoxFit.contain),
    );

    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        ProductoDetalleInfo(producto: producto),
        const SizedBox(height: AppSpacing.lg),
        _BotonAgregar(producto: producto, agotado: agotado),
      ],
    );

    return Dialog(
      insetPadding: const EdgeInsets.all(AppSpacing.xl),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: dosColumnas ? 880 : 460, maxHeight: 640),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: dosColumnas
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: AspectRatio(aspectRatio: 1, child: imagen)),
                        const SizedBox(width: AppSpacing.xl),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.only(top: AppSpacing.sm, right: 52),
                            child: info,
                          ),
                        ),
                      ],
                    )
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(height: 240, child: imagen),
                          const SizedBox(height: AppSpacing.lg),
                          info,
                        ],
                      ),
                    ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton.filledTonal(
                tooltip: 'Cerrar',
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BotonAgregar extends StatelessWidget {
  final Producto producto;
  final bool agotado;
  const _BotonAgregar({required this.producto, required this.agotado});

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      icon: const Icon(Icons.add_shopping_cart),
      label: Text(agotado ? 'Producto agotado' : 'Agregar al carrito'),
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.dorado,
        foregroundColor: AppColors.azul,
        minimumSize: const Size.fromHeight(52),
      ),
      onPressed: agotado ? null : () => _agregarAlCarrito(context, producto),
    );
  }
}

/// Información del producto (categoría, stock, nombre, precios, color, modelos, personalización).
class ProductoDetalleInfo extends StatelessWidget {
  final Producto producto;
  const ProductoDetalleInfo({super.key, required this.producto});

  @override
  Widget build(BuildContext context) {
    final royal = context.royal;
    final tieneDescuento = producto.enDescuento && producto.porcentajeDescuento > 0;
    final agotado = producto.stock <= 0;
    final colorPrecio = context.esOscuro ? AppColors.doradoClaro : AppColors.azul;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Categoría y Código
        Row(
          children: [
            Expanded(
              child: Text(
                producto.colorLegible.isNotEmpty
                    ? '${producto.categoria.toUpperCase()} • ${producto.colorLegible}'
                    : producto.categoria.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: royal.textoSecundario,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: agotado
                    ? Colors.red.withValues(alpha: 0.12)
                    : AppColors.verdeStock.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                agotado ? 'Agotado' : 'Stock: ${producto.stock} un.',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: agotado ? Colors.red : AppColors.verdeStock,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Nombre del modelo
        Text(producto.nombre, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 10),

        // Precios
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 10,
          runSpacing: 4,
          children: [
            Text(
              producto.precioFinalFormateado,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: tieneDescuento ? AppColors.rojoDescuento : colorPrecio,
              ),
            ),
            if (tieneDescuento) ...[
              Text(
                producto.precioOriginalFormateado,
                style: TextStyle(
                  fontSize: 16,
                  decoration: TextDecoration.lineThrough,
                  color: royal.textoAtenuado,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.rojoDescuento,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '-${producto.porcentajeDescuento}% OFF',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),

        if (producto.colorHex.isNotEmpty) ...[
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: colorDesdeHex(producto.colorHex),
                  shape: BoxShape.circle,
                  border: Border.all(color: royal.borde, width: 1.5),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Color: ${CatalogoScreen.nombreColorLegible(producto.colorHex)}',
                style: TextStyle(fontSize: 14, color: royal.textoPrincipal),
              ),
            ],
          ),
        ],

        const SizedBox(height: 18),
        Text('Modelos compatibles', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: producto.modelosCompatibles
              .map((m) => Chip(
                    avatar: Icon(Icons.phone_iphone_rounded, size: 16, color: royal.textoSecundario),
                    label: Text(m),
                    backgroundColor: royal.superficieAlta,
                  ))
              .toList(),
        ),

        if (producto.personalizable) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.dorado.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(color: AppColors.dorado.withValues(alpha: 0.6)),
            ),
            child: Row(
              children: [
                const Icon(Icons.brush_outlined, color: AppColors.dorado),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Este modelo se puede personalizar. Coordinamos el diseño por WhatsApp al confirmar el pedido.',
                    style: TextStyle(color: royal.textoPrincipal),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
