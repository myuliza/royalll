import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../models/producto.dart';
import '../theme/app_theme.dart';
import '../widgets/producto_card.dart';

/// Sección Inicio. La navegación entre secciones la maneja el router (AppShell).
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void onNavigate(BuildContext context, int _) => context.go('/catalogo');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondo,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _HeroBanner(onNavigate: (i) => onNavigate(context, i)),
                    _SeccionCategorias(onNavigate: (i) => onNavigate(context, i)),
                    _SeccionPopulares(onNavigate: (i) => onNavigate(context, i)),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  final void Function(int) onNavigate;

  const _HeroBanner({required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      constraints: const BoxConstraints(minHeight: 190),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [AppColors.azul, AppColors.azulClaro],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.azul.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // Imagen de funda iPhone con transparencia gradual (de menos a más transparencia)
          Positioned(
            right: -10,
            top: -10,
            bottom: -10,
            width: 220,
            child: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                begin: Alignment.centerRight,
                end: Alignment.centerLeft,
                colors: [Colors.white, Colors.transparent],
                stops: [0.15, 0.85],
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
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.dorado.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.dorado.withValues(alpha: 0.5)),
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
                const SizedBox(height: 10),
                const Text(
                  'Colección para\niPhone',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Diseño, Protección, Estilo.',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => onNavigate(1),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    foregroundColor: Theme.of(context).colorScheme.onSecondary,
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  label: const Text('Ver colección'),
                  icon: const Icon(Icons.arrow_forward, size: 14),
                  iconAlignment: IconAlignment.end,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SeccionCategorias extends StatelessWidget {
  final void Function(int) onNavigate;

  const _SeccionCategorias({required this.onNavigate});

  static const List<_CatItem> _cats = [
    _CatItem('Clásicas', Icons.phone_iphone_outlined, 'solido'),
    _CatItem('Diseños', Icons.palette_outlined, 'personalizada'),
    _CatItem('Transparente', Icons.blur_on_outlined, 'transparente'),
    _CatItem('Ver todo', Icons.apps_outlined, 'todas'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Categorías',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textoPrincipal,
                ),
              ),
              TextButton(
                onPressed: () => onNavigate(1),
                style: TextButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  foregroundColor: Theme.of(context).colorScheme.primary,
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text('Ver todas →'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: _cats
                .map((c) => _CatChip(item: c, onNavigate: onNavigate))
                .toList(),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _CatItem {
  final String label;
  final IconData icon;
  final String filtro;
  const _CatItem(this.label, this.icon, this.filtro);
}

class _CatChip extends StatelessWidget {
  final _CatItem item;
  final void Function(int) onNavigate;

  const _CatChip({required this.item, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;

    return Material(
      color: colores.surface,
      elevation: 2,
      shadowColor: colores.primary.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => onNavigate(1),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 80, minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 64,
                  height: 48,
                  child: Icon(item.icon, color: colores.primary, size: 28),
                ),
                const SizedBox(height: 8),
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: colores.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SeccionPopulares extends StatelessWidget {
  final void Function(int) onNavigate;

  const _SeccionPopulares({required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Más populares',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textoPrincipal,
                ),
              ),
              TextButton(
                onPressed: () => onNavigate(1),
                style: TextButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  foregroundColor: Theme.of(context).colorScheme.primary,
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text('Ver todas →'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('productos')
                .limit(4)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline,
                            color: Colors.redAccent, size: 32),
                        SizedBox(height: 8),
                        Text(
                          'No se pudieron cargar los productos',
                          style: TextStyle(
                              color: AppColors.textoSecundario, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (!snapshot.hasData) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: CircularProgressIndicator(color: AppColors.dorado),
                  ),
                );
              }

              final productos = snapshot.data!.docs
                  .map((d) =>
                      Producto.fromMap(d.id, d.data() as Map<String, dynamic>))
                  .toList();

              if (productos.isEmpty) {
                return Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inventory_2_outlined,
                            color: AppColors.dorado, size: 32),
                        SizedBox(height: 8),
                        Text(
                          'Próximamente los productos',
                          style: TextStyle(
                              color: AppColors.textoSecundario, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 900;
                  final isMedium = constraints.maxWidth > 600;
                  final crossAxisCount = isWide ? 4 : (isMedium ? 3 : 2);
                  final childAspectRatio = isWide ? 0.75 : 0.68;

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: childAspectRatio,
                    ),
                    itemCount: productos.length,
                    itemBuilder: (context, i) {
                      final p = productos[i];
                      return ProductoCard(
                        producto: p,
                        onTap: () => mostrarModalProductoDetalle(context, p),
                      );
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}