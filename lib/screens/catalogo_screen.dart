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

  final List<String> _categorias = ['todas', 'solido', 'transparente', 'personalizada'];
  final List<String> _modelos = [
    'todos', 'iPhone 13', 'iPhone 13 Pro', 'iPhone 14', 'iPhone 14 Pro',
    'iPhone 15', 'iPhone 15 Pro', 'iPhone 16', 'iPhone 16 Pro',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ROYAL'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FaqScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.shopping_bag_outlined),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CarritoScreen())),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFiltros(),
          Expanded(child: _buildGrid()),
        ],
      ),
    );
  }

  Widget _buildFiltros() {
    return Column(
      children: [
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            children: _categorias.map((c) {
              final selected = c == _categoriaSeleccionada;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(_labelCategoria(c)),
                  selected: selected,
                  selectedColor: AppColors.dorado,
                  labelStyle: TextStyle(color: selected ? AppColors.azul : AppColors.textoSecundario, fontWeight: FontWeight.w600),
                  onSelected: (_) => setState(() => _categoriaSeleccionada = c),
                ),
              );
            }).toList(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: DropdownButtonFormField<String>(
            value: _modeloSeleccionado,
            decoration: const InputDecoration(labelText: 'Modelo de iPhone', isDense: true),
            items: _modelos.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
            onChanged: (v) => setState(() => _modeloSeleccionado = v ?? 'todos'),
          ),
        ),
      ],
    );
  }

  String _labelCategoria(String c) {
    switch (c) {
      case 'solido': return 'Color sólido';
      case 'transparente': return 'Transparente';
      case 'personalizada': return 'Personalizada';
      default: return 'Todas';
    }
  }

  Widget _buildGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('productos').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('No se pudieron cargar los productos.'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final productos = snapshot.data!.docs
            .map((d) => Producto.fromMap(d.id, d.data() as Map<String, dynamic>))
            .where((p) => _categoriaSeleccionada == 'todas' || p.categoria == _categoriaSeleccionada)
            .where((p) => _modeloSeleccionado == 'todos' || p.modelosCompatibles.contains(_modeloSeleccionado))
            .toList();

        if (productos.isEmpty) {
          return const Center(child: Text('No hay fundas para este filtro.'));
        }

        return GridView.builder(
          padding: const EdgeInsets.all(12),
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
                MaterialPageRoute(builder: (_) => ProductoDetalleScreen(producto: p)),
              ),
            );
          },
        );
      },
    );
  }
}
