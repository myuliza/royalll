import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/producto.dart';
import '../providers/carrito_provider.dart';
import '../theme/app_theme.dart';

class ProductoDetalleScreen extends StatelessWidget {
  final Producto producto;
  const ProductoDetalleScreen({super.key, required this.producto});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(producto.nombre)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: producto.fotosUrls.isNotEmpty
                  ? CachedNetworkImage(imageUrl: producto.fotosUrls.first, fit: BoxFit.cover)
                  : Container(color: Colors.grey.shade200, child: const Icon(Icons.phone_iphone, size: 60)),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(producto.nombre, style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 6),
                  Text(producto.precioFormateado, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.azul)),
                  const SizedBox(height: 14),
                  Text('Modelos compatibles', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: producto.modelosCompatibles
                        .map((m) => Chip(label: Text(m), backgroundColor: AppColors.fondo))
                        .toList(),
                  ),
                  if (producto.personalizable) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.doradoClaro.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.dorado),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.brush_outlined, color: AppColors.dorado),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text('Esta funda se puede personalizar. Coordinamos el diseño por WhatsApp al confirmar el pedido.'),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add_shopping_cart),
                      label: const Text('Agregar al carrito'),
                      onPressed: () {
                        context.read<CarritoProvider>().agregar(producto);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${producto.nombre} agregado al carrito')),
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
    );
  }
}
