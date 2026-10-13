import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../models/producto.dart';
import '../../models/venta.dart';
import '../../theme/app_theme.dart';
import '../../utils/estadisticas_ventas.dart';
import '../../utils/formatters.dart';
import '../../utils/visual.dart';
import '../../widgets/app_product_image.dart';
import '../../widgets/ui/ui.dart';

/// Pestaña "Ventas" del panel de empleados: lee la colección `ventas` con un límite
/// según el período (nunca la colección entera) y muestra el dashboard.
class VentasTab extends StatefulWidget {
  final List<Producto> productos;

  /// Solo para tests: ventas fijas en lugar de Firestore.
  @visibleForTesting
  final List<Venta>? ventasDePrueba;

  @visibleForTesting
  final DateTime? ahoraDePrueba;

  const VentasTab({super.key, required this.productos, this.ventasDePrueba, this.ahoraDePrueba});

  @override
  State<VentasTab> createState() => _VentasTabState();
}

class _VentasTabState extends State<VentasTab> {
  PeriodoVentas _periodo = PeriodoVentas.semana;
  bool _demo = false;
  Stream<QuerySnapshot<Map<String, dynamic>>>? _stream;
  PeriodoVentas? _streamPeriodo;

  DateTime get _ahora => widget.ahoraDePrueba ?? DateTime.now();

  Stream<QuerySnapshot<Map<String, dynamic>>> _consulta() {
    if (_stream != null && _streamPeriodo == _periodo) return _stream!;
    final desde = rangosDe(_periodo, _ahora).anterior.desde;
    _streamPeriodo = _periodo;
    _stream = FirebaseFirestore.instance
        .collection('ventas')
        .where('fecha', isGreaterThanOrEqualTo: Timestamp.fromDate(desde))
        .orderBy('fecha', descending: true)
        .limit(_periodo.limiteConsulta)
        .snapshots();
    return _stream!;
  }

  List<Venta> _ventasDemo() => ventasDeEjemplo(
        [
          for (final p in widget.productos)
            (
              id: p.id,
              nombre: p.nombre,
              modelo: p.modelosCompatibles.isNotEmpty ? p.modelosCompatibles.first : '',
              categoria: p.categoria,
              precio: p.precioFinal,
            ),
        ],
        _ahora,
      );

  @override
  Widget build(BuildContext context) {
    final encabezado = _Encabezado(
      periodo: _periodo,
      demo: _demo,
      onPeriodo: (p) => setState(() => _periodo = p),
      onDemo: kDebugMode ? () => setState(() => _demo = !_demo) : null,
    );

    if (_demo || widget.ventasDePrueba != null) {
      final ventas = widget.ventasDePrueba ?? _ventasDemo();
      return _Contenido(
        encabezado: encabezado,
        demo: _demo,
        resumen: ResumenVentas.calcular(ventas, _periodo, _ahora),
        productos: widget.productos,
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _consulta(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          final sinPermiso = snapshot.error is FirebaseException &&
              (snapshot.error as FirebaseException).code == 'permission-denied';
          return _Contenido(
            encabezado: encabezado,
            productos: widget.productos,
            cuerpo: EmptyState.error(
              titulo: sinPermiso ? 'Sin permiso para leer las ventas' : 'No se pudieron cargar las ventas',
              mensaje: sinPermiso
                  ? 'Las reglas publicadas de Firestore todavía no incluyen la colección "ventas". '
                      'Revisá firestore.rules.propuesta.'
                  : 'Revisá tu conexión e intentá de nuevo.',
            ),
          );
        }
        if (!snapshot.hasData) {
          return _Contenido(encabezado: encabezado, productos: widget.productos, cuerpo: const _Esqueleto());
        }
        final docs = snapshot.data!.docs;
        final ventas = docs.map((d) => Venta.fromMap(d.id, d.data())).toList();
        return _Contenido(
          encabezado: encabezado,
          resumen: ResumenVentas.calcular(ventas, _periodo, _ahora),
          productos: widget.productos,
          limiteAlcanzado: docs.length >= _periodo.limiteConsulta,
          onDemo: kDebugMode ? () => setState(() => _demo = true) : null,
        );
      },
    );
  }
}

class _Encabezado extends StatelessWidget {
  final PeriodoVentas periodo;
  final bool demo;
  final ValueChanged<PeriodoVentas> onPeriodo;
  final VoidCallback? onDemo;

  const _Encabezado({required this.periodo, required this.demo, required this.onPeriodo, this.onDemo});

  @override
  Widget build(BuildContext context) {
    final royal = context.royal;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          titulo: 'Ventas',
          subtitulo: 'Productos vendidos, ingresos y actividad. ${periodo.comparacion[0].toUpperCase()}${periodo.comparacion.substring(1)}.',
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final p in PeriodoVentas.values)
              ChoiceChip(
                label: Text(p.etiqueta),
                selected: p == periodo,
                showCheckmark: false,
                labelStyle: TextStyle(
                  color: p == periodo ? AppColors.azul : royal.textoPrincipal,
                  fontWeight: p == periodo ? FontWeight.w700 : FontWeight.w500,
                ),
                onSelected: (_) => onPeriodo(p),
              ),
            if (onDemo != null)
              FilterChip(
                avatar: const Icon(Icons.science_outlined, size: 16),
                label: const Text('Datos de ejemplo (DEMO)'),
                tooltip: 'Solo en modo debug. Genera ventas en memoria; no escribe en la base.',
                selected: demo,
                showCheckmark: false,
                labelStyle: TextStyle(color: demo ? AppColors.azul : royal.textoPrincipal),
                onSelected: (_) => onDemo!(),
              ),
          ],
        ),
        if (demo) ...[
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.6)),
            ),
            child: Row(
              children: [
                const Icon(Icons.science_outlined, color: Colors.orange, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'DEMO · Datos de ejemplo generados en memoria. No se guardan en la base real.',
                    style: TextStyle(color: royal.textoPrincipal, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}

class _Contenido extends StatelessWidget {
  final Widget encabezado;
  final ResumenVentas? resumen;
  final Widget? cuerpo;
  final List<Producto> productos;
  final bool demo;
  final bool limiteAlcanzado;
  final VoidCallback? onDemo;

  const _Contenido({
    required this.encabezado,
    required this.productos,
    this.resumen,
    this.cuerpo,
    this.demo = false,
    this.limiteAlcanzado = false,
    this.onDemo,
  });

  @override
  Widget build(BuildContext context) {
    final r = resumen;
    Widget contenido;
    if (cuerpo != null) {
      contenido = cuerpo!;
    } else if (r == null || r.vacio) {
      contenido = EmptyState(
        icono: Icons.point_of_sale_outlined,
        titulo: 'Todavía no hay ventas en este período',
        mensaje: 'Cada pedido confirmado desde el carrito se registra en la colección "ventas" '
            'y aparece acá automáticamente.',
        accion: onDemo != null ? 'Ver datos de ejemplo (DEMO)' : null,
        onAccion: onDemo,
      );
    } else {
      contenido = VentasVista(resumen: r, productos: productos, limiteAlcanzado: limiteAlcanzado);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 96),
      children: [encabezado, contenido],
    );
  }
}

class _Esqueleto extends StatelessWidget {
  const _Esqueleto();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Row(
          children: [
            Expanded(child: SkeletonBox(height: 110, radio: AppRadius.lg)),
            SizedBox(width: AppSpacing.md),
            Expanded(child: SkeletonBox(height: 110, radio: AppRadius.lg)),
          ],
        ),
        SizedBox(height: AppSpacing.md),
        SkeletonBox(height: 280, width: double.infinity, radio: AppRadius.lg),
      ],
    );
  }
}

/// Dashboard de ventas (solo presentación).
class VentasVista extends StatelessWidget {
  final ResumenVentas resumen;
  final List<Producto> productos;
  final bool limiteAlcanzado;

  const VentasVista({super.key, required this.resumen, required this.productos, this.limiteAlcanzado = false});

  @override
  Widget build(BuildContext context) {
    final r = resumen;
    final fotos = {for (final p in productos) p.id: p.fotoPrincipalUrl};
    final comp = r.periodo.comparacion;

    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final colStats = w >= 1000 ? 4 : 2;
        final colInferior = w >= 1100 ? 3 : (w >= 700 ? 2 : 1);

        final stats = [
          StatCard(
            titulo: 'Ingresos',
            valor: formatPrice(r.ingresos),
            icono: Icons.payments_outlined,
            variacion: ResumenVentas.variacion(r.ingresos, r.ingresosAnterior),
            textoVariacion: comp,
            degradado: AppColors.degradadoVerde,
          ),
          StatCard(
            titulo: 'Unidades vendidas',
            valor: '${r.unidades}',
            icono: Icons.inventory_2_outlined,
            variacion: ResumenVentas.variacion(r.unidades, r.unidadesAnterior),
            textoVariacion: comp,
            degradado: AppColors.degradadoCyan,
          ),
          StatCard(
            titulo: 'Pedidos',
            valor: '${r.pedidos}',
            icono: Icons.receipt_long_outlined,
            variacion: ResumenVentas.variacion(r.pedidos, r.pedidosAnterior),
            textoVariacion: comp,
          ),
          StatCard(
            titulo: 'Ticket promedio',
            valor: formatPrice(r.ticketPromedio),
            icono: Icons.shopping_cart_checkout_rounded,
            variacion: ResumenVentas.variacion(r.ticketPromedio, r.ticketAnterior),
            textoVariacion: comp,
          ),
        ];

        final evolucion = _Panel(
          titulo: 'Evolución de ingresos',
          subtitulo: r.periodo == PeriodoVentas.hoy ? 'Por hora' : (r.periodo == PeriodoVentas.anio ? 'Por mes' : 'Por día'),
          child: SizedBox(height: 240, child: _GraficoEvolucion(serie: r.serie)),
        );
        final anillos = _Panel(
          titulo: 'Participación por categoría',
          subtitulo: '% de unidades vendidas',
          child: _AnillosCategorias(categorias: r.categorias, totalUnidades: r.unidades),
        );
        final barras = _Panel(
          titulo: 'Unidades por categoría',
          child: SizedBox(height: 220, child: _GraficoCategorias(categorias: r.categorias)),
        );
        final masVendidos = _Panel(
          titulo: 'Más vendidos',
          child: _MasVendidos(productos: r.masVendidos, fotos: fotos),
        );
        final actividad = _Panel(
          titulo: 'Actividad reciente',
          child: _ActividadReciente(ventas: r.recientes),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Columnas(columnas: colStats, children: stats),
            const SizedBox(height: AppSpacing.lg),
            if (w >= 1000)
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(flex: 3, child: evolucion),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(flex: 2, child: anillos),
                  ],
                ),
              )
            else ...[
              evolucion,
              const SizedBox(height: AppSpacing.lg),
              anillos,
            ],
            const SizedBox(height: AppSpacing.lg),
            _Columnas(columnas: colInferior, children: [barras, masVendidos, actividad]),
            const SizedBox(height: AppSpacing.lg),
            _Panel(
              titulo: 'Categorías',
              subtitulo: 'Totales del período${r.codigosUsados > 0 ? ' · ${r.codigosUsados} pedidos con código promocional' : ''}',
              child: _CategoriasProgreso(categorias: r.categorias, totalUnidades: r.unidades),
            ),
            if (limiteAlcanzado) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                'Se muestran las últimas ${r.periodo.limiteConsulta} ventas del período (límite de lectura).',
                style: TextStyle(fontSize: 12, color: context.royal.textoSecundario),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Reparte los hijos en N columnas de igual ancho (las filas se apilan).
class _Columnas extends StatelessWidget {
  final int columnas;
  final List<Widget> children;

  const _Columnas({required this.columnas, required this.children});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        const espacio = AppSpacing.lg;
        final ancho = (c.maxWidth - espacio * (columnas - 1)) / columnas;
        return Wrap(
          spacing: espacio,
          runSpacing: espacio,
          children: [for (final w in children) SizedBox(width: ancho, child: w)],
        );
      },
    );
  }
}

class _Panel extends StatelessWidget {
  final String titulo;
  final String? subtitulo;
  final Widget child;

  const _Panel({required this.titulo, required this.child, this.subtitulo});

  @override
  Widget build(BuildContext context) {
    final royal = context.royal;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg + 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(titulo, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: royal.textoPrincipal)),
          if (subtitulo != null)
            Text(subtitulo!, style: TextStyle(fontSize: 12, color: royal.textoSecundario)),
          const SizedBox(height: AppSpacing.lg),
          child,
        ],
      ),
    );
  }
}

/// "1,2 M" / "350 mil" / "900" para ejes de gráficos.
String _compacto(num v) {
  if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(v >= 10000000 ? 0 : 1).replaceAll('.', ',')} M';
  if (v >= 1000) return '${(v / 1000).round()} mil';
  return v.round().toString();
}

class _GraficoEvolucion extends StatelessWidget {
  final List<PuntoSerie> serie;
  const _GraficoEvolucion({required this.serie});

  @override
  Widget build(BuildContext context) {
    final royal = context.royal;
    final maxY = serie.fold<int>(0, (m, p) => math.max(m, p.ingresos));
    final techo = maxY == 0 ? 1.0 : maxY * 1.2;
    final pasoX = math.max(1, (serie.length / 7).ceil());
    const naranja = AppColors.degradadoNaranja;

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: techo,
        minX: 0,
        maxX: (serie.length - 1).toDouble(),
        gridData: FlGridData(
          drawVerticalLine: false,
          horizontalInterval: techo / 4,
          getDrawingHorizontalLine: (_) => FlLine(color: royal.borde, strokeWidth: 1, dashArray: [4, 4]),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 52,
              interval: techo / 4,
              getTitlesWidget: (v, meta) => SideTitleWidget(
                meta: meta,
                child: Text(_compacto(v), style: TextStyle(fontSize: 10, color: royal.textoSecundario)),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              interval: pasoX.toDouble(),
              getTitlesWidget: (v, meta) {
                final i = v.round();
                if (i < 0 || i >= serie.length || v != i.toDouble()) return const SizedBox.shrink();
                return SideTitleWidget(
                  meta: meta,
                  child: Text(serie[i].etiqueta, style: TextStyle(fontSize: 10, color: royal.textoSecundario)),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          handleBuiltInTouches: true,
          touchTooltipData: LineTouchTooltipData(
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            maxContentWidth: 180,
            tooltipBorderRadius: BorderRadius.circular(AppRadius.sm),
            getTooltipColor: (_) => AppColors.azulClaro,
            getTooltipItems: (spots) => [
              for (final s in spots)
                LineTooltipItem(
                  '${serie[s.x.round()].etiqueta}\n',
                  const TextStyle(fontFamily: AppTheme.fontFamily, color: Colors.white70, fontSize: 11),
                  children: [
                    TextSpan(
                      text: formatPrice(s.y),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    TextSpan(
                      text: '\n${serie[s.x.round()].unidades} unidades',
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
            ],
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [for (var i = 0; i < serie.length; i++) FlSpot(i.toDouble(), serie[i].ingresos.toDouble())],
            isCurved: true,
            preventCurveOverShooting: true,
            barWidth: 3,
            gradient: const LinearGradient(colors: naranja),
            dotData: FlDotData(show: serie.length <= 12),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [naranja.first.withValues(alpha: 0.45), naranja.last.withValues(alpha: 0.0)],
              ),
            ),
          ),
        ],
      ),
      duration: AppDurations.lenta,
    );
  }
}

class _GraficoCategorias extends StatelessWidget {
  final List<TotalCategoria> categorias;
  const _GraficoCategorias({required this.categorias});

  @override
  Widget build(BuildContext context) {
    final royal = context.royal;
    final lista = categorias.take(7).toList();
    final maxY = lista.fold<int>(0, (m, c) => math.max(m, c.unidades));

    return BarChart(
      BarChartData(
        maxY: maxY == 0 ? 1 : maxY * 1.2,
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(color: royal.borde, strokeWidth: 1, dashArray: [4, 4]),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (v, meta) => SideTitleWidget(
                meta: meta,
                child: Text(v.round().toString(), style: TextStyle(fontSize: 10, color: royal.textoSecundario)),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (v, meta) {
                final i = v.round();
                if (i < 0 || i >= lista.length) return const SizedBox.shrink();
                final etiqueta = Categorias.etiqueta(lista[i].categoria);
                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    etiqueta.length > 7 ? '${etiqueta.substring(0, 6)}.' : etiqueta,
                    style: TextStyle(fontSize: 10, color: royal.textoSecundario),
                  ),
                );
              },
            ),
          ),
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            tooltipBorderRadius: BorderRadius.circular(AppRadius.sm),
            getTooltipColor: (_) => AppColors.azulClaro,
            getTooltipItem: (group, _, rod, __) {
              final c = lista[group.x];
              return BarTooltipItem(
                '${Categorias.etiqueta(c.categoria)}\n',
                const TextStyle(fontFamily: AppTheme.fontFamily, color: Colors.white70, fontSize: 11),
                children: [
                  TextSpan(
                    text: '${c.unidades} unidades\n',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  TextSpan(text: formatPrice(c.ingresos), style: const TextStyle(color: Colors.white70, fontSize: 11)),
                ],
              );
            },
          ),
        ),
        barGroups: [
          for (var i = 0; i < lista.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: lista[i].unidades.toDouble(),
                  width: 18,
                  borderRadius: BorderRadius.circular(6),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Categorias.de(lista[i].categoria).color,
                      Color.lerp(Categorias.de(lista[i].categoria).color, Colors.white, 0.35)!,
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      duration: AppDurations.lenta,
    );
  }
}

class _AnillosCategorias extends StatelessWidget {
  final List<TotalCategoria> categorias;
  final int totalUnidades;
  const _AnillosCategorias({required this.categorias, required this.totalUnidades});

  @override
  Widget build(BuildContext context) {
    final royal = context.royal;
    final lista = categorias.take(6).toList();
    return Wrap(
      spacing: AppSpacing.lg,
      runSpacing: AppSpacing.lg,
      alignment: WrapAlignment.spaceEvenly,
      children: [
        for (final c in lista)
          () {
            final pct = totalUnidades == 0 ? 0.0 : c.unidades / totalUnidades * 100;
            final color = Categorias.de(c.categoria).color;
            return Tooltip(
              message: '${Categorias.etiqueta(c.categoria)}: ${c.unidades} unidades · ${formatPrice(c.ingresos)}',
              child: SizedBox(
                width: 92,
                child: Column(
                  children: [
                    SizedBox(
                      width: 76,
                      height: 76,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          PieChart(
                            PieChartData(
                              startDegreeOffset: -90,
                              sectionsSpace: 0,
                              centerSpaceRadius: 28,
                              sections: [
                                PieChartSectionData(value: pct, color: color, radius: 9, showTitle: false),
                                PieChartSectionData(
                                  value: 100 - pct,
                                  color: royal.superficieAlta,
                                  radius: 9,
                                  showTitle: false,
                                ),
                              ],
                            ),
                            duration: AppDurations.lenta,
                          ),
                          Text(
                            '${pct.round()}%',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: royal.textoPrincipal),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      Categorias.etiqueta(c.categoria),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: royal.textoSecundario),
                    ),
                  ],
                ),
              ),
            );
          }(),
      ],
    );
  }
}

class _MasVendidos extends StatelessWidget {
  final List<ProductoVendido> productos;
  final Map<String, String> fotos;
  const _MasVendidos({required this.productos, required this.fotos});

  @override
  Widget build(BuildContext context) {
    final royal = context.royal;
    return Column(
      children: [
        for (var i = 0; i < productos.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: royal.fondoImagen,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: AppProductImage(imageUrl: fotos[productos[i].productoId] ?? '', height: 36),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        productos[i].nombre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: royal.textoPrincipal),
                      ),
                      Text(
                        productos[i].modelo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, color: royal.textoSecundario),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.dorado.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    '${productos[i].unidades} un.',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: context.esOscuro ? AppColors.doradoClaro : AppColors.doradoOscuro,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

String _haceCuanto(DateTime f) {
  final d = DateTime.now().difference(f);
  if (d.inMinutes < 1) return 'recién';
  if (d.inMinutes < 60) return 'hace ${d.inMinutes} min';
  if (d.inHours < 24) return 'hace ${d.inHours} h';
  if (d.inDays == 1) return 'ayer';
  if (d.inDays < 7) return 'hace ${d.inDays} días';
  return '${f.day.toString().padLeft(2, '0')}/${f.month.toString().padLeft(2, '0')}/${f.year}';
}

class _ActividadReciente extends StatelessWidget {
  final List<Venta> ventas;
  const _ActividadReciente({required this.ventas});

  @override
  Widget build(BuildContext context) {
    final royal = context.royal;
    return Column(
      children: [
        for (final v in ventas.take(6))
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.verdeStock.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.receipt_long_rounded, size: 20, color: AppColors.verdeStock),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        v.cliente.isEmpty ? 'Pedido' : 'Pedido de ${v.cliente}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: royal.textoPrincipal),
                      ),
                      Text(
                        '${v.unidades} un. · ${_haceCuanto(v.fecha)}${v.codigoPromocional != null ? ' · ${v.codigoPromocional}' : ''}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, color: royal.textoSecundario),
                      ),
                    ],
                  ),
                ),
                Text(
                  formatPrice(v.total),
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: royal.textoPrincipal),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _CategoriasProgreso extends StatelessWidget {
  final List<TotalCategoria> categorias;
  final int totalUnidades;
  const _CategoriasProgreso({required this.categorias, required this.totalUnidades});

  @override
  Widget build(BuildContext context) {
    final royal = context.royal;
    return Column(
      children: [
        for (final c in categorias)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Categorias.de(c.categoria).color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Categorias.de(c.categoria).icono, size: 18, color: Categorias.de(c.categoria).color),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              Categorias.etiqueta(c.categoria),
                              style: TextStyle(fontWeight: FontWeight.w600, color: royal.textoPrincipal),
                            ),
                          ),
                          Text(
                            '${c.unidades} un. · ${formatPrice(c.ingresos)}',
                            style: TextStyle(fontSize: 12, color: royal.textoSecundario),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: totalUnidades == 0 ? 0 : c.unidades / totalUnidades),
                          duration: AppDurations.lenta,
                          builder: (_, v, __) => LinearProgressIndicator(
                            value: v,
                            minHeight: 8,
                            backgroundColor: royal.superficieAlta,
                            color: Categorias.de(c.categoria).color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
