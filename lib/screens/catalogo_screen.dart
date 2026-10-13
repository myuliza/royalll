import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/producto.dart';
import '../providers/busqueda_catalogo.dart';
import '../theme/breakpoints.dart';
import '../theme/app_theme.dart';
import '../utils/visual.dart';
import '../widgets/producto_card.dart';
import '../widgets/ui/ui.dart';
import 'producto_detalle_screen.dart';

/// Filtros rápidos especiales (también llegan por URL: /catalogo?especial=ofertas).
class FiltroEspecial {
  static const ofertas = 'ofertas';
  static const nuevos = 'nuevos';
  static const personalizables = 'personalizables';

  static const etiquetas = {
    ofertas: 'Ofertas',
    nuevos: 'Nuevos modelos',
    personalizables: 'Personalizables',
  };

  static const iconos = {
    ofertas: Icons.local_offer_outlined,
    nuevos: Icons.new_releases_outlined,
    personalizables: Icons.brush_outlined,
  };

  /// Nuevos modelos = compatibles con iPhone 17 o 18.
  static bool esNuevo(Producto p) => p.modelosCompatibles
      .any((m) => m.startsWith('iPhone 17') || m.startsWith('iPhone 18'));

  static bool cumple(String especial, Producto p) => switch (especial) {
        ofertas => p.enDescuento && p.porcentajeDescuento > 0,
        nuevos => esNuevo(p),
        personalizables => p.personalizable,
        _ => true,
      };
}

class CatalogoScreen extends StatefulWidget {
  /// Filtros iniciales que llegan por URL (ej. /catalogo?categoria=transparente).
  final String? categoria;
  final String? modelo;
  final String? especial;

  /// Solo para tests: datos fijos en lugar de Firestore.
  @visibleForTesting
  final List<Producto>? productosDePrueba;

  const CatalogoScreen(
      {super.key,
      this.categoria,
      this.modelo,
      this.especial,
      this.productosDePrueba});

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

enum _Orden { relevancia, precioMenor, precioMayor, descuento, nombre }

const _etiquetasOrden = {
  _Orden.relevancia: 'Relevancia',
  _Orden.precioMenor: 'Menor precio',
  _Orden.precioMayor: 'Mayor precio',
  _Orden.descuento: 'Mayor descuento',
  _Orden.nombre: 'Nombre (A-Z)',
};

class _CatalogoScreenState extends State<CatalogoScreen> {
  String _categoriaSeleccionada = 'todas';
  String _modeloSeleccionado = 'todos';
  String _especial = '';
  _Orden _orden = _Orden.relevancia;
  final Set<String> _coloresSeleccionados =
      {}; // Filtrado multicolor simultáneo

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
    _especial = FiltroEspecial.etiquetas.containsKey(widget.especial)
        ? widget.especial!
        : '';
  }

  /// Refleja los filtros principales en la URL (en web se puede compartir o recargar).
  void _sincronizarUrl() {
    final router = GoRouter.maybeOf(context);
    if (router == null) return;
    final params = <String, String>{
      if (_categoriaSeleccionada != 'todas')
        'categoria': _categoriaSeleccionada,
      if (_modeloSeleccionado != 'todos') 'modelo': _modeloSeleccionado,
      if (_especial.isNotEmpty) 'especial': _especial,
    };
    router.go(
        Uri(path: '/catalogo', queryParameters: params.isEmpty ? null : params)
            .toString());
  }

  void _cambiar(VoidCallback cambio, {bool url = true}) {
    setState(cambio);
    if (url) _sincronizarUrl();
  }

  void _limpiarTodo(BusquedaCatalogo busqueda) {
    busqueda.limpiar();
    _cambiar(() {
      _categoriaSeleccionada = 'todas';
      _modeloSeleccionado = 'todos';
      _especial = '';
      _orden = _Orden.relevancia;
      _coloresSeleccionados.clear();
    });
  }

  String _nombreColorLegible(String hex) =>
      CatalogoScreen.nombreColorLegible(hex);

  Color _parseHex(String hex) => colorDesdeHex(hex);

  /// Detalle: diálogo en escritorio/tablet, pantalla completa en móvil
  void _mostrarModalDetalle(Producto p) => abrirDetalleProducto(context, p);

  bool _coincideBusqueda(Producto p, String q) {
    final matchNombre = p.nombre.toLowerCase().contains(q);
    final matchCodigo = p.codigoColor.toLowerCase().contains(q);
    final matchColorHex = p.colorHex.toLowerCase().contains(q);
    final colorNom = _nombreColorLegible(p.colorHex).toLowerCase();
    final matchColorNom = colorNom.contains(q);
    final matchModelos =
        p.modelosCompatibles.any((m) => m.toLowerCase().contains(q));
    final matchCategoria = p.categoria.toLowerCase().contains(q);

    // Búsqueda inteligente por familias de colores y estilos
    bool matchFamiliaColor = false;
    if (q == 'titanio' || q == 'gris') {
      matchFamiliaColor = p.colorHex.toUpperCase() == '#64748B';
    } else if (q == 'dorado' ||
        q == 'beige' ||
        q == 'oro' ||
        q == 'floral' ||
        q == 'flores') {
      matchFamiliaColor = p.colorHex.toUpperCase() == '#C9A227';
    } else if (q == 'morado' || q == 'purpura' || q == 'púrpura') {
      matchFamiliaColor = p.colorHex.toUpperCase() == '#7E22CE';
    } else if (q == 'verde') {
      matchFamiliaColor = p.colorHex.toUpperCase() == '#16A34A';
    } else if (q == 'rosa' || q == 'pink') {
      matchFamiliaColor = p.colorHex.toUpperCase() == '#F472B6';
    } else if (q == 'cyan' ||
        q == 'celeste' ||
        q == 'royale' ||
        q == 'mariposa' ||
        q == 'corona') {
      matchFamiliaColor = p.colorHex.toUpperCase() == '#00B4D8';
    } else if (q == 'cyber' ||
        q == 'holografico' ||
        q == 'holográfico' ||
        q == 'anillo') {
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
      matchFamiliaColor = p.colorHex.toUpperCase() == '#E5E7EB' ||
          p.categoria == 'transparente';
    } else if (q == 'blanco') {
      matchFamiliaColor = p.colorHex.toUpperCase() == '#FFFFFF';
    } else if (q == 'negro') {
      matchFamiliaColor = p.colorHex.toUpperCase() == '#000000';
    }

    return matchNombre ||
        matchCodigo ||
        matchColorHex ||
        matchColorNom ||
        matchModelos ||
        matchCategoria ||
        matchFamiliaColor;
  }

  List<Producto> _filtrar(List<Producto> allProductos, String consulta) {
    final filtrados = allProductos.where((p) {
      if (_categoriaSeleccionada != 'todas' &&
          p.categoria != _categoriaSeleccionada) {
        return false;
      }
      if (_modeloSeleccionado != 'todos' &&
          !p.modelosCompatibles.contains(_modeloSeleccionado)) {
        return false;
      }
      // FILTRADO MULTICOLOR: permite seleccionar múltiples colores simultáneos
      if (_coloresSeleccionados.isNotEmpty &&
          !_coloresSeleccionados.contains(p.colorHex.toUpperCase().trim())) {
        return false;
      }
      if (_especial.isNotEmpty && !FiltroEspecial.cumple(_especial, p)) {
        return false;
      }
      // Búsqueda por texto integrada: modelo, color legible, código de modelo/color
      if (consulta.isNotEmpty && !_coincideBusqueda(p, consulta)) {
        return false;
      }
      return true;
    }).toList();

    switch (_orden) {
      case _Orden.relevancia:
        break;
      case _Orden.precioMenor:
        filtrados.sort((a, b) => a.precioFinal.compareTo(b.precioFinal));
      case _Orden.precioMayor:
        filtrados.sort((a, b) => b.precioFinal.compareTo(a.precioFinal));
      case _Orden.descuento:
        int pct(Producto p) => p.enDescuento ? p.porcentajeDescuento : 0;
        filtrados.sort((a, b) => pct(b).compareTo(pct(a)));
      case _Orden.nombre:
        filtrados.sort((a, b) => a.nombre.compareTo(b.nombre));
    }
    return filtrados;
  }

  @override
  Widget build(BuildContext context) {
    // Buscador global (barra superior en escritorio/tablet, campo propio en móvil)
    final busquedaGlobal = context.watch<BusquedaCatalogo>();
    final consulta = busquedaGlobal.consulta;

    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: widget.productosDePrueba != null
            ? null
            : FirebaseFirestore.instance.collection('productos').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const EmptyState.error(
              titulo: 'Error al sincronizar catálogo',
              mensaje: 'No pudimos cargar las fundas. Revisá tu conexión.',
            );
          }
          final cargando =
              widget.productosDePrueba == null && !snapshot.hasData;

          final allProductos = widget.productosDePrueba ??
              (cargando
                  ? <Producto>[]
                  : snapshot.data!.docs
                      .map((d) => Producto.fromMap(
                          d.id, d.data() as Map<String, dynamic>))
                      .toList());

          // 1. Extracción dinámica de colores desde los documentos de Firebase
          final Map<String, int> conteoColores = {};
          final Map<String, int> conteoCategorias = {};
          for (final p in allProductos) {
            final hex = p.colorHex.toUpperCase().trim();
            if (hex.isNotEmpty) {
              conteoColores[hex] = (conteoColores[hex] ?? 0) + 1;
            }
            conteoCategorias[p.categoria] =
                (conteoCategorias[p.categoria] ?? 0) + 1;
          }
          final categorias = [
            ..._categorias,
            ...conteoCategorias.keys.where((c) => !_categorias.contains(c)),
          ];

          // 2. Buscador y filtro integrado (modelo, color, código, categoría y filtros rápidos)
          final productosFiltrados = _filtrar(allProductos, consulta);
          final movil = Breakpoints.esMovil(context);

          return LayoutBuilder(
            builder: (context, constraints) {
              final lateral = math.max(
                Breakpoints.paddingLateral(context),
                (constraints.maxWidth - Breakpoints.anchoMaximo) / 2,
              );

              return Scrollbar(
                child: CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                          lateral, AppSpacing.xl, lateral, AppSpacing.sm),
                      sliver: SliverToBoxAdapter(
                        child: SectionHeader(
                          titulo: 'Catálogo',
                          subtitulo: cargando
                              ? 'Cargando fundas…'
                              : '${productosFiltrados.length} de ${allProductos.length} fundas',
                          grande: true,
                        ),
                      ),
                    ),
                    // Barra de filtros fija al hacer scroll
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _FiltrosDelegate(
                        alto: movil ? 168 : 112,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: lateral),
                          child: _buildFiltros(
                              conteoColores, conteoCategorias, categorias),
                        ),
                      ),
                    ),
                    if (cargando)
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                            lateral, AppSpacing.lg, lateral, AppSpacing.xl),
                        sliver: const SliverToBoxAdapter(
                            child: SkeletonGrid(
                                cantidad: 8, anchoMaximoItem: 250)),
                      )
                    else if (productosFiltrados.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: EmptyState(
                          icono: Icons.search_off_rounded,
                          titulo:
                              'No hay fundas disponibles para estos filtros.',
                          mensaje: 'Probá con otra categoría, modelo o color.',
                          accion: 'Limpiar filtros',
                          onAccion: () => _limpiarTodo(busquedaGlobal),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                            lateral, AppSpacing.lg, lateral, AppSpacing.xxl),
                        sliver: SliverGrid.builder(
                          gridDelegate:
                              SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: movil ? 230 : 260,
                            mainAxisSpacing: AppSpacing.lg,
                            crossAxisSpacing: AppSpacing.lg,
                            childAspectRatio: 0.70,
                          ),
                          itemCount: productosFiltrados.length,
                          itemBuilder: (context, i) {
                            final p = productosFiltrados[i];
                            return ProductoCard(
                              key: ValueKey(p.id),
                              producto: p,
                              onTap: () => _mostrarModalDetalle(p),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  int get _filtrosAvanzadosActivos =>
      (_modeloSeleccionado != 'todos' ? 1 : 0) + _coloresSeleccionados.length;

  bool get _hayFiltros =>
      _categoriaSeleccionada != 'todas' ||
      _modeloSeleccionado != 'todos' ||
      _especial.isNotEmpty ||
      _orden != _Orden.relevancia ||
      _coloresSeleccionados.isNotEmpty;

  /// Filtros de modelo y color en una bottom sheet para liberar espacio al catálogo
  void _mostrarFiltrosAvanzados(Map<String, int> conteoColores) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      isScrollControlled: true,
      constraints: const BoxConstraints(maxWidth: 640),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx, setSheetState) {
          void actualizar(VoidCallback cambio, {bool url = false}) {
            _cambiar(cambio, url: url);
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
                        child: Text('Filtros',
                            style: Theme.of(sheetCtx).textTheme.titleLarge),
                      ),
                      if (_filtrosAvanzadosActivos > 0)
                        TextButton(
                          onPressed: () => actualizar(() {
                            _modeloSeleccionado = 'todos';
                            _coloresSeleccionados.clear();
                          }, url: true),
                          child: const Text('Limpiar filtros'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    key: ValueKey(_modeloSeleccionado),
                    initialValue: _modelos.contains(_modeloSeleccionado)
                        ? _modeloSeleccionado
                        : 'todos',
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Modelo de iPhone',
                      border: OutlineInputBorder(),
                    ),
                    items: _modelos
                        .map((m) => DropdownMenuItem(
                              value: m,
                              child: Text(m == 'todos'
                                  ? 'Todos los modelos de iPhone'
                                  : m),
                            ))
                        .toList(),
                    onChanged: (v) => actualizar(
                        () => _modeloSeleccionado = v ?? 'todos',
                        url: true),
                  ),
                  const SizedBox(height: 20),
                  Text('Colores',
                      style: Theme.of(sheetCtx).textTheme.titleSmall),
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
                            border:
                                Border.all(color: Colors.black26, width: 0.8),
                          ),
                        ),
                        label: Text(
                            '${_nombreColorLegible(hex)} (${entry.value})'),
                        labelStyle: TextStyle(
                            color: isSelected ? AppColors.azul : null),
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

  Widget _buildFiltros(Map<String, int> conteoColores,
      Map<String, int> conteoCategorias, List<String> categorias) {
    final activos = _filtrosAvanzadosActivos;
    final busqueda = context.read<BusquedaCatalogo>();
    final mostrarBuscador = Breakpoints.esMovil(context);
    final royal = context.royal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.md),
        // Buscador integrado por modelo, color y código (en móvil; en escritorio está en la barra superior)
        if (mostrarBuscador) ...[
          SizedBox(
            height: 48,
            child: TextField(
              controller: busqueda.controller,
              focusNode: busqueda.focoCatalogo,
              textInputAction: TextInputAction.search,
              style: TextStyle(color: royal.textoPrincipal),
              decoration: InputDecoration(
                hintText: 'Buscar modelo, color o código',
                prefixIcon: Icon(Icons.search, color: royal.textoAtenuado),
                suffixIcon: busqueda.consulta.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        tooltip: 'Borrar búsqueda',
                        onPressed: busqueda.limpiar,
                      )
                    : null,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  borderSide: BorderSide(color: royal.borde),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  borderSide: BorderSide(color: royal.borde),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  borderSide:
                      const BorderSide(color: AppColors.dorado, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],

        // Selector de categorías
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: categorias.map((c) {
              final selected = c == _categoriaSeleccionada;
              final cuenta = c == 'todas' ? null : conteoCategorias[c] ?? 0;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(cuenta == null
                      ? Categorias.etiqueta(c)
                      : '${Categorias.etiqueta(c)} ($cuenta)'),
                  selected: selected,
                  showCheckmark: false,
                  labelStyle: TextStyle(
                    color: selected ? AppColors.azul : royal.textoPrincipal,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                  side: BorderSide(
                      color: selected ? AppColors.dorado : royal.borde),
                  onSelected: (_) => _cambiar(() => _categoriaSeleccionada = c),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Modelo, orden, filtros rápidos y filtros avanzados (colores)
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _ChipMenu<String>(
                icono: Icons.phone_iphone_rounded,
                etiqueta: _modeloSeleccionado == 'todos'
                    ? 'Modelo'
                    : _modeloSeleccionado,
                activo: _modeloSeleccionado != 'todos',
                opciones: {
                  for (final m in _modelos)
                    m: m == 'todos' ? 'Todos los modelos' : m
                },
                seleccion: _modeloSeleccionado,
                onSeleccion: (m) => _cambiar(() => _modeloSeleccionado = m),
              ),
              const SizedBox(width: 8),
              _ChipMenu<_Orden>(
                icono: Icons.sort_rounded,
                etiqueta: _orden == _Orden.relevancia
                    ? 'Ordenar'
                    : _etiquetasOrden[_orden]!,
                activo: _orden != _Orden.relevancia,
                opciones: _etiquetasOrden,
                seleccion: _orden,
                onSeleccion: (o) => _cambiar(() => _orden = o, url: false),
              ),
              const SizedBox(width: 8),
              for (final e in FiltroEspecial.etiquetas.entries) ...[
                FilterChip(
                  avatar: Icon(
                    FiltroEspecial.iconos[e.key],
                    size: 16,
                    color: _especial == e.key
                        ? AppColors.azul
                        : royal.textoSecundario,
                  ),
                  label: Text(e.value),
                  selected: _especial == e.key,
                  showCheckmark: false,
                  labelStyle: TextStyle(
                      color: _especial == e.key
                          ? AppColors.azul
                          : royal.textoPrincipal),
                  onSelected: (sel) =>
                      _cambiar(() => _especial = sel ? e.key : ''),
                ),
                const SizedBox(width: 8),
              ],
              FilterChip(
                avatar: Badge(
                  isLabelVisible: activos > 0,
                  label: Text('$activos'),
                  backgroundColor: AppColors.azul,
                  textColor: Colors.white,
                  child: Icon(Icons.tune,
                      size: 16,
                      color:
                          activos > 0 ? AppColors.azul : royal.textoSecundario),
                ),
                label: const Text('Filtros'),
                tooltip: 'Modelo y colores',
                selected: activos > 0,
                showCheckmark: false,
                labelStyle: TextStyle(
                    color: activos > 0 ? AppColors.azul : royal.textoPrincipal),
                onSelected: (_) => _mostrarFiltrosAvanzados(conteoColores),
              ),
              if (_hayFiltros) ...[
                const SizedBox(width: 8),
                ActionChip(
                  avatar: Icon(Icons.filter_alt_off_outlined,
                      size: 16, color: royal.textoSecundario),
                  label: const Text('Limpiar'),
                  onPressed: () => _limpiarTodo(busqueda),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Chip que despliega un menú de opciones (modelo, orden).
class _ChipMenu<T> extends StatelessWidget {
  final IconData icono;
  final String etiqueta;
  final bool activo;
  final Map<T, String> opciones;
  final T seleccion;
  final ValueChanged<T> onSeleccion;

  const _ChipMenu({
    required this.icono,
    required this.etiqueta,
    required this.activo,
    required this.opciones,
    required this.seleccion,
    required this.onSeleccion,
  });

  @override
  Widget build(BuildContext context) {
    final royal = context.royal;
    return MenuAnchor(
      style: MenuStyle(
        maximumSize: const WidgetStatePropertyAll(Size(280, 420)),
        shape: WidgetStatePropertyAll(RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md))),
      ),
      menuChildren: [
        for (final o in opciones.entries)
          MenuItemButton(
            leadingIcon: Icon(
              o.key == seleccion ? Icons.check_rounded : null,
              size: 18,
              color: AppColors.dorado,
            ),
            onPressed: () => onSeleccion(o.key),
            child: Text(o.value),
          ),
      ],
      builder: (context, controller, _) => FilterChip(
        avatar: Icon(icono,
            size: 16, color: activo ? AppColors.azul : royal.textoSecundario),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(etiqueta),
            const SizedBox(width: 2),
            Icon(Icons.expand_more_rounded,
                size: 18,
                color: activo ? AppColors.azul : royal.textoSecundario),
          ],
        ),
        selected: activo,
        showCheckmark: false,
        labelStyle:
            TextStyle(color: activo ? AppColors.azul : royal.textoPrincipal),
        onSelected: (_) =>
            controller.isOpen ? controller.close() : controller.open(),
      ),
    );
  }
}

/// Encabezado fijo con la barra de filtros.
class _FiltrosDelegate extends SliverPersistentHeaderDelegate {
  final double alto;
  final Widget child;

  _FiltrosDelegate({required this.alto, required this.child});

  @override
  double get minExtent => alto;
  @override
  double get maxExtent => alto;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final royal = context.royal;
    final elevado = overlapsContent || shrinkOffset > 0;
    return AnimatedContainer(
      duration: AppDurations.rapida,
      decoration: BoxDecoration(
        color: royal.fondo,
        border: Border(
            bottom:
                BorderSide(color: elevado ? royal.borde : Colors.transparent)),
        boxShadow:
            elevado ? AppShadows.suave(Theme.of(context).brightness) : null,
      ),
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _FiltrosDelegate oldDelegate) => true;
}
