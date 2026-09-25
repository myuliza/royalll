import 'package:flutter_test/flutter_test.dart';
import 'package:royal_app/models/producto.dart';

void main() {
  test('Producto calcula precioFinal y descuento correctamente', () {
    final producto = Producto(
      id: 'test-1',
      nombre: 'Funda iPhone 14',
      categoria: 'solido',
      modelosCompatibles: ['iPhone 14'],
      precio: 100000,
      colorHex: '#000000',
      personalizable: false,
      stock: 10,
      fotosUrls: [],
      enDescuento: true,
      porcentajeDescuento: 20,
    );

    expect(producto.precio, 100000);
    expect(producto.precioFinal, 80000);
    expect(producto.precioOriginalFormateado, '100.000 Gs');
    expect(producto.precioFinalFormateado, '80.000 Gs');
    expect(producto.precioFormateado, '80.000 Gs');
  });

  test('Producto sin descuento mantiene precio original', () {
    final producto = Producto(
      id: 'test-2',
      nombre: 'Funda iPhone 15',
      categoria: 'transparente',
      modelosCompatibles: ['iPhone 15'],
      precio: 85000,
      colorHex: '#E5E7EB',
      personalizable: false,
      stock: 5,
      fotosUrls: [],
      enDescuento: false,
      porcentajeDescuento: 0,
    );

    expect(producto.precioFinal, 85000);
    expect(producto.precioFormateado, '85.000 Gs');
  });

  test('limpiarNombre elimina "funda royal" y formatea estrictamente como "Funda [Modelo]"', () {
    expect(Producto.limpiarNombre('Funda Royal iPhone 13'), 'Funda iPhone 13');
    expect(Producto.limpiarNombre('funda royal iPhone 14 Pro'), 'Funda iPhone 14 Pro');
    expect(Producto.limpiarNombre('iPhone 15 Pro Max'), 'Funda iPhone 15 Pro Max');
    expect(Producto.limpiarNombre('Funda iPhone 16'), 'Funda iPhone 16');
  });

  test('formatPrice formatea correctamente precios en guaraníes', () {
    final p = Producto(
      id: 'test-3',
      nombre: 'Funda iPhone 16 Pro Max',
      categoria: 'solido',
      modelosCompatibles: [],
      precio: 1500000,
      colorHex: '#FFFFFF',
      personalizable: false,
      stock: 1,
      fotosUrls: [],
    );
    expect(p.precioFormateado, '1.500.000 Gs');
  });
}
