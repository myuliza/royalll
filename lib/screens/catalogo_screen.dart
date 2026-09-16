import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/producto.dart';
import '../theme/app_theme.dart';
import '../widgets/producto_card.dart';
import 'producto_detalle_screen.dart';
import 'carrito_screen.dart';
import 'faq_screen.dart';

class CatalogoScreen extends StatefulWidget {
  const CatalogoScreen({super.key});

  @override
  State<CatalogoScreen> createState() => _CatalogoScreenState();
}

class _CatalogoScreenState extends State<CatalogoScreen> {
  String _categoriaSeleccionada = 'todas';
  String _modeloSeleccionado = 'todos';

  final List<String> _categorias = [
    'todas',
    'solido',
    'transparente',
    'personalizada',
  ];
  final List<String> _modelos = [
    'todos', 'iPhone 13', 'iPhone 13 Pro', 'iPhone 14', 'iPhone 14 Pro',
    'iPhone 15', 'iPhone 15 Pro', 'iPhone 16', 'iPhone 16 Pro',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondo,
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          _buildFiltros(),
          Expanded(child: _buildGrid()),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.azul,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: AppColors.dorado,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Center(
              child: Text(
                'R',
                style: TextStyle(
                  color: AppColors.azul,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'ROYAL',
            style: TextStyle(
              letterSpacing: 3,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ],
      ),
      actions: [
        _AppBarIconButton(
          icon: Icons.help_outline,
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const FaqScreen()),
          ),
        ),
        _AppBarIconButton(
          icon: Icons.shopping_bag_outlined,
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CarritoScreen()),
          ),
        ),
        const SizedBox(width: 6),
      ],
    );
  }

  Widget _buildFiltros() {
    return Container(
      color: AppColors.azul,
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: _categorias.map((c) {
                final selected = c == _categoriaSeleccionada;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: _FiltroChip(
                    label: _labelCategoria(c),
                    selected: selected,
                    onTap: () => setState(() => _categoriaSeleccionada = c),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _ModeloDropdown(
              value: _modeloSeleccionado,
              opciones: _modelos,
              onChanged: (v) =>
                  setState(() => _modeloSeleccionado = v ?? 'todos'),
            ),
          ),
        ],
      ),
    );
  }

  String _labelCategoria(String c) {
    switch (c) {
      case 'solido':
        return 'Color sólido';
      case 'transparente':
        return 'Transparente';
      case 'personalizada':
        return 'Personalizada';
      default:
        return 'Todas';
    }
  }

  Widget _buildGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('productos').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _EstadoVacio(
            icon: Icons.error_outline,
            iconColor: Colors.redAccent,
            mensaje: 'No se pudieron cargar los productos.',
          );
        }
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.dorado),
          );
        }

        final productos = snapshot.data!.docs
            .map((d) => Producto.fromMap(d.id, d.data() as Map<String, dynamic>))
            .where((p) =>
                _categoriaSeleccionada == 'todas' ||
                p.categoria == _categoriaSeleccionada)
            .where((p) =>
                _modeloSeleccionado == 'todos' ||
                p.modelosCompatibles.contains(_modeloSeleccionado))
            .toList();

        if (productos.isEmpty) {
          return _EstadoVacio(
            icon: Icons.search_off,
            iconColor: AppColors.dorado,
            mensaje: 'No hay fundas para este filtro.',
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 0.68,
          ),
          itemCount: productos.length,
          itemBuilder: (context, i) {
            final p = productos[i];
            return ProductoCard(
              producto: p,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ProductoDetalleScreen(producto: p)),
              ),
            );
          },
        );
      },
    );
  }
}

/// Botón de ícono circular translúcido para la AppBar, consistente con
/// el estilo del resto de la app.
class _AppBarIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _AppBarIconButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: Colors.white.withOpacity(0.12),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, size: 20, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

/// Chip de filtro con estilo propio: fondo dorado + sombra cuando está
/// seleccionado, pastilla translúcida blanca cuando no.
class _FiltroChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FiltroChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.dorado : Colors.white.withOpacity(0.10),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected
                ? AppColors.dorado
                : Colors.white.withOpacity(0.35),
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.dorado.withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.azul : Colors.white,
          ),
        ),
      ),
    );
  }
}

/// Selector de modelo presentado como tarjeta blanca elevada, en vez del
/// campo de formulario por defecto de [DropdownButtonFormField].
class _ModeloDropdown extends StatelessWidget {
  final String value;
  final List<String> opciones;
  final ValueChanged<String?> onChanged;

  const _ModeloDropdown({
    required this.value,
    required this.opciones,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: AppColors.dorado),
          decoration: const InputDecoration(
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.symmetric(vertical: 12),
          ),
          style: const TextStyle(
            color: AppColors.textoPrincipal,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          items: opciones
              .map((m) => DropdownMenuItem(
                    value: m,
                    child: Row(
                      children: [
                        const Icon(Icons.phone_iphone_outlined,
                            size: 16, color: AppColors.dorado),
                        const SizedBox(width: 8),
                        Text(m == 'todos' ? 'Todos los modelos' : m),
                      ],
                    ),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

/// Estado vacío/error con ícono + mensaje, en línea con el resto de la app.
class _EstadoVacio extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String mensaje;

  const _EstadoVacio({
    required this.icon,
    required this.iconColor,
    required this.mensaje,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: 40),
            const SizedBox(height: 12),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textoSecundario,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}