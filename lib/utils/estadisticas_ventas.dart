import 'dart:math' as math;
import '../models/venta.dart';

enum PeriodoVentas { hoy, semana, mes, anio }

extension PeriodoVentasInfo on PeriodoVentas {
  String get etiqueta => switch (this) {
        PeriodoVentas.hoy => 'Hoy',
        PeriodoVentas.semana => '7 días',
        PeriodoVentas.mes => '30 días',
        PeriodoVentas.anio => 'Este año',
      };

  String get comparacion => switch (this) {
        PeriodoVentas.hoy => 'vs. ayer',
        PeriodoVentas.semana => 'vs. 7 días previos',
        PeriodoVentas.mes => 'vs. 30 días previos',
        PeriodoVentas.anio => 'vs. mismo período del año pasado',
      };

  /// Límite de documentos a leer (no se lee toda la colección).
  int get limiteConsulta => switch (this) {
        PeriodoVentas.hoy => 400,
        PeriodoVentas.semana => 1500,
        PeriodoVentas.mes => 4000,
        PeriodoVentas.anio => 10000,
      };
}

class RangoFechas {
  final DateTime desde; // inclusive
  final DateTime hasta; // exclusivo
  const RangoFechas(this.desde, this.hasta);
  bool contiene(DateTime f) => !f.isBefore(desde) && f.isBefore(hasta);
}

/// Rango del período actual y del anterior (para la variación).
({RangoFechas actual, RangoFechas anterior}) rangosDe(PeriodoVentas periodo, DateTime ahora) {
  final hoy = DateTime(ahora.year, ahora.month, ahora.day);
  final manana = hoy.add(const Duration(days: 1));
  switch (periodo) {
    case PeriodoVentas.hoy:
      return (
        actual: RangoFechas(hoy, manana),
        anterior: RangoFechas(hoy.subtract(const Duration(days: 1)), hoy),
      );
    case PeriodoVentas.semana:
    case PeriodoVentas.mes:
      final dias = periodo == PeriodoVentas.semana ? 7 : 30;
      final desde = manana.subtract(Duration(days: dias));
      return (
        actual: RangoFechas(desde, manana),
        anterior: RangoFechas(desde.subtract(Duration(days: dias)), desde),
      );
    case PeriodoVentas.anio:
      final inicio = DateTime(ahora.year);
      return (
        actual: RangoFechas(inicio, manana),
        anterior: RangoFechas(
          DateTime(ahora.year - 1),
          DateTime(ahora.year - 1, ahora.month, ahora.day + 1),
        ),
      );
  }
}

class PuntoSerie {
  final String etiqueta;
  final int ingresos;
  final int unidades;
  const PuntoSerie(this.etiqueta, this.ingresos, this.unidades);
}

class TotalCategoria {
  final String categoria;
  final int unidades;
  final int ingresos;
  const TotalCategoria(this.categoria, this.unidades, this.ingresos);
}

class ProductoVendido {
  final String productoId;
  final String nombre;
  final String modelo;
  final int unidades;
  final int ingresos;
  const ProductoVendido(this.productoId, this.nombre, this.modelo, this.unidades, this.ingresos);
}

/// Resumen calculado para el dashboard de Ventas.
class ResumenVentas {
  final PeriodoVentas periodo;
  final int ingresos;
  final int unidades;
  final int pedidos;
  final int ingresosAnterior;
  final int unidadesAnterior;
  final int pedidosAnterior;
  final List<PuntoSerie> serie;
  final List<TotalCategoria> categorias; // ordenadas por unidades (desc)
  final List<ProductoVendido> masVendidos; // top 5
  final List<Venta> recientes; // últimas 8
  final int codigosUsados;

  const ResumenVentas({
    required this.periodo,
    required this.ingresos,
    required this.unidades,
    required this.pedidos,
    required this.ingresosAnterior,
    required this.unidadesAnterior,
    required this.pedidosAnterior,
    required this.serie,
    required this.categorias,
    required this.masVendidos,
    required this.recientes,
    required this.codigosUsados,
  });

  int get ticketPromedio => pedidos == 0 ? 0 : (ingresos / pedidos).round();
  int get ticketAnterior => pedidosAnterior == 0 ? 0 : (ingresosAnterior / pedidosAnterior).round();
  bool get vacio => pedidos == 0;

  /// Variación porcentual vs. el período anterior (null si no hay base de comparación).
  static double? variacion(num actual, num anterior) {
    if (anterior == 0) return actual == 0 ? 0 : null;
    return (actual - anterior) / anterior * 100;
  }

  static const _meses = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];

  static ResumenVentas calcular(List<Venta> ventas, PeriodoVentas periodo, DateTime ahora) {
    final r = rangosDe(periodo, ahora);
    final actuales = ventas.where((v) => r.actual.contiene(v.fecha)).toList()
      ..sort((a, b) => b.fecha.compareTo(a.fecha));
    final anteriores = ventas.where((v) => r.anterior.contiene(v.fecha)).toList();

    int sumaTotal(List<Venta> l) => l.fold(0, (s, v) => s + v.total);
    int sumaUnidades(List<Venta> l) => l.fold(0, (s, v) => s + v.unidades);

    // Serie temporal: por hora (hoy), por día (7/30 días) o por mes (año)
    final List<PuntoSerie> serie;
    switch (periodo) {
      case PeriodoVentas.hoy:
        final ing = List<int>.filled(24, 0), uni = List<int>.filled(24, 0);
        for (final v in actuales) {
          ing[v.fecha.hour] += v.total;
          uni[v.fecha.hour] += v.unidades;
        }
        serie = [for (var h = 0; h < 24; h++) PuntoSerie('${h.toString().padLeft(2, '0')} h', ing[h], uni[h])];
      case PeriodoVentas.semana:
      case PeriodoVentas.mes:
        final dias = r.actual.hasta.difference(r.actual.desde).inDays;
        final ing = List<int>.filled(dias, 0), uni = List<int>.filled(dias, 0);
        for (final v in actuales) {
          final d = DateTime(v.fecha.year, v.fecha.month, v.fecha.day).difference(r.actual.desde).inDays;
          if (d >= 0 && d < dias) {
            ing[d] += v.total;
            uni[d] += v.unidades;
          }
        }
        serie = [
          for (var d = 0; d < dias; d++)
            () {
              final f = r.actual.desde.add(Duration(days: d));
              return PuntoSerie('${f.day}/${f.month}', ing[d], uni[d]);
            }(),
        ];
      case PeriodoVentas.anio:
        final meses = ahora.month;
        final ing = List<int>.filled(meses, 0), uni = List<int>.filled(meses, 0);
        for (final v in actuales) {
          ing[v.fecha.month - 1] += v.total;
          uni[v.fecha.month - 1] += v.unidades;
        }
        serie = [for (var m = 0; m < meses; m++) PuntoSerie(_meses[m], ing[m], uni[m])];
    }

    // Totales por categoría y por producto
    final porCategoria = <String, (int, int)>{};
    final porProducto = <String, ProductoVendido>{};
    for (final v in actuales) {
      for (final i in v.items) {
        final cat = i.categoria.isEmpty ? 'otras' : i.categoria;
        final prev = porCategoria[cat] ?? (0, 0);
        porCategoria[cat] = (prev.$1 + i.cantidad, prev.$2 + i.subtotal);

        final clave = i.productoId.isNotEmpty ? i.productoId : i.nombre;
        final p = porProducto[clave];
        porProducto[clave] = ProductoVendido(
          i.productoId,
          i.nombre,
          i.modelo,
          (p?.unidades ?? 0) + i.cantidad,
          (p?.ingresos ?? 0) + i.subtotal,
        );
      }
    }
    final categorias = porCategoria.entries.map((e) => TotalCategoria(e.key, e.value.$1, e.value.$2)).toList()
      ..sort((a, b) => b.unidades.compareTo(a.unidades));
    final masVendidos = porProducto.values.toList()..sort((a, b) => b.unidades.compareTo(a.unidades));

    return ResumenVentas(
      periodo: periodo,
      ingresos: sumaTotal(actuales),
      unidades: sumaUnidades(actuales),
      pedidos: actuales.length,
      ingresosAnterior: sumaTotal(anteriores),
      unidadesAnterior: sumaUnidades(anteriores),
      pedidosAnterior: anteriores.length,
      serie: serie,
      categorias: categorias,
      masVendidos: masVendidos.take(5).toList(),
      recientes: actuales.take(8).toList(),
      codigosUsados: actuales.where((v) => v.codigoPromocional != null).length,
    );
  }
}

/// Ventas de ejemplo (solo modo DEMO, en memoria: nunca se escriben en la base).
List<Venta> ventasDeEjemplo(List<({String id, String nombre, String modelo, String categoria, int precio})> productos,
    DateTime ahora) {
  if (productos.isEmpty) return const [];
  final rnd = math.Random(42);
  final ventas = <Venta>[];
  const clientes = ['Ana', 'Lucas', 'Sofía', 'Mateo', 'Valentina', 'Diego', 'Camila', 'Joaquín'];
  const codigos = [null, null, null, 'ROYAL10', null, 'BIENVENIDA'];
  // ~400 días hacia atrás para que todos los períodos y sus comparaciones tengan datos
  for (var d = 0; d < 400; d++) {
    final cantidadDia = rnd.nextInt(d < 30 ? 5 : 3);
    for (var k = 0; k < cantidadDia; k++) {
      final fecha = DateTime(ahora.year, ahora.month, ahora.day, 9 + rnd.nextInt(12), rnd.nextInt(60))
          .subtract(Duration(days: d));
      if (fecha.isAfter(ahora)) continue;
      final items = <ItemVenta>[];
      for (var n = 0; n < 1 + rnd.nextInt(3); n++) {
        final p = productos[rnd.nextInt(productos.length)];
        items.add(ItemVenta(
          productoId: p.id,
          nombre: p.nombre,
          modelo: p.modelo,
          categoria: p.categoria,
          cantidad: 1 + rnd.nextInt(2),
          precioUnitario: p.precio,
        ));
      }
      final subtotal = items.fold(0, (s, i) => s + i.subtotal);
      final codigo = codigos[rnd.nextInt(codigos.length)];
      final descuento = codigo == null ? 0 : (subtotal * 0.1).round();
      ventas.add(Venta(
        id: 'demo-$d-$k',
        fecha: fecha,
        items: items,
        subtotal: subtotal,
        descuento: descuento,
        total: subtotal - descuento,
        codigoPromocional: codigo,
        cliente: clientes[rnd.nextInt(clientes.length)],
        formaPago: rnd.nextBool() ? 'efectivo' : 'transferencia',
      ));
    }
  }
  return ventas;
}
