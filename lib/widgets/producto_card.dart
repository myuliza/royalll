import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/producto.dart';
import '../theme/app_theme.dart';

class ProductoCard extends StatelessWidget {
  final Producto producto;
  final VoidCallback onTap;

  const ProductoCard({super.key, required this.producto, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: producto.fotosUrls.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: producto.fotosUrls.first,
                      fit: BoxFit.cover,
                      placeholder: (c, u) => Container(color: Colors.grey.shade200),
                      errorWidget: (c, u, e) => Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.image_not_supported_outlined),
                      ),
                    )
                  : Container(
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.phone_iphone, size: 40, color: Colors.grey),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    producto.nombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  if (producto.personalizable)
                    const Text('Personalizable', style: TextStyle(fontSize: 11, color: AppColors.dorado)),
                  const SizedBox(height: 4),
                  Text(
                    producto.precioFormateado,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.azul),
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
