import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/producto.dart';
import '../providers/carrito_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_product_image.dart';

class ProductoDetalleScreen extends StatelessWidget {
  final Producto producto;
  const ProductoDetalleScreen({super.key, required this.producto});

  @override
  Widget build(BuildContext context) {
    final tieneDescuento = producto.enDescuento && producto.porcentajeDescuento > 0;
    final agotado = producto.stock <= 0;

    return Scaffold(
      appBar: AppBar(title: Text(producto.nombre)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                color: const Color(0xFFF9FAFB),
                padding: const EdgeInsets.all(24),
                child: AppProductImage(
                  imageUrl: producto.fotoPrincipalUrl,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Categoría y Código
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        producto.codigoColor.isNotEmpty
                            ? '${producto.categoria.toUpperCase()} • ${producto.codigoColor.toUpperCase()}'
                            : producto.categoria.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textoSecundario,
                          letterSpacing: 0.5,
                        ),
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
                          agotado ? 'Agotado' : 'Stock: ${producto.stock} un.',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: agotado ? Colors.red : AppColors.verdeStock,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Nombre del modelo
                  Text(producto.nombre, style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 10),

                  // Precios
                  if (tieneDescuento)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          producto.precioFinalFormateado,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppColors.rojoDescuento,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          producto.precioOriginalFormateado,
                          style: const TextStyle(
                            fontSize: 16,
                            decoration: TextDecoration.lineThrough,
                            color: AppColors.textoAtenuado,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.rojoDescuento,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '-${producto.porcentajeDescuento}% OFF',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      producto.precioFormateado,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.azul,
                      ),
                    ),

                  const SizedBox(height: 18),
                  Text('Modelos compatibles', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: producto.modelosCompatibles
                        .map((m) => Chip(label: Text(m), backgroundColor: AppColors.fondo))
                        .toList(),
                  ),

                  if (producto.personalizable) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.doradoClaro.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.dorado),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.brush_outlined, color: AppColors.dorado),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text('Este modelo se puede personalizar. Coordinamos el diseño por WhatsApp al confirmar el pedido.'),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 28),

                  // Botón Agregar al Carrito con validación de stock
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add_shopping_cart),
                      label: Text(agotado ? 'Producto agotado' : 'Agregar al carrito'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: agotado ? Colors.grey : AppColors.dorado,
                      ),
                      onPressed: agotado
                          ? null
                          : () {
                              final exito = context.read<CarritoProvider>().agregar(producto);
                              if (exito) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('${producto.nombre} agregado al carrito')),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('No es posible agregar más: stock máximo alcanzado.'),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                              }
                            },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
