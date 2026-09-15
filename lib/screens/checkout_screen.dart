import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/carrito_provider.dart';

/// Número de WhatsApp de Royal en formato internacional, sin '+' ni espacios.
/// Ej: Paraguay = 595981234567
const String kWhatsappNumeroRoyal = '595981234567'; // TODO: reemplazar por el número real

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _nombreController = TextEditingController();
  final _formaPago = ValueNotifier<String>('efectivo');
  final _formKey = GlobalKey<FormState>();

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
                    RadioListTile(
                      value: 'efectivo',
                      groupValue: value,
                      title: const Text('Efectivo'),
                      onChanged: (v) => _formaPago.value = v!,
                    ),
                    RadioListTile(
                      value: 'transferencia',
                      groupValue: value,
                      title: const Text('Transferencia'),
                      onChanged: (v) => _formaPago.value = v!,
                    ),
                  ],
                ),
              ),
              const Spacer(),
              const Text(
                'Al confirmar se abrirá WhatsApp con el pedido ya armado para coordinar la entrega y el pago.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('Enviar pedido por WhatsApp'),
                  onPressed: () => _confirmarPedido(carrito),
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

    final buffer = StringBuffer();
    buffer.writeln('¡Hola Royal! Quiero hacer este pedido:');
    buffer.writeln();
    for (final item in carrito.items) {
      buffer.writeln('• ${item.cantidad}x ${item.producto.nombre} — ${item.producto.precioFormateado} c/u');
    }
    buffer.writeln();
    if (carrito.cuponAplicado != null) {
      buffer.writeln('Cupón aplicado: ${carrito.cuponAplicado!.codigo}');
    }
    buffer.writeln('Total: ${carrito.total.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')} Gs');
    buffer.writeln();
    buffer.writeln('Nombre: ${_nombreController.text.trim()}');
    buffer.writeln('Forma de pago: ${_formaPago.value == 'efectivo' ? 'Efectivo' : 'Transferencia'}');

    final mensaje = Uri.encodeComponent(buffer.toString());
    final url = Uri.parse('https://wa.me/$kWhatsappNumeroRoyal?text=$mensaje');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
      if (mounted) {
        carrito.limpiar();
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir WhatsApp')),
      );
    }
  }
}
