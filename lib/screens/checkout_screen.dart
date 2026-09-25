import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/app_config.dart';
import '../utils/formatters.dart';
import '../providers/carrito_provider.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _nombreController = TextEditingController();
  final _formaPago = ValueNotifier<String>('efectivo');
  final _formKey = GlobalKey<FormState>();
  bool _procesando = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _formaPago.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final carrito = context.watch<CarritoProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Confirmar pedido')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Datos para el pedido', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(labelText: 'Tu nombre'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresá tu nombre' : null,
              ),
              const SizedBox(height: 16),
              const Text('Forma de pago', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ValueListenableBuilder<String>(
                valueListenable: _formaPago,
                builder: (context, value, _) => Column(
                  children: [
                    RadioListTile<String>(
                      value: 'efectivo',
                      groupValue: value,
                      title: const Text('Efectivo'),
                      onChanged: (v) {
                        if (v != null) _formaPago.value = v;
                      },
                    ),
                    RadioListTile<String>(
                      value: 'transferencia',
                      groupValue: value,
                      title: const Text('Transferencia'),
                      onChanged: (v) {
                        if (v != null) _formaPago.value = v;
                      },
                    ),
                  ],
                ),
              ),
              const Spacer(),
              const Text(
                'Al confirmar se descontará el stock en Firebase y se abrirá WhatsApp para coordinar la entrega.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: _procesando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.chat_bubble_outline),
                  label: Text(_procesando ? 'Procesando stock...' : 'Enviar pedido por WhatsApp'),
                  onPressed: _procesando ? null : () => _confirmarPedido(carrito),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmarPedido(CarritoProvider carrito) async {
    if (!_formKey.currentState!.validate()) return;
    if (carrito.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El carrito está vacío.')),
      );
      return;
    }

    setState(() => _procesando = true);

    try {
      // 1. TRANSACCIÓN RIGUROSA EN FIRESTORE: Descontar stock y validar disponibilidad real
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        for (final item in carrito.items) {
          final docRef = FirebaseFirestore.instance.collection('productos').doc(item.producto.id);
          final snapshot = await transaction.get(docRef);

          if (!snapshot.exists) {
            throw Exception('El producto "${item.producto.nombre}" ya no existe en el catálogo.');
          }

          final stockActual = (snapshot.data()?['stock'] as num?)?.toInt() ?? 0;
          if (stockActual < item.cantidad) {
            throw Exception('Stock insuficiente para "${item.producto.nombre}". Quedan solo $stockActual unidades.');
          }

          transaction.update(docRef, {'stock': stockActual - item.cantidad});
        }

        // 2. Si se aplicó cupón, incrementar usosActuales con FieldValue.increment(1)
        if (carrito.cuponAplicado != null) {
          final cuponRef = FirebaseFirestore.instance.collection('cupones').doc(carrito.cuponAplicado!.codigo);
          transaction.update(cuponRef, {'usosActuales': FieldValue.increment(1)});
        }
      });

      // 3. Armar mensaje de WhatsApp con formato centralizado
      final buffer = StringBuffer();
      buffer.writeln('¡Hola ${AppConfig.appName}! Quiero confirmar este pedido:');
      buffer.writeln();
      for (final item in carrito.items) {
        buffer.writeln('• ${item.cantidad}x ${item.producto.nombre} — ${item.producto.precioFinalFormateado} c/u');
      }
      buffer.writeln();
      if (carrito.cuponAplicado != null) {
        buffer.writeln('Cupón aplicado: ${carrito.cuponAplicado!.codigo} (-${formatPrice(carrito.descuento)})');
      }
      buffer.writeln('Total: ${formatPrice(carrito.total)}');
      buffer.writeln();
      buffer.writeln('Cliente: ${_nombreController.text.trim()}');
      buffer.writeln('Pago: ${_formaPago.value == 'efectivo' ? 'Efectivo' : 'Transferencia'}');

      final mensaje = Uri.encodeComponent(buffer.toString());
      final url = Uri.parse('https://wa.me/${AppConfig.whatsappNumero}?text=$mensaje');

      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        if (mounted) {
          carrito.limpiar();
          Navigator.popUntil(context, (route) => route.isFirst);
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir WhatsApp.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al procesar: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }
}
