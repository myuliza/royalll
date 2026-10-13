import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:royal_app/models/cupon.dart';
import 'package:royal_app/providers/carrito_provider.dart';
import 'package:royal_app/screens/empleado/codigos_tab.dart';
import 'package:royal_app/theme/app_theme.dart';
import 'package:royal_app/theme/theme_controller.dart';

import 'soporte_pruebas.dart';

final _ahora = DateTime(2026, 10, 13, 12);

Cupon _cupon({
  String codigo = 'ROYAL10',
  String tipo = 'porcentaje',
  int valor = 10,
  DateTime? inicio,
  DateTime? fin,
  int? max,
  int usos = 0,
  int minimo = 0,
  bool activo = true,
  String aplicaA = AlcanceCupon.todo,
  List<String> categorias = const [],
  List<String> modelos = const [],
}) =>
    Cupon(
      codigo: codigo,
      tipo: tipo,
      valor: valor,
      fechaInicio: inicio,
      vigenciaHasta: fin ?? DateTime(2026, 12, 31),
      usosMaximos: max,
      usosActuales: usos,
      compraMinima: minimo,
      activo: activo,
      aplicaA: aplicaA,
      categorias: categorias,
      modelos: modelos,
    );

void main() {
  group('Modelo Cupon', () {
    test('Estados', () {
      expect(_cupon().estado(_ahora), EstadoCupon.activo);
      expect(_cupon(activo: false).estado(_ahora), EstadoCupon.pausado);
      expect(_cupon(fin: DateTime(2026, 10, 1)).estado(_ahora), EstadoCupon.vencido);
      expect(_cupon(max: 5, usos: 5).estado(_ahora), EstadoCupon.agotado);
      expect(_cupon(inicio: DateTime(2026, 11, 1)).estado(_ahora), EstadoCupon.programado);
    });

    test('Compatibilidad con cupones existentes (sin campos nuevos)', () {
      final viejo = Cupon.fromMap({
        'codigo': 'viejo',
        'tipo': 'monto_fijo',
        'valor': 20000,
        'vigenciaHasta': Timestamp.fromDate(DateTime(2027)),
        'usosMaximos': 10,
        'usosActuales': 3,
      });
      expect(viejo.codigo, 'VIEJO');
      expect(viejo.activo, isTrue);
      expect(viejo.aplicaA, AlcanceCupon.todo);
      expect(viejo.compraMinima, 0);
      expect(viejo.estado(_ahora), EstadoCupon.activo);
      // Sin el campo usosMaximos = sin límite
      expect(Cupon.fromMap({'codigo': 'X', 'vigenciaHasta': '2027-01-01'}).usosMaximos, isNull);
    });

    test('Motivos claros de rechazo', () {
      expect(_cupon().motivoInvalido(subtotal: 100000, subtotalAplicable: 100000, ahora: _ahora), isNull);
      expect(_cupon(activo: false).motivoInvalido(subtotal: 1, subtotalAplicable: 1, ahora: _ahora), contains('pausado'));
      expect(_cupon(fin: DateTime(2026, 10, 2)).motivoInvalido(subtotal: 1, subtotalAplicable: 1, ahora: _ahora),
          contains('venció el 01/10/2026'));
      expect(_cupon(max: 1, usos: 1).motivoInvalido(subtotal: 1, subtotalAplicable: 1, ahora: _ahora),
          contains('límite de usos'));
      expect(_cupon(minimo: 200000).motivoInvalido(subtotal: 150000, subtotalAplicable: 150000, ahora: _ahora),
          contains('compra mínima de 200.000 Gs'));
      expect(_cupon(aplicaA: AlcanceCupon.categorias, categorias: ['cuero'])
              .motivoInvalido(subtotal: 90000, subtotalAplicable: 0, ahora: _ahora),
          contains('no aplica'));
    });

    test('Descuentos: porcentaje y monto fijo con tope', () {
      expect(_cupon(valor: 15).calcularDescuento(200000), 30000);
      expect(_cupon(tipo: 'monto_fijo', valor: 50000).calcularDescuento(200000), 50000);
      expect(_cupon(tipo: 'monto_fijo', valor: 50000).calcularDescuento(30000), 30000);
    });

    test('Formato de código', () {
      expect(Cupon.normalizarCodigo(' royal 10 '), 'ROYAL10');
      expect(Cupon.formatoCodigo.hasMatch('ROYAL10'), isTrue);
      expect(Cupon.formatoCodigo.hasMatch('AB'), isFalse);
      expect(Cupon.formatoCodigo.hasMatch('CON ESPACIO'), isFalse);
    });
  });

  group('Carrito con código', () {
    final ps = productosDePrueba(); // [1] DualTek 102.000 (con 15% off), [2] Cuero 150.000, [3] Silicona 90.000

    test('Aplica solo a las categorías elegidas', () {
      final carrito = CarritoProvider()
        ..agregar(ps[2])
        ..agregar(ps[3]);
      carrito.aplicarCupon(_cupon(valor: 10, aplicaA: AlcanceCupon.categorias, categorias: ['cuero']));
      expect(carrito.subtotal, 240000);
      expect(carrito.subtotalAplicable, 150000);
      expect(carrito.descuento, 15000);
      expect(carrito.total, 225000);
    });

    test('Si el carrito queda bajo la compra mínima, el descuento se suspende con aviso', () {
      final carrito = CarritoProvider()
        ..agregar(ps[2])
        ..agregar(ps[3]);
      carrito.aplicarCupon(_cupon(valor: 10, minimo: 200000));
      expect(carrito.descuento, 24000);
      carrito.quitar(ps[2].id);
      expect(carrito.descuento, 0);
      expect(carrito.avisoCupon, contains('compra mínima'));
    });
  });

  group('Pestaña Códigos promocionales', () {
    final cupones = [
      _cupon(codigo: 'ROYAL10', max: 100, usos: 12, inicio: DateTime(2026, 10, 1)),
      _cupon(codigo: 'BIENVENIDA', tipo: 'monto_fijo', valor: 20000, minimo: 150000),
      _cupon(codigo: 'CUERO25', valor: 25, aplicaA: AlcanceCupon.categorias, categorias: ['cuero', 'magsafe']),
      _cupon(codigo: 'IPHONE17', aplicaA: AlcanceCupon.modelos, modelos: ['iPhone 17', 'iPhone 17 Pro Max']),
      _cupon(codigo: 'PAUSADO', activo: false),
      _cupon(codigo: 'VENCIDO', fin: DateTime(2026, 1, 1)),
      _cupon(codigo: 'AGOTADO', max: 5, usos: 5),
    ];

    Future<void> montar(WidgetTester tester, Size tamano, ThemeMode modo) async {
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
            home: Scaffold(body: CodigosTab(productos: productosDePrueba(), cuponesDePrueba: cupones)),
          ),
        ),
      );
      await avanzar(tester);
    }

    for (final modo in [ThemeMode.light, ThemeMode.dark]) {
      for (final t in tamanosVerificados.entries) {
        testWidgets('codigos ${t.key} ${modo.name}: sin overflow', (tester) async {
          await montar(tester, t.value, modo);
          expect(find.text('ROYAL10'), findsOneWidget);
          expect(tester.takeException(), isNull);
          await capturar(tester, 'codigos_${t.key}_${modo.name}');
        });
      }
    }

    testWidgets('Escritorio usa tabla y móvil tarjetas', (tester) async {
      await montar(tester, const Size(1366, 768), ThemeMode.light);
      expect(find.byType(DataTable), findsOneWidget);
      await montar(tester, const Size(390, 844), ThemeMode.light);
      expect(find.byType(DataTable), findsNothing);
    });

    testWidgets('Buscador y filtro por estado', (tester) async {
      await montar(tester, const Size(1366, 768), ThemeMode.light);
      await tester.enterText(find.byType(TextField), 'royal');
      await avanzar(tester);
      expect(find.text('ROYAL10'), findsOneWidget);
      expect(find.text('BIENVENIDA'), findsNothing);

      await tester.enterText(find.byType(TextField), '');
      await tester.tap(find.text('Pausado (1)'));
      await avanzar(tester);
      expect(find.text('PAUSADO'), findsOneWidget);
      expect(find.text('ROYAL10'), findsNothing);
    });

    testWidgets('El formulario valida el código y el porcentaje', (tester) async {
      await montar(tester, const Size(1366, 768), ThemeMode.light);
      await tester.tap(find.text('Nuevo código'));
      await avanzar(tester);
      await tester.enterText(find.widgetWithText(TextFormField, 'Código'), 'a b');
      await tester.enterText(find.widgetWithText(TextFormField, 'Valor'), '150');
      await tester.tap(find.text('Crear código'));
      await avanzar(tester);
      expect(find.text('Entre 3 y 20 caracteres: A-Z, 0-9, - o _.'), findsOneWidget);
      expect(find.text('El porcentaje no puede superar 100.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
