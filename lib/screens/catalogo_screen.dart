import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../models/producto.dart';
import '../providers/busqueda_catalogo.dart';
import '../providers/carrito_provider.dart';
import '../theme/breakpoints.dart';
import '../theme/app_theme.dart';
import '../widgets/producto_card.dart';
import '../widgets/app_product_image.dart';
import 'producto_detalle_screen.dart';

class CatalogoScreen extends StatefulWidget {
  /// Filtros iniciales que llegan por URL (ej. /catalogo?categoria=transparente).
  final String? categoria;
  final String? modelo;
  final String? especial;

  const CatalogoScreen({super.key, this.categoria, this.modelo, this.especial});

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
  final Set<String> _coloresSeleccionados = {}; // Filtrado multicolor simultáneo

  final List<String> _categorias = [
    'todas',
    'solido',
    'silicona',
    'transparente',
    'cuero',
    'dualtek',
    'magsafe',
  ];

  final List<String> _modelos = [
    'todos',
    'iPhone 11',
    'iPhone 11 Pro',
    'iPhone 11 Pro Max',
    'iPhone 13',
    'iPhone 13 Pro',
    'iPhone 14',
    'iPhone 14 Plus',
    'iPhone 15',
    'iPhone 15 Plus',
    'iPhone 15 Pro Max',
    'iPhone 16',
    'iPhone 16 Pro Max',
    'iPhone 17',
    'iPhone 17 Pro',
    'iPhone 17 Pro Max',
    'iPhone 18 Pro Max',
  ];

  @override
  void initState() {
    super.initState();
    _aplicarFiltrosDeUrl();
  }

  @override
  void didUpdateWidget(covariant CatalogoScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.categoria != widget.categoria ||
        oldWidget.modelo != widget.modelo ||
        oldWidget.especial != widget.especial) {
      _aplicarFiltrosDeUrl();
    }
  }

  void _aplicarFiltrosDeUrl() {
    _categoriaSeleccionada = widget.categoria ?? 'todas';
    _modeloSeleccionado = widget.modelo ?? 'todos';
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

  /// Popup / Modal centrado en Modo Usuario con cierre automático al agregar al carrito
  void _mostrarModalDetalle(Producto p) {
    final tieneDescuento = p.enDescuento && p.porcentajeDescuento > 0;
    final swatchColor = _parseHex(p.colorHex);
    final agotado = p.stock <= 0;

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.60),
      builder: (dialogCtx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 48, vertical: 48),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Barra superior con botón de cerrar
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 8, 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.fondo,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        p.colorLegible.isNotEmpty
                            ? '${p.categoria.toUpperCase()} • ${p.colorLegible}'
                            : p.categoria.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                          color: AppColors.textoSecundario,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      tooltip: 'Cerrar',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => Navigator.pop(dialogCtx),
                    ),
                  ],
                ),
              ),

              // Imagen compacta
              Container(
                height: 160,
                color: const Color(0xFFF9FAFB),
                padding: const EdgeInsets.all(10),
                child: AppProductImage(
                  imageUrl: p.fotoPrincipalUrl,
                  fit: BoxFit.contain,
                ),
              ),

              // Información del producto
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.nombre,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textoPrincipal,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Precios
                    Row(
                      children: [
                        Text(
                          p.precioFinalFormateado,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: tieneDescuento ? AppColors.rojoDescuento : AppColors.azul,
                          ),
                        ),
                        if (tieneDescuento) ...[
                          const SizedBox(width: 6),
                          Text(
                            p.precioOriginalFormateado,
                            style: const TextStyle(
                              fontSize: 12,
                              decoration: TextDecoration.lineThrough,
                              color: AppColors.textoAtenuado,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.rojoDescuento,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              '-${p.porcentajeDescuento}% OFF',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Color y Stock
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: swatchColor,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.black26),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _nombreColorLegible(p.colorHex),
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: agotado
                                ? Colors.red.withValues(alpha: 0.12)
                                : AppColors.verdeStock.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            agotado ? 'Agotado' : 'Stock: ${p.stock}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: agotado ? Colors.red : AppColors.verdeStock,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.add_shopping_cart, size: 16),
                        label: Text(agotado ? 'Agotado' : 'Agregar al carrito'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: agotado ? Colors.grey : AppColors.dorado,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: agotado
                            ? null
                            : () {
                                final carrito = context.read<CarritoProvider>();
                                final agregado = carrito.agregar(p);
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
                    const SizedBox(height: 4),

                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        icon: const Icon(Icons.info_outline, size: 14),
                        label: const Text('Ver detalle completo', style: TextStyle(fontSize: 12)),
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
    // Buscador global (barra superior en escritorio/tablet, campo propio en móvil)
    final busquedaGlobal = context.watch<BusquedaCatalogo>();
    final consulta = busquedaGlobal.consulta;

    return Scaffold(
      backgroundColor: AppColors.fondo,
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
            if (consulta.isNotEmpty) {
              final q = consulta;
              final matchNombre = p.nombre.toLowerCase().contains(q);
              final matchCodigo = p.codigoColor.toLowerCase().contains(q);
              final matchColorHex = p.colorHex.toLowerCase().contains(q);
              final colorNom = _nombreColorLegible(p.colorHex).toLowerCase();
              final matchColorNom = colorNom.contains(q);
              final matchModelos = p.modelosCompatibles.any((m) => m.toLowerCase().contains(q));
              final matchCategoria = p.categoria.toLowerCase().contains(q);

              // Búsqueda inteligente por familias de colores y estilos
              bool matchFamiliaColor = false;
              if (q == 'titanio' || q == 'gris') {
                matchFamiliaColor = p.colorHex.toUpperCase() == '#64748B';
              } else if (q == 'dorado' || q == 'beige' || q == 'oro' || q == 'floral' || q == 'flores') {
                matchFamiliaColor = p.colorHex.toUpperCase() == '#C9A227';
              } else if (q == 'morado' || q == 'purpura' || q == 'púrpura') {
                matchFamiliaColor = p.colorHex.toUpperCase() == '#7E22CE';
              } else if (q == 'verde') {
                matchFamiliaColor = p.colorHex.toUpperCase() == '#16A34A';
              } else if (q == 'rosa' || q == 'pink') {
                matchFamiliaColor = p.colorHex.toUpperCase() == '#F472B6';
              } else if (q == 'cyan' || q == 'celeste' || q == 'royale' || q == 'mariposa' || q == 'corona') {
                matchFamiliaColor = p.colorHex.toUpperCase() == '#00B4D8';
              } else if (q == 'cyber' || q == 'holografico' || q == 'holográfico' || q == 'anillo') {
                matchFamiliaColor = p.colorHex.toUpperCase() == '#0284C7';
              } else if (q == 'neon' || q == 'neón' || q == 'ondas' || q == 'fuego') {
                matchFamiliaColor = p.colorHex.toUpperCase() == '#FF5722';
              } else if (q == 'botanical' || q == 'dark' || q == 'ronell') {
                matchFamiliaColor = p.colorHex.toUpperCase() == '#334155';
              } else if (q == 'azul') {
                matchFamiliaColor = p.colorHex.toUpperCase() == '#0B2545' ||
                    p.colorHex.toUpperCase() == '#13315C' ||
                    p.colorHex.toUpperCase() == '#00B4D8' ||
                    p.colorHex.toUpperCase() == '#0284C7';
              } else if (q == 'rojo') {
                matchFamiliaColor = p.colorHex.toUpperCase() == '#DC2626';
              } else if (q == 'transparente' || q == 'clear' || q == 'tpu') {
                matchFamiliaColor = p.colorHex.toUpperCase() == '#E5E7EB' || p.categoria == 'transparente';
              } else if (q == 'blanco') {
                matchFamiliaColor = p.colorHex.toUpperCase() == '#FFFFFF';
              } else if (q == 'negro') {
                matchFamiliaColor = p.colorHex.toUpperCase() == '#000000';
              }

              if (!matchNombre && !matchCodigo && !matchColorHex && !matchColorNom && !matchModelos && !matchCategoria && !matchFamiliaColor) {
                return false;
              }
            }
            return true;
          }).toList();

          return CustomScrollView(
            slivers: [
              // Barra de filtros con fondo oscuro que se desplaza hacia arriba al hacer scroll
              SliverToBoxAdapter(
                child: _buildFiltros(conteoColores),
              ),
              // Grilla de productos limpia y centrada para PC
              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: productosFiltrados.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 60),
                            child: Center(
                              child: Text(
                                'No hay fundas disponibles para estos filtros.',
                                style: TextStyle(color: AppColors.textoSecundario),
                              ),
                            ),
                          )
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              final isWide = constraints.maxWidth > 900;
                              final isMedium = constraints.maxWidth > 600;
                              final crossAxisCount = isWide ? 4 : (isMedium ? 3 : 2);
                              final childAspectRatio = isWide ? 0.75 : 0.68;

                              return GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                padding: const EdgeInsets.all(16),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  mainAxisSpacing: 16,
                                  crossAxisSpacing: 16,
                                  childAspectRatio: childAspectRatio,
                                ),
                                itemCount: productosFiltrados.length,
                                itemBuilder: (context, i) {
                                  final p = productosFiltrados[i];
                                  return ProductoCard(
                                    producto: p,
                                    onTap: () => _mostrarModalDetalle(p),
                                  );
                                },
                              );
                            },
                          ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 32),
              ),
            ],
          );
        },
      ),
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
    final busqueda = context.read<BusquedaCatalogo>();
    final mostrarBuscador = Breakpoints.esMovil(context);
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
                if (mostrarBuscador)
                Expanded(
                  child: TextField(
                    controller: busqueda.controller,
                    focusNode: busqueda.focoCatalogo,
                    textInputAction: TextInputAction.search,
                    style: const TextStyle(color: AppColors.textoPrincipal),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      hintText: 'Buscar modelo, color o código',
                      prefixIcon: const Icon(Icons.search, color: AppColors.textoAtenuado),
                      suffixIcon: busqueda.consulta.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              tooltip: 'Borrar búsqueda',
                              onPressed: busqueda.limpiar,
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(28),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                )
                else
                  const Spacer(),
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
                          : c == 'silicona'
                              ? 'Silicona'
                              : c == 'transparente'
                                  ? 'Transparente'
                                  : c == 'cuero'
                                      ? 'Cuero'
                                      : c == 'dualtek'
                                          ? 'DualTek'
                                          : c == 'magsafe'
                                              ? 'MagSafe'
                                              : 'Todas',
                    ),
                    selected: selected,
                    showCheckmark: false,
                    color: WidgetStateProperty.resolveWith<Color?>((states) {
                      if (states.contains(WidgetState.selected)) {
                        return AppColors.dorado;
                      }
                      return AppColors.azulClaro;
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
