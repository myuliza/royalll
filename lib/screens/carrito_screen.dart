import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../models/cupon.dart';
import '../providers/carrito_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'checkout_screen.dart';

class CarritoScreen extends StatefulWidget {
  const CarritoScreen({super.key});

  @override
  State<CarritoScreen> createState() => _CarritoScreenState();
}

class _CarritoScreenState extends State<CarritoScreen> {
  final _cuponController = TextEditingController();
  String? _errorCupon;
  bool _validando = false;

  Future<void> _aplicarCupon(CarritoProvider carrito) async {
    final codigo = _cuponController.text.trim().toUpperCase();
    if (codigo.isEmpty) return;
    setState(() { _validando = true; _errorCupon = null; });

    try {
      final doc = await FirebaseFirestore.instance.collection('cupones').doc(codigo).get();
      if (!doc.exists) {
        setState(() => _errorCupon = 'Cupón no encontrado');
        return;
      }
      final cupon = Cupon.fromMap(doc.data()!);
      if (!cupon.esValido) {
        setState(() => _errorCupon = 'Cupón vencido o sin usos disponibles');
        return;
      }
      carrito.aplicarCupon(cupon);
    } catch (e) {
      setState(() => _errorCupon = 'No se pudo validar el cupón');
    } finally {
      setState(() => _validando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tu carrito')),
      body: Consumer<CarritoProvider>(
        builder: (context, carrito, _) {
          if (carrito.items.isEmpty) {
            return const Center(child: Text('Tu carrito está vacío'));
          }
          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: carrito.items.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, i) {
                    final item = carrito.items[i];
                    return ListTile(
                      title: Text(item.producto.nombre),
                      subtitle: Text(item.producto.precioFormateado),
                      leading: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () => carrito.actualizarCantidad(item.producto.id, item.cantidad - 1),
                          ),
                          Text('${item.cantidad}'),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () {
                              final ok = carrito.actualizarCantidad(item.producto.id, item.cantidad + 1);
                              if (!ok) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Stock máximo de "${item.producto.nombre}" alcanzado (${item.producto.stock} disponibles).'),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => carrito.quitar(item.producto.id),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _cuponController,
                        decoration: InputDecoration(
                          labelText: 'Código promocional',
                          errorText: _errorCupon,
                        ),
                        textCapitalization: TextCapitalization.characters,
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: _validando ? null : () => _aplicarCupon(carrito),
                      child: _validando
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Aplicar'),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, -2))],
                ),
                child: Column(
                  children: [
                    _filaResumen('Subtotal', carrito.subtotal),
                    if (carrito.cuponAplicado != null)
                      _filaResumen('Descuento (${carrito.cuponAplicado!.codigo})', -carrito.descuento, color: AppColors.dorado),
                    const Divider(),
                    _filaResumen('Total', carrito.total, esTotal: true),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CheckoutScreen())),
                        child: const Text('Continuar al pedido'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _filaResumen(String label, int valor, {bool esTotal = false, Color? color}) {
    final formateado = '${valor < 0 ? '-' : ''}${formatPrice(valor.abs())}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: esTotal ? FontWeight.bold : FontWeight.normal, fontSize: esTotal ? 16 : 14)),
          Text(formateado, style: TextStyle(fontWeight: esTotal ? FontWeight.bold : FontWeight.normal, fontSize: esTotal ? 16 : 14, color: color)),
        ],
      ),
    );
  }
}
