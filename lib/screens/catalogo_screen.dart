import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../models/producto.dart';
import '../providers/carrito_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/producto_card.dart';
import '../widgets/royal_logo.dart';
import '../widgets/app_product_image.dart';
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

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _nombreColorLegible(String hex) {
    final h = hex.toUpperCase().trim();
    if (_nombresColores.containsKey(h)) {
      return _nombresColores[h]!;
    }
    return h;
  }

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

  /// Popup / Modal centrado en Modo Usuario con cierre automático al agregar al carrito
  void _mostrarModalDetalle(Producto p) {
    final tieneDescuento = p.enDescuento && p.porcentajeDescuento > 0;
    final swatchColor = _parseHex(p.colorHex);
    final agotado = p.stock <= 0;

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.70), // Fondo translúcido
      builder: (dialogCtx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Barra superior con botón de cerrar
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.fondo,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        p.codigoColor.isNotEmpty
                            ? '${p.categoria.toUpperCase()} • ${p.codigoColor.toUpperCase()}'
                            : p.categoria.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: AppColors.textoSecundario,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: 'Cerrar',
                      onPressed: () => Navigator.pop(dialogCtx),
                    ),
                  ],
                ),
              ),

              // Imagen ampliada con AppProductImage
              Container(
                height: 250,
                color: const Color(0xFFF9FAFB),
                padding: const EdgeInsets.all(16),
                child: AppProductImage(
                  imageUrl: p.fotoPrincipalUrl,
                  fit: BoxFit.contain,
                ),
              ),

              // Información del producto
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nombre con formato estricto: "Funda iPhone X"
                    Text(
                      p.nombre,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textoPrincipal,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Precios
                    Row(
                      children: [
                        Text(
                          p.precioFinalFormateado,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: tieneDescuento ? AppColors.rojoDescuento : AppColors.azul,
                          ),
                        ),
                        if (tieneDescuento) ...[
                          const SizedBox(width: 8),
                          Text(
                            p.precioOriginalFormateado,
                            style: const TextStyle(
                              fontSize: 14,
                              decoration: TextDecoration.lineThrough,
                              color: AppColors.textoAtenuado,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.rojoDescuento,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '-${p.porcentajeDescuento}% OFF',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Color y Stock
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: swatchColor,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.black26),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Color: ${_nombreColorLegible(p.colorHex)}',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: agotado
                                ? Colors.red.withValues(alpha: 0.12)
                                : AppColors.verdeStock.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            agotado ? 'Agotado' : 'Stock: ${p.stock} un.',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: agotado ? Colors.red : AppColors.verdeStock,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // REQUERIMIENTO 1: CIERRE AUTOMÁTICO DEL POPUP AL AGREGAR AL CARRITO
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.add_shopping_cart),
                        label: Text(agotado ? 'Producto agotado' : 'Agregar al carrito'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: agotado ? Colors.grey : AppColors.dorado,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: agotado
                            ? null
                            : () {
                                final carrito = context.read<CarritoProvider>();
                                final agregado = carrito.agregar(p);
                                // CERRAR AUTOMÁTICAMENTE EL POPUP DE FORMA INMEDIATA:
                                Navigator.pop(dialogCtx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      agregado
                                          ? '${p.nombre} agregado al carrito'
                                          : 'Stock agotado o límite alcanzado para ${p.nombre}',
                                    ),
                                    backgroundColor: agregado ? AppColors.azul : Colors.orange,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              },
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Botón para ver detalle completo
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        icon: const Icon(Icons.info_outline, size: 16),
                        label: const Text('Ver opciones y modelos compatibles'),
                        onPressed: () {
                          Navigator.pop(dialogCtx);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProductoDetalleScreen(producto: p),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
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
                            onTap: () => _mostrarModalDetalle(p),
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

  Widget _buildFiltros(Map<String, int> conteoColores) {
    return Container(
      color: AppColors.azul,
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Buscador integrado por modelo, color y código de producto
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _busqueda = v.trim().toLowerCase()),
              style: const TextStyle(fontSize: 13, color: AppColors.textoPrincipal),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                isDense: true,
                hintText: 'Buscar por modelo, color o código (ej. iPhone 15, rojo, 001)...',
                prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textoAtenuado),
                suffixIcon: _busqueda.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _busqueda = '');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Selector de categorías
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
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
                      fontSize: 12,
                      fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                    ),
                    onSelected: (_) => setState(() => _categoriaSeleccionada = c),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),

          // Selector de modelo
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _modeloSeleccionado,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.dorado),
                  items: _modelos
                      .map((m) => DropdownMenuItem(
                            value: m,
                            child: Text(m == 'todos' ? 'Todos los modelos de iPhone' : m),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _modeloSeleccionado = v ?? 'todos'),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // REQUERIMIENTO 5: FILTRADO MULTICOLOR DINÁMICO (paleta ampliada con selección múltiple)
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 4),
            child: Row(
              children: [
                const Text(
                  'COLORES DISPONIBLES (SELECCIÓN MÚLTIPLE):',
                  style: TextStyle(
                    color: AppColors.doradoClaro,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                if (_coloresSeleccionados.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => setState(() => _coloresSeleccionados.clear()),
                    child: const Text(
                      'Limpiar filtros',
                      style: TextStyle(color: Colors.white70, fontSize: 10, decoration: TextDecoration.underline),
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(
            height: 32,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: conteoColores.entries.map((entry) {
                final hex = entry.key;
                final count = entry.value;
                final isSelected = _coloresSeleccionados.contains(hex);
                final colorVisual = _parseHex(hex);

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: isSelected,
                    showCheckmark: false,
                    color: WidgetStateProperty.resolveWith<Color?>((states) {
                      if (states.contains(WidgetState.selected)) {
                        return AppColors.dorado;
                      }
                      return const Color(0xFF13315C);
                    }),
                    side: BorderSide(
                      color: isSelected ? AppColors.dorado : Colors.white.withValues(alpha: 0.25),
                      width: 1,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    avatar: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: colorVisual,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: hex == '#FFFFFF' || hex == '#E5E7EB' ? Colors.black38 : Colors.white60,
                          width: 0.8,
                        ),
                      ),
                    ),
                    label: Text(
                      '${_nombreColorLegible(hex)} ($count)',
                      style: TextStyle(
                        fontSize: 11,
                        color: isSelected ? AppColors.azul : Colors.white,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      ),
                    ),
                    onSelected: (val) {
                      setState(() {
                        if (val) {
                          _coloresSeleccionados.add(hex);
                        } else {
                          _coloresSeleccionados.remove(hex);
                        }
                      });
                    },
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