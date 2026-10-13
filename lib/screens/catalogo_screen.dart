import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/producto.dart';
import '../theme/app_theme.dart';
import '../widgets/producto_card.dart';
import '../widgets/royal_logo.dart';
import 'producto_detalle_screen.dart';
import 'carrito_screen.dart';
import 'faq_screen.dart';

class CatalogoScreen extends StatefulWidget {
  const CatalogoScreen({super.key});

  // Paleta completa y estandarizada de colores principales
  static const Map<String, String> _nombresColores = {
    '#000000': 'Negro',
    '#FFFFFF': 'Blanco',
    '#E5E7EB': 'Blanco/Transparente',
    '#0B2545': 'Azul',
    '#13315C': 'Azul Marino',
    '#DC2626': 'Rojo',
    '#16A34A': 'Verde',
    '#F472B6': 'Rosa',
    '#7E22CE': 'Morado',
    '#C9A227': 'Dorado/Beige',
    '#64748B': 'Gris/Titanio',
    '#78350F': 'Marrón',
  };

  static String nombreColorLegible(String hex) {
    final h = hex.toUpperCase().trim();
    return _nombresColores[h] ?? h;
  }

  @override
  State<CatalogoScreen> createState() => _CatalogoScreenState();
}

class _CatalogoScreenState extends State<CatalogoScreen> {
  String _categoriaSeleccionada = 'todas';
  String _modeloSeleccionado = 'todos';
  String _busqueda = '';
  final Set<String> _coloresSeleccionados = {}; // Filtrado multicolor simultáneo
  final TextEditingController _searchCtrl = TextEditingController();

  final List<String> _categorias = [
    'todas',
    'solido',
    'transparente',
    'personalizada',
  ];

  final List<String> _modelos = [
    'todos',
    'iPhone 12',
    'iPhone 12 Pro',
    'iPhone 13',
    'iPhone 13 Pro',
    'iPhone 13 Pro Max',
    'iPhone 14',
    'iPhone 14 Pro',
    'iPhone 14 Pro Max',
    'iPhone 15',
    'iPhone 15 Pro',
    'iPhone 15 Pro Max',
    'iPhone 16',
    'iPhone 16 Pro',
    'iPhone 16 Pro Max',
  ];


  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _nombreColorLegible(String hex) => CatalogoScreen.nombreColorLegible(hex);

  Color _parseHex(String hex) {
    try {
      final buffer = StringBuffer();
      if (hex.length == 6 || hex.length == 7) buffer.write('ff');
      buffer.write(hex.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return Colors.grey;
    }
  }

  void _abrirDetalle(Producto p) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProductoDetalleScreen(producto: p)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondo,
      appBar: _buildAppBar(context),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('productos').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error al sincronizar catálogo'));
          }
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.dorado),
            );
          }

          final allProductos = snapshot.data!.docs
              .map((d) => Producto.fromMap(d.id, d.data() as Map<String, dynamic>))
              .toList();

          // 1. Extracción dinámica de colores desde los documentos de Firebase
          final Map<String, int> conteoColores = {};
          for (final p in allProductos) {
            final hex = p.colorHex.toUpperCase().trim();
            if (hex.isNotEmpty) {
              conteoColores[hex] = (conteoColores[hex] ?? 0) + 1;
            }
          }

          // 2. Buscador y filtro integrado (modelo, color, código y categoría)
          final productosFiltrados = allProductos.where((p) {
            if (_categoriaSeleccionada != 'todas' && p.categoria != _categoriaSeleccionada) {
              return false;
            }
            if (_modeloSeleccionado != 'todos' && !p.modelosCompatibles.contains(_modeloSeleccionado)) {
              return false;
            }
            // FILTRADO MULTICOLOR: permite seleccionar múltiples colores simultáneos
            if (_coloresSeleccionados.isNotEmpty && !_coloresSeleccionados.contains(p.colorHex.toUpperCase().trim())) {
              return false;
            }
            // Búsqueda por texto integrada: modelo, color legible, código de modelo/color
            if (_busqueda.isNotEmpty) {
              final q = _busqueda;
              final matchNombre = p.nombre.toLowerCase().contains(q);
              final matchCodigo = p.codigoColor.toLowerCase().contains(q);
              final matchColorHex = p.colorHex.toLowerCase().contains(q);
              final colorNom = _nombreColorLegible(p.colorHex).toLowerCase();
              final matchColorNom = colorNom.contains(q);
              final matchModelos = p.modelosCompatibles.any((m) => m.toLowerCase().contains(q));
              final matchCategoria = p.categoria.toLowerCase().contains(q);

              // Búsqueda inteligente por familias de colores
              bool matchFamiliaColor = false;
              if (q == 'titanio' || q == 'gris') {
                matchFamiliaColor = p.colorHex.toUpperCase() == '#64748B';
              } else if (q == 'dorado' || q == 'beige' || q == 'oro') {
                matchFamiliaColor = p.colorHex.toUpperCase() == '#C9A227';
              } else if (q == 'morado' || q == 'purpura' || q == 'púrpura') {
                matchFamiliaColor = p.colorHex.toUpperCase() == '#7E22CE';
              } else if (q == 'verde') {
                matchFamiliaColor = p.colorHex.toUpperCase() == '#16A34A';
              } else if (q == 'rosa' || q == 'pink') {
                matchFamiliaColor = p.colorHex.toUpperCase() == '#F472B6';
              } else if (q == 'azul') {
                matchFamiliaColor = p.colorHex.toUpperCase() == '#0B2545' || p.colorHex.toUpperCase() == '#13315C';
              } else if (q == 'rojo') {
                matchFamiliaColor = p.colorHex.toUpperCase() == '#DC2626';
              } else if (q == 'blanco' || q == 'transparente') {
                matchFamiliaColor = p.colorHex.toUpperCase() == '#FFFFFF' || p.colorHex.toUpperCase() == '#E5E7EB';
              } else if (q == 'negro') {
                matchFamiliaColor = p.colorHex.toUpperCase() == '#000000';
              }

              if (!matchNombre && !matchCodigo && !matchColorHex && !matchColorNom && !matchModelos && !matchCategoria && !matchFamiliaColor) {
                return false;
              }
            }
            return true;
          }).toList();

          return Column(
            children: [
              _buildFiltros(conteoColores),
              Expanded(
                child: productosFiltrados.isEmpty
                    ? const Center(
                        child: Text(
                          'No hay fundas disponibles para estos filtros.',
                          style: TextStyle(color: AppColors.textoSecundario),
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          childAspectRatio: 0.68,
                        ),
                        itemCount: productosFiltrados.length,
                        itemBuilder: (context, i) {
                          final p = productosFiltrados[i];
                          return ProductoCard(
                            producto: p,
                            onTap: () => _abrirDetalle(p),
                          );
                        },
                      ),
              ),
            ],
          );
        },
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
      title: const RoyalLogo(size: 26, isLight: true),
      actions: [
        IconButton(
          icon: const Icon(Icons.help_outline),
          tooltip: 'Preguntas frecuentes',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const FaqScreen()),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.shopping_bag_outlined),
          tooltip: 'Carrito',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CarritoScreen()),
          ),
        ),
        const SizedBox(width: 6),
      ],
    );
  }

  int get _filtrosAvanzadosActivos =>
      (_modeloSeleccionado != 'todos' ? 1 : 0) + _coloresSeleccionados.length;

  /// Filtros de modelo y color en una bottom sheet para liberar espacio al catálogo
  void _mostrarFiltrosAvanzados(Map<String, int> conteoColores) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx, setSheetState) {
          void actualizar(VoidCallback cambio) {
            setState(cambio);
            setSheetState(() {});
          }

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text('Filtros', style: Theme.of(sheetCtx).textTheme.titleLarge),
                      ),
                      if (_filtrosAvanzadosActivos > 0)
                        TextButton(
                          onPressed: () => actualizar(() {
                            _modeloSeleccionado = 'todos';
                            _coloresSeleccionados.clear();
                          }),
                          child: const Text('Limpiar filtros'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    key: ValueKey(_modeloSeleccionado),
                    initialValue: _modeloSeleccionado,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Modelo de iPhone',
                      border: OutlineInputBorder(),
                    ),
                    items: _modelos
                        .map((m) => DropdownMenuItem(
                              value: m,
                              child: Text(m == 'todos' ? 'Todos los modelos de iPhone' : m),
                            ))
                        .toList(),
                    onChanged: (v) => actualizar(() => _modeloSeleccionado = v ?? 'todos'),
                  ),
                  const SizedBox(height: 20),
                  Text('Colores', style: Theme.of(sheetCtx).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  // FILTRADO MULTICOLOR DINÁMICO (paleta ampliada con selección múltiple)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: conteoColores.entries.map((entry) {
                      final hex = entry.key;
                      final isSelected = _coloresSeleccionados.contains(hex);
                      return FilterChip(
                        selected: isSelected,
                        avatar: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: _parseHex(hex),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.black26, width: 0.8),
                          ),
                        ),
                        label: Text('${_nombreColorLegible(hex)} (${entry.value})'),
                        onSelected: (val) => actualizar(() {
                          if (val) {
                            _coloresSeleccionados.add(hex);
                          } else {
                            _coloresSeleccionados.remove(hex);
                          }
                        }),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () => Navigator.pop(sheetCtx),
                    child: const Text('Ver resultados'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFiltros(Map<String, int> conteoColores) {
    final activos = _filtrosAvanzadosActivos;
    return Container(
      color: AppColors.azul,
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Buscador integrado por modelo, color y código + acceso a filtros
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _busqueda = v.trim().toLowerCase()),
                    textInputAction: TextInputAction.search,
                    style: const TextStyle(color: AppColors.textoPrincipal),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      hintText: 'Buscar modelo, color o código',
                      prefixIcon: const Icon(Icons.search, color: AppColors.textoAtenuado),
                      suffixIcon: _busqueda.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              tooltip: 'Borrar búsqueda',
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _busqueda = '');
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(28),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Filtros',
                  color: Colors.white,
                  onPressed: () => _mostrarFiltrosAvanzados(conteoColores),
                  icon: Badge(
                    isLabelVisible: activos > 0,
                    label: Text('$activos'),
                    backgroundColor: AppColors.dorado,
                    textColor: AppColors.azul,
                    child: const Icon(Icons.tune),
                  ),
                ),
              ],
            ),
          ),

          // Selector de categorías
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: _categorias.map((c) {
                final selected = c == _categoriaSeleccionada;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(
                      c == 'solido'
                          ? 'Sólido'
                          : c == 'transparente'
                              ? 'Transparente'
                              : c == 'personalizada'
                                  ? 'Personalizada'
                                  : 'Todas',
                    ),
                    selected: selected,
                    showCheckmark: false,
                    color: WidgetStateProperty.resolveWith<Color?>((states) {
                      if (states.contains(WidgetState.selected)) {
                        return AppColors.dorado;
                      }
                      return const Color(0xFF13315C);
                    }),
                    side: BorderSide(
                      color: selected ? AppColors.dorado : Colors.white.withValues(alpha: 0.25),
                      width: 1,
                    ),
                    labelStyle: TextStyle(
                      color: selected ? AppColors.azul : Colors.white,
                      fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                    ),
                    onSelected: (_) => setState(() => _categoriaSeleccionada = c),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
