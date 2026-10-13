import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/producto.dart';
import '../theme/app_theme.dart';
import '../widgets/producto_card.dart';
import 'catalogo_screen.dart';
import 'carrito_screen.dart';
import 'faq_screen.dart';
import 'producto_detalle_screen.dart';
import 'empleado_login_screen.dart';
import '../widgets/royal_logo.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tabIndex = 0;

  void _goToTab(int index) {
    setState(() => _tabIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      _HomeTab(onNavigate: _goToTab),
      const CatalogoScreen(),
      const CarritoScreen(),
      const FaqScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _tabIndex,
        children: tabs,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: _goToTab,
        backgroundColor: Colors.white,
        indicatorColor: AppColors.dorado.withValues(alpha: 0.18),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: AppColors.dorado),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view, color: AppColors.dorado),
            label: 'Catálogo',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_bag_outlined),
            selectedIcon: Icon(Icons.shopping_bag, color: AppColors.dorado),
            label: 'Carrito',
          ),
          NavigationDestination(
            icon: Icon(Icons.help_outline),
            selectedIcon: Icon(Icons.help, color: AppColors.dorado),
            label: 'FAQ',
          ),
        ],
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  final void Function(int) onNavigate;

  const _HomeTab({required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondo,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverToBoxAdapter(child: _HeroBanner(onNavigate: onNavigate)),
          SliverToBoxAdapter(child: _SeccionCategorias(onNavigate: onNavigate)),
          SliverToBoxAdapter(child: _SeccionPopulares(onNavigate: onNavigate)),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context) {
    return SliverAppBar(
      backgroundColor: AppColors.azul,
      foregroundColor: Colors.white,
      floating: true,
      snap: true,
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.lock_outline, size: 20),
          tooltip: 'Acceso empleado',
onPressed: () => Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => const EmpleadoLoginScreen()),
),
        ),
      ],
      title: const RoyalLogo(size: 28, isLight: true),
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
        children: [
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.dorado.withValues(alpha: 0.12),
              ),
            ),
          ),
          Positioned(
            right: 10,
            bottom: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.dorado.withValues(alpha: 0.08),
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

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.68,
                ),
                itemCount: productos.length,
                itemBuilder: (context, i) {
                  final p = productos[i];
                  return ProductoCard(
                    producto: p,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => ProductoDetalleScreen(producto: p)),
                    ),
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