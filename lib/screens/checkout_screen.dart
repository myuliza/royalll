import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/app_config.dart';
import '../models/cupon.dart';
import '../models/venta.dart';
import '../utils/formatters.dart';
import '../providers/carrito_provider.dart';
import '../theme/app_theme.dart';
import '../theme/breakpoints.dart';
import '../widgets/ui/ui.dart';

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
    final royal = context.royal;
    final colorPrecio = context.esOscuro ? AppColors.doradoClaro : AppColors.azul;
    final tituloSeccion = TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: royal.textoPrincipal);

    final boton = SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
        icon: _procesando
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.azul),
              )
            : const Icon(Icons.chat_bubble_outline),
        label: Text(_procesando ? 'Procesando stock...' : 'Enviar pedido por WhatsApp'),
        onPressed: _procesando ? null : () => _confirmarPedido(carrito),
      ),
    );

    return PopScope(
      canPop: !_procesando,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: const Text('Confirmar pedido'),
          backgroundColor: royal.fondo,
          foregroundColor: royal.textoPrincipal,
          titleTextStyle: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: royal.textoPrincipal,
          ),
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: EdgeInsets.symmetric(
                horizontal: Breakpoints.paddingLateral(context),
                vertical: AppSpacing.lg,
              ),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text('Datos para el pedido', style: tituloSeccion),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _nombreController,
                                decoration: const InputDecoration(
                                  labelText: 'Tu nombre',
                                  prefixIcon: Icon(Icons.person_outline),
                                ),
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresá tu nombre' : null,
                              ),
                              const SizedBox(height: 16),
                              Text('Forma de pago', style: tituloSeccion),
                              ValueListenableBuilder<String>(
                                valueListenable: _formaPago,
                                builder: (context, value, _) => RadioGroup<String>(
                                  groupValue: value,
                                  onChanged: (v) {
                                    if (v != null) _formaPago.value = v;
                                  },
                                  child: const Column(
                                    children: [
                                      RadioListTile<String>(
                                        value: 'efectivo',
                                        title: Text('Efectivo'),
                                        secondary: Icon(Icons.payments_outlined),
                                      ),
                                      RadioListTile<String>(
                                        value: 'transferencia',
                                        title: Text('Transferencia'),
                                        secondary: Icon(Icons.account_balance_outlined),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        // Resumen del pedido (solo lectura)
                        AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text('Tu pedido', style: tituloSeccion),
                              const SizedBox(height: 8),
                              for (final item in carrito.items)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${item.cantidad}× ${item.producto.nombre}',
                                          style: TextStyle(color: royal.textoSecundario),
                                        ),
                                      ),
                                      Text(formatPrice(item.subtotal), style: TextStyle(color: royal.textoPrincipal)),
                                    ],
                                  ),
                                ),
                              if (carrito.cuponAplicado != null)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Cupón ${carrito.cuponAplicado!.codigo}',
                                          style: const TextStyle(color: AppColors.dorado),
                                        ),
                                      ),
                                      Text('-${formatPrice(carrito.descuento)}', style: const TextStyle(color: AppColors.dorado)),
                                    ],
                                  ),
                                ),
                              const Divider(height: 20),
                              Row(
                                children: [
                                  Expanded(child: Text('Total', style: tituloSeccion)),
                                  Text(
                                    formatPrice(carrito.total),
                                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: colorPrecio),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline, size: 16, color: royal.textoAtenuado),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Al confirmar se descontará el stock en Firebase y se abrirá WhatsApp para coordinar la entrega.',
                                style: TextStyle(fontSize: 12, color: royal.textoSecundario),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
          child: SafeArea(
            minimum: const EdgeInsets.all(16),
            child: Center(
              heightFactor: 1,
              child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 640), child: boton),
            ),
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
      // 1. TRANSACCIÓN RIGUROSA EN FIRESTORE: validar stock real y el código promocional, y descontar.
      // Firestore exige hacer todas las lecturas antes que cualquier escritura.
      final cuponAplicado = carrito.cuponAplicado;
      if (cuponAplicado != null && carrito.avisoCupon != null) {
        throw Exception('${carrito.avisoCupon} Quitá el código en el carrito para continuar.');
      }

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final productos = FirebaseFirestore.instance.collection('productos');

        // 1a. Lecturas: productos y código
        final lecturas = <(ItemCarrito, DocumentReference<Map<String, dynamic>>, DocumentSnapshot<Map<String, dynamic>>)>[];
        for (final item in carrito.items) {
          final docRef = productos.doc(item.producto.id);
          lecturas.add((item, docRef, await transaction.get(docRef)));
        }
        final cuponRef = cuponAplicado == null
            ? null
            : FirebaseFirestore.instance.collection('cupones').doc(cuponAplicado.codigo);
        final cuponSnap = cuponRef == null ? null : await transaction.get(cuponRef);

        // 1b. Validaciones con los datos reales del servidor
        for (final (item, _, snapshot) in lecturas) {
          if (!snapshot.exists) {
            throw Exception('El producto "${item.producto.nombre}" ya no existe en el catálogo.');
          }
          final stockActual = (snapshot.data()?['stock'] as num?)?.toInt() ?? 0;
          if (stockActual < item.cantidad) {
            throw Exception('Stock insuficiente para "${item.producto.nombre}". Quedan solo $stockActual unidades.');
          }
        }
        if (cuponSnap != null) {
          if (!cuponSnap.exists) {
            throw Exception('El código ${cuponAplicado!.codigo} ya no existe. Quitalo del carrito para continuar.');
          }
          final cuponActual = Cupon.fromMap({'codigo': cuponAplicado!.codigo, ...cuponSnap.data()!});
          final motivo = cuponActual.motivoInvalido(
            subtotal: carrito.subtotal,
            subtotalAplicable: carrito.subtotalAplicable,
          );
          if (motivo != null) throw Exception('$motivo Quitá el código en el carrito para continuar.');
        }

        // 1c. Escrituras: descontar stock y registrar el uso del código (+1)
        for (final (item, docRef, snapshot) in lecturas) {
          final stockActual = (snapshot.data()?['stock'] as num?)?.toInt() ?? 0;
          transaction.update(docRef, {'stock': stockActual - item.cantidad});
        }
        if (cuponRef != null) {
          transaction.update(cuponRef, {'usosActuales': FieldValue.increment(1)});
        }
      });

      // 3. Registrar la venta para el dashboard de empleados (colección `ventas`).
      // No se espera la respuesta: si falla (sin conexión o reglas sin publicar), el pedido sigue igual.
      FirebaseFirestore.instance
          .collection('ventas')
          .add(Venta.nuevaDesdeCarrito(
            carrito,
            cliente: _nombreController.text.trim(),
            formaPago: _formaPago.value,
          ))
          .catchError((Object e) {
        debugPrint('No se pudo registrar la venta: $e');
        return FirebaseFirestore.instance.collection('ventas').doc();
      });

      // 4. Armar mensaje de WhatsApp con formato centralizado
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
