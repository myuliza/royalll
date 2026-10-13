import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/app_config.dart';
import '../theme/app_theme.dart';
import '../theme/breakpoints.dart';
import '../widgets/ui/ui.dart';

class FaqScreen extends StatefulWidget {
  /// Solo para tests: muestra únicamente las preguntas estándar, sin Firestore.
  @visibleForTesting
  final bool sinFirebase;

  const FaqScreen({super.key, this.sinFirebase = false});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  // Lista estándar y completa de Preguntas Frecuentes
  static const List<Map<String, dynamic>> _faqsEstandar = [
    {
      'categoria': 'Pagos',
      'icono': Icons.payments_outlined,
      'pregunta': '¿Cuáles son los métodos de pago aceptados?',
      'respuesta': 'Aceptamos múltiples formas de pago para tu total comodidad:\n\n'
          '• Efectivo contra entrega: Pagás en mano al momento de recibir tu pedido (válido en Asunción y Gran Asunción).\n'
          '• Transferencia Bancaria / Giros: Te enviamos los datos de nuestra cuenta al coordinar por WhatsApp.\n'
          '• Pago con QR / Tarjeta: Podés solicitar el código QR de pago antes de la entrega.',
    },
    {
      'categoria': 'Envíos',
      'icono': Icons.local_shipping_outlined,
      'pregunta': '¿Cuáles son los tiempos y políticas de envío?',
      'respuesta': 'Realizamos envíos a todo el territorio nacional:\n\n'
          '• Asunción y Gran Asunción: Entregas en el día o en un plazo máximo de 24 horas hábiles a través de delivery propio.\n'
          '• Interior del país: Envíos por agencias de encomienda y transportadoras reconocidas (Aex, encomiendas exprés) en 24 a 48 horas hábiles con número de seguimiento para rastrear tu paquete.\n'
          '• El costo exacto se calcula y coordina por WhatsApp según tu zona o ciudad.',
    },
    {
      'categoria': 'Garantía',
      'icono': Icons.replay_outlined,
      'pregunta': '¿Cuál es la política de cambios o devoluciones de fundas?',
      'respuesta': 'Tu satisfacción está garantizada en Royal:\n\n'
          '• Tenés hasta 7 días corridos a partir de la recepción para solicitar un cambio.\n'
          '• ¿Pediste un modelo de iPhone equivocado? Te realizamos el cambio de modelo sin inconvenientes, coordinando el delivery.\n'
          '• Requisitos: La funda debe estar sin uso, en perfectas condiciones y conservando su empaque original.\n'
          '• Garantía por fallas de fábrica: Si el producto presenta algún desperfecto de fabricación, te entregamos una unidad nueva de inmediato.',
    },
    {
      'categoria': 'Compatibilidad',
      'icono': Icons.phone_iphone_outlined,
      'pregunta': '¿Cómo verifico la compatibilidad con mi modelo de iPhone?',
      'respuesta': 'Es fundamental confirmar el modelo exacto antes de ordenar, ya que los bordes y el módulo de cámaras varían:\n\n'
          '1. En tu iPhone, ingresá a: Configuración > General > Información.\n'
          '2. Revisá el campo "Nombre del modelo" (ej. iPhone 15 Pro, iPhone 14, iPhone 13 Pro Max).\n'
          '3. Tené en cuenta que los modelos Pro y Pro Max tienen dimensiones y orificios de cámara distintos a las versiones normales y Plus.\n'
          '4. En cada producto de nuestro catálogo detallamos los modelos compatibles. Ante cualquier duda, envianos un mensaje por WhatsApp y te asesoramos al instante.',
    },
    {
      'categoria': 'Personalización',
      'icono': Icons.brush_outlined,
      'pregunta': '¿Cómo funciona la personalización de fundas?',
      'respuesta':
          'En los modelos marcados como "Personalizables", podés agregar tu nombre, iniciales o diseño exclusivo. '
              'Una vez que selecciones la funda y presiones "Continuar al pedido", coordinamos por WhatsApp los detalles, '
              'tipografías y colores antes de enviarla a producción.',
    },
  ];

  Future<void> _abrirWhatsapp() async {
    final mensaje = Uri.encodeComponent(
        '¡Hola ${AppConfig.appName}! Tengo una consulta sobre el catálogo de fundas.');
    final url =
        Uri.parse('https://wa.me/${AppConfig.whatsappNumero}?text=$mensaje');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final royal = context.royal;
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: widget.sinFirebase
            ? null
            : FirebaseFirestore.instance.collection('faq').snapshots(),
        builder: (context, snapshot) {
          // Si Firebase tiene preguntas personalizadas cargadas, las combinamos; sino usamos las estándar
          List<Map<String, dynamic>> faqs = List.from(_faqsEstandar);

          if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
            final docsFromDb = snapshot.data!.docs.map((d) {
              final data = d.data() as Map<String, dynamic>;
              return {
                'categoria': data['categoria'] ?? 'General',
                'icono': Icons.help_outline,
                'pregunta': data['pregunta'] ?? '',
                'respuesta': data['respuesta'] ?? '',
              };
            }).toList();

            // Agregar preguntas de Firebase que no estén ya en la lista estándar
            for (final doc in docsFromDb) {
              if (doc['pregunta'].toString().isNotEmpty &&
                  !faqs.any((f) => f['pregunta'] == doc['pregunta'])) {
                faqs.add(doc);
              }
            }
          }

          final lateral = Breakpoints.paddingLateral(context);

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
                lateral, AppSpacing.xl, lateral, AppSpacing.xxl),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SectionHeader(
                      titulo: 'Preguntas frecuentes',
                      subtitulo: 'Compras, envíos, garantía y compatibilidad.',
                      grande: true,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    // Banner informativo superior
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.lg + 2),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.azul, AppColors.azulClaro],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                        border: Border.all(
                            color: AppColors.dorado.withValues(alpha: 0.25)),
                        boxShadow:
                            AppShadows.suave(Theme.of(context).brightness),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.dorado.withValues(alpha: 0.25),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.help_center_outlined,
                                color: Colors.white, size: 28),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '¿Tenés dudas?',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 3),
                                Text(
                                  'Acá respondemos las preguntas más comunes sobre compras, envíos y compatibilidad.',
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Lista de preguntas frecuentes (tarjetas expandibles)
                    for (final item in faqs) ...[
                      _TarjetaFaq(item: item),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    const SizedBox(height: AppSpacing.lg),

                    // Tarjeta de contacto WhatsApp directo
                    AppCard(
                      padding: const EdgeInsets.all(AppSpacing.xl - 4),
                      child: Column(
                        children: [
                          const Icon(Icons.support_agent,
                              size: 40, color: AppColors.dorado),
                          const SizedBox(height: 8),
                          Text(
                            '¿No encontraste lo que buscabas?',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: royal.textoPrincipal),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Escribinos a nuestro WhatsApp y te atendemos de forma personalizada.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 13, color: royal.textoSecundario),
                          ),
                          const SizedBox(height: 14),
                          FilledButton.icon(
                            icon: const Icon(Icons.chat_bubble_outline),
                            label: const Text('Contactar por WhatsApp'),
                            onPressed: _abrirWhatsapp,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TarjetaFaq extends StatelessWidget {
  final Map<String, dynamic> item;
  const _TarjetaFaq({required this.item});

  @override
  Widget build(BuildContext context) {
    final royal = context.royal;
    final icono = item['icono'] as IconData? ?? Icons.help_outline;
    final forma = RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg));

    return Container(
      decoration: BoxDecoration(
        color: royal.superficie,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: royal.borde),
        boxShadow: AppShadows.suave(Theme.of(context).brightness),
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        shape: forma,
        collapsedShape: forma,
        tilePadding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 6),
        iconColor: AppColors.dorado,
        collapsedIconColor: royal.textoSecundario,
        expansionAnimationStyle:
            const AnimationStyle(duration: AppDurations.media),
        leading: Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: AppColors.dorado.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icono, color: AppColors.dorado, size: 20),
        ),
        title: Text(
          item['pregunta'] ?? '',
          style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: royal.textoPrincipal),
        ),
        subtitle: Text(
          item['categoria'] ?? 'Información',
          style: TextStyle(fontSize: 11, color: royal.textoSecundario),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: royal.superficieAlta,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Text(
                item['respuesta'] ?? '',
                style: TextStyle(
                    fontSize: 13, height: 1.5, color: royal.textoSecundario),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
