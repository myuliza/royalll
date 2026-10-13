import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:royal_app/models/venta.dart';
import 'package:royal_app/screens/empleado/ventas_tab.dart';
import 'package:royal_app/theme/app_theme.dart';
import 'package:royal_app/theme/theme_controller.dart';
import 'package:royal_app/utils/estadisticas_ventas.dart';

import 'soporte_pruebas.dart';

Venta _venta(String id, DateTime fecha, List<(String, String, int, int)> items, {String? codigo}) {
  final lineas = [
    for (final (pid, cat, cant, precio) in items)
      ItemVenta(productoId: pid, nombre: 'Funda $pid', modelo: 'iPhone 15', categoria: cat, cantidad: cant, precioUnitario: precio),
  ];
  final total = lineas.fold(0, (s, i) => s + i.subtotal);
  return Venta(id: id, fecha: fecha, items: lineas, subtotal: total, descuento: 0, total: total, codigoPromocional: codigo);
}

void main() {
  final ahora = DateTime(2026, 10, 13, 15, 30);

  group('Estadísticas de ventas', () {
    final ventas = [
      _venta('a', DateTime(2026, 10, 13, 10), [('1', 'silicona', 2, 90000)], codigo: 'ROYAL10'),
      _venta('b', DateTime(2026, 10, 13, 14), [('2', 'cuero', 1, 150000), ('1', 'silicona', 1, 90000)]),
      _venta('c', DateTime(2026, 10, 12, 9), [('3', 'magsafe', 1, 135000)]), // ayer
      _venta('d', DateTime(2026, 10, 1, 9), [('1', 'silicona', 3, 90000)]), // hace 12 días
      _venta('e', DateTime(2025, 6, 1, 9), [('2', 'cuero', 1, 150000)]), // año pasado
    ];

    test('Hoy vs. ayer', () {
      final r = ResumenVentas.calcular(ventas, PeriodoVentas.hoy, ahora);
      expect(r.pedidos, 2);
      expect(r.unidades, 4);
      expect(r.ingresos, 420000);
      expect(r.ticketPromedio, 210000);
      expect(r.pedidosAnterior, 1);
      expect(r.ingresosAnterior, 135000);
      expect(ResumenVentas.variacion(r.ingresos, r.ingresosAnterior)!.round(), 211);
      expect(r.serie.length, 24);
      expect(r.serie[10].ingresos, 180000);
      expect(r.serie[14].unidades, 2);
      expect(r.codigosUsados, 1);
    });

    test('7 días: serie diaria, categorías y más vendidos', () {
      final r = ResumenVentas.calcular(ventas, PeriodoVentas.semana, ahora);
      expect(r.pedidos, 3);
      expect(r.serie.length, 7);
      expect(r.serie.last.etiqueta, '13/10');
      expect(r.serie.last.ingresos, 420000);
      expect(r.categorias.first.categoria, 'silicona');
      expect(r.categorias.first.unidades, 3);
      expect(r.masVendidos.first.productoId, '1');
      expect(r.masVendidos.first.unidades, 3);
      // El pedido de hace 12 días cae en el período anterior
      expect(r.pedidosAnterior, 1);
    });

    test('Este año: serie mensual y comparación con el año pasado', () {
      final r = ResumenVentas.calcular(ventas, PeriodoVentas.anio, ahora);
      expect(r.pedidos, 4);
      expect(r.serie.length, 10);
      expect(r.serie.last.etiqueta, 'Oct');
      expect(r.pedidosAnterior, 1);
    });

    test('Sin base de comparación no hay variación', () {
      expect(ResumenVentas.variacion(100, 0), isNull);
      expect(ResumenVentas.variacion(0, 0), 0);
    });

    test('Los datos de ejemplo cubren los períodos', () {
      final demo = ventasDeEjemplo([
        (id: '1', nombre: 'Funda iPhone 15', modelo: 'iPhone 15', categoria: 'silicona', precio: 90000),
        (id: '2', nombre: 'Funda iPhone 14', modelo: 'iPhone 14', categoria: 'cuero', precio: 150000),
      ], ahora);
      expect(demo, isNotEmpty);
      expect(ResumenVentas.calcular(demo, PeriodoVentas.mes, ahora).vacio, isFalse);
      expect(demo.every((v) => !v.fecha.isAfter(ahora)), isTrue);
    });
  });

  group('Dashboard de ventas', () {
    final productos = productosDePrueba();
    final ventas = ventasDeEjemplo([
      for (final p in productos)
        (id: p.id, nombre: p.nombre, modelo: p.modelosCompatibles.first, categoria: p.categoria, precio: p.precioFinal),
    ], ahora);

    Future<void> montar(WidgetTester tester, Size tamano, ThemeMode modo, {List<Venta>? datos}) async {
      await cargarFuentes();
      fijarTamano(tester, tamano);
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => ThemeController(),
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: modo,
            home: Scaffold(
              body: VentasTab(productos: productos, ventasDePrueba: datos ?? ventas, ahoraDePrueba: ahora),
            ),
          ),
        ),
      );
      await avanzar(tester, 8);
    }

    for (final modo in [ThemeMode.light, ThemeMode.dark]) {
      for (final t in tamanosVerificados.entries) {
        testWidgets('ventas ${t.key} ${modo.name}: sin overflow', (tester) async {
          await montar(tester, t.value, modo);
          expect(find.text('Ingresos'), findsOneWidget);
          expect(find.text('Más vendidos'), findsOneWidget);
          expect(tester.takeException(), isNull);
          await capturar(tester, 'ventas_${t.key}_${modo.name}');
        });
      }
    }

    testWidgets('Cambiar de período recalcula', (tester) async {
      await montar(tester, const Size(1366, 768), ThemeMode.light);
      await tester.tap(find.text('Hoy'));
      await avanzar(tester);
      expect(find.text('Por hora'), findsOneWidget);
      await tester.tap(find.text('Este año'));
      await avanzar(tester);
      expect(find.text('Por mes'), findsOneWidget);
    });

    testWidgets('Sin ventas muestra el estado vacío', (tester) async {
      await montar(tester, const Size(390, 844), ThemeMode.light, datos: const []);
      expect(find.text('Todavía no hay ventas en este período'), findsOneWidget);
    });
  });
}
