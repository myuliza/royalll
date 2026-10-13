import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../models/producto.dart';
import '../theme/app_theme.dart';
import '../theme/breakpoints.dart';
import '../utils/visual.dart';
import '../widgets/producto_card.dart';
import '../widgets/ui/ui.dart';
import 'catalogo_screen.dart';

/// Sección Inicio. La navegación entre secciones la maneja el router (AppShell).
class HomeScreen extends StatelessWidget {
  /// Solo para tests: datos fijos en lugar de Firestore.
  @visibleForTesting
  final List<Producto>? productosDePrueba;

  const HomeScreen({super.key, this.productosDePrueba});

  static void _irCatalogo(BuildContext context,
      [Map<String, String>? filtros]) {
    context.go(Uri(path: '/catalogo', queryParameters: filtros).toString());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: productosDePrueba != null
            ? null
            : FirebaseFirestore.instance.collection('productos').snapshots(),
        builder: (context, snapshot) {
          final productos = productosDePrueba ??
              (snapshot.hasData
                  ? snapshot.data!.docs
                      .map((d) => Producto.fromMap(
                          d.id, d.data() as Map<String, dynamic>))
                      .toList()
                  : null);

          return LayoutBuilder(
            builder: (context, constraints) {
              final lateral = math.max(
                Breakpoints.paddingLateral(context),
                (constraints.maxWidth - Breakpoints.anchoMaximo) / 2,
              );
              return ListView(
                padding: EdgeInsets.fromLTRB(
                    lateral, AppSpacing.xl, lateral, AppSpacing.xxl),
                children: [
                  const SectionHeader(
                    titulo: 'Inicio',
                    subtitulo:
                        'Fundas premium para tu iPhone: diseño, protección y estilo.',
                    grande: true,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _TarjetasDestacadas(productos: productos),
                  const SizedBox(height: AppSpacing.xl),
                  _HeroBanner(onVerColeccion: () => _irCatalogo(context)),
                  const SizedBox(height: AppSpacing.xxl),
                  if (snapshot.hasError)
                    const EmptyState.error(
                        titulo: 'No se pudieron cargar los productos')
                  else ...[
                    _SeccionCategorias(productos: productos),
                    const SizedBox(height: AppSpacing.xxl),
                    _SeccionModelos(productos: productos),
                    const SizedBox(height: AppSpacing.xxl),
                    _SeccionPopulares(productos: productos),
                  ],
                ],
              );
            },
          );
        },
      ),
    );
  }
}

/// Grilla adaptable: columnas según el ancho disponible.
class _Grilla extends StatelessWidget {
  final double anchoMinimo;
  final double espacio;
  final List<Widget> children;

  const _Grilla(
      {required this.anchoMinimo,
      required this.children,
      this.espacio = AppSpacing.lg});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final columnas = math.max(
            1, ((c.maxWidth + espacio) / (anchoMinimo + espacio)).floor());
        final ancho = (c.maxWidth - espacio * (columnas - 1)) / columnas;
        return Wrap(
          spacing: espacio,
          runSpacing: espacio,
          children: [
            for (final w in children) SizedBox(width: ancho, child: w)
          ],
        );
      },
    );
  }
}

class _TarjetasDestacadas extends StatelessWidget {
  final List<Producto>? productos;
  const _TarjetasDestacadas({required this.productos});

  @override
  Widget build(BuildContext context) {
    String contar(bool Function(Producto) f) =>
        productos == null ? '…' : '${productos!.where(f).length}';
    final escritorio = Breakpoints.esEscritorio(context);

    final tarjetas = [
      FeatureTile(
        titulo: 'Colección iPhone',
        subtitulo: 'Todas las fundas',
        icono: Icons.phone_iphone_rounded,
        degradado: AppColors.degradadoCyan,
        contador: productos == null ? '…' : '${productos!.length}',
        onTap: () => HomeScreen._irCatalogo(context),
      ),
      FeatureTile(
        titulo: 'Ofertas',
        subtitulo: 'Con descuento',
        icono: Icons.local_offer_rounded,
        degradado: AppColors.degradadoNaranja,
        contador:
            contar((p) => FiltroEspecial.cumple(FiltroEspecial.ofertas, p)),
        onTap: () => HomeScreen._irCatalogo(
            context, {'especial': FiltroEspecial.ofertas}),
      ),
      FeatureTile(
        titulo: 'Nuevos modelos',
        subtitulo: 'iPhone 17 y 18',
        icono: Icons.new_releases_rounded,
        degradado: AppColors.degradadoVerde,
        contador: contar(FiltroEspecial.esNuevo),
        onTap: () => HomeScreen._irCatalogo(
            context, {'especial': FiltroEspecial.nuevos}),
      ),
      FeatureTile(
        titulo: 'Personalizables',
        subtitulo: 'Tu diseño',
        icono: Icons.brush_rounded,
        degradado: AppColors.degradadoRosa,
        contador: contar((p) => p.personalizable),
        onTap: () => HomeScreen._irCatalogo(
            context, {'especial': FiltroEspecial.personalizables}),
      ),
    ];

    return _Grilla(anchoMinimo: escritorio ? 220 : 150, children: tarjetas);
  }
}

/// Banner de colección (antes hero grande, ahora tarjeta compacta)
class _HeroBanner extends StatelessWidget {
  final VoidCallback onVerColeccion;

  const _HeroBanner({required this.onVerColeccion});

  @override
  Widget build(BuildContext context) {
    final movil = Breakpoints.esMovil(context);
    return Container(
      constraints: const BoxConstraints(minHeight: 132),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        gradient: const LinearGradient(
          colors: [AppColors.azul, AppColors.azulClaro],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AppColors.dorado.withValues(alpha: 0.25)),
        boxShadow: AppShadows.suave(Theme.of(context).brightness),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Imagen de funda iPhone con transparencia gradual (de menos a más transparencia)
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: movil ? 130 : 260,
            child: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                begin: Alignment.centerRight,
                end: Alignment.centerLeft,
                colors: [Colors.white, Colors.transparent],
                stops: [0.15, 0.95],
              ).createShader(bounds),
              blendMode: BlendMode.dstIn,
              child: Image.asset(
                'assets/hero_case.jpg',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg + 4),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.dorado.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: AppColors.dorado.withValues(alpha: 0.5)),
                        ),
                        child: const Text(
                          'Nueva colección',
                          style: TextStyle(
                            color: AppColors.doradoClaro,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Colección para iPhone',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Diseño, Protección, Estilo.',
                        style: TextStyle(color: Colors.white60, fontSize: 13),
                      ),
                      if (movil) ...[
                        const SizedBox(height: 12),
                        _botonVer(),
                      ],
                    ],
                  ),
                ),
                if (!movil) ...[
                  const SizedBox(width: AppSpacing.lg),
                  Padding(
                      padding: const EdgeInsets.only(right: 120),
                      child: _botonVer()),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _botonVer() => FilledButton.icon(
        onPressed: onVerColeccion,
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 44),
          textStyle: const TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontWeight: FontWeight.w700,
              fontSize: 13),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.pill)),
        ),
        label: const Text('Ver colección'),
        icon: const Icon(Icons.arrow_forward, size: 16),
        iconAlignment: IconAlignment.end,
      );
}

class _SeccionCategorias extends StatelessWidget {
  final List<Producto>? productos;
  const _SeccionCategorias({required this.productos});

  // Etiquetas propias del Inicio (Clásicas, Diseños) + el resto de las categorías del catálogo
  static const _etiquetasInicio = {
    'solido': 'Clásicas',
    'personalizada': 'Diseños'
  };

  @override
  Widget build(BuildContext context) {
    final conteo = <String, int>{};
    for (final p in productos ?? const <Producto>[]) {
      conteo[p.categoria] = (conteo[p.categoria] ?? 0) + 1;
    }
    // Se muestran las categorías con productos (mientras carga, todas)
    final cats = Categorias.todas
        .where((c) => productos == null || (conteo[c.id] ?? 0) > 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          titulo: 'Categorías',
          accion: 'Ver todas',
          onAccion: () => HomeScreen._irCatalogo(context),
        ),
        _Grilla(
          anchoMinimo: 130,
          espacio: AppSpacing.md,
          children: [
            for (final c in cats)
              IconTile(
                titulo: _etiquetasInicio[c.id] ?? c.etiqueta,
                icono: c.icono,
                color: c.color,
                onTap: () =>
                    HomeScreen._irCatalogo(context, {'categoria': c.id}),
              ),
            IconTile(
              titulo: 'Ver todo',
              icono: Icons.apps_rounded,
              color: AppColors.doradoOscuro,
              onTap: () => HomeScreen._irCatalogo(context),
            ),
          ],
        ),
      ],
    );
  }
}

class _SeccionModelos extends StatelessWidget {
  final List<Producto>? productos;
  const _SeccionModelos({required this.productos});

  @override
  Widget build(BuildContext context) {
    if (productos == null || productos!.isEmpty) return const SizedBox.shrink();
    final conteo = <String, int>{};
    for (final p in productos!) {
      for (final m in p.modelosCompatibles) {
        conteo[m] = (conteo[m] ?? 0) + 1;
      }
    }
    // Más nuevos primero (orden natural descendente: iPhone 18 > 17 > …)
    final modelos = conteo.keys.toList()..sort((a, b) => b.compareTo(a));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(
            titulo: 'Por modelo',
            subtitulo: 'Encontrá la funda exacta para tu iPhone'),
        _Grilla(
          anchoMinimo: 130,
          espacio: AppSpacing.md,
          children: [
            for (final m in modelos.take(12))
              IconTile(
                titulo: '$m (${conteo[m]})',
                icono: Icons.phone_iphone_rounded,
                color: AppColors.dorado,
                onTap: () => HomeScreen._irCatalogo(context, {'modelo': m}),
              ),
          ],
        ),
      ],
    );
  }
}

class _SeccionPopulares extends StatelessWidget {
  final List<Producto>? productos;
  const _SeccionPopulares({required this.productos});

  @override
  Widget build(BuildContext context) {
    final lista = productos;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          titulo: 'Más populares',
          accion: 'Ver todas',
          onAccion: () => HomeScreen._irCatalogo(context),
        ),
        if (lista == null)
          const SkeletonGrid(cantidad: 4, anchoMaximoItem: 260, proporcion: 0.7)
        else if (lista.isEmpty)
          const EmptyState(
              icono: Icons.inventory_2_outlined,
              titulo: 'Próximamente los productos')
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: Breakpoints.esMovil(context) ? 230 : 260,
              mainAxisSpacing: AppSpacing.lg,
              crossAxisSpacing: AppSpacing.lg,
              childAspectRatio: 0.70,
            ),
            itemCount: math.min(8, lista.length),
            itemBuilder: (context, i) {
              final p = lista[i];
              return ProductoCard(
                producto: p,
                onTap: () => mostrarModalProductoDetalle(context, p),
              );
            },
          ),
      ],
    );
  }
}
