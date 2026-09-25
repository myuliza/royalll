import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/app_config.dart';
import '../theme/app_theme.dart';

class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

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
      'respuesta':
          'Aceptamos múltiples formas de pago para tu total comodidad:\n\n'
          '• Efectivo contra entrega: Pagás en mano al momento de recibir tu pedido (válido en Asunción y Gran Asunción).\n'
          '• Transferencia Bancaria / Giros: Te enviamos los datos de nuestra cuenta al coordinar por WhatsApp.\n'
          '• Pago con QR / Tarjeta: Podés solicitar el código QR de pago antes de la entrega.',
    },
    {
      'categoria': 'Envíos',
      'icono': Icons.local_shipping_outlined,
      'pregunta': '¿Cuáles son los tiempos y políticas de envío?',
      'respuesta':
          'Realizamos envíos a todo el territorio nacional:\n\n'
          '• Asunción y Gran Asunción: Entregas en el día o en un plazo máximo de 24 horas hábiles a través de delivery propio.\n'
          '• Interior del país: Envíos por agencias de encomienda y transportadoras reconocidas (Aex, encomiendas exprés) en 24 a 48 horas hábiles con número de seguimiento para rastrear tu paquete.\n'
          '• El costo exacto se calcula y coordina por WhatsApp según tu zona o ciudad.',
    },
    {
      'categoria': 'Garantía',
      'icono': Icons.replay_outlined,
      'pregunta': '¿Cuál es la política de cambios o devoluciones de fundas?',
      'respuesta':
          'Tu satisfacción está garantizada en Royal:\n\n'
          '• Tenés hasta 7 días corridos a partir de la recepción para solicitar un cambio.\n'
          '• ¿Pediste un modelo de iPhone equivocado? Te realizamos el cambio de modelo sin inconvenientes, coordinando el delivery.\n'
          '• Requisitos: La funda debe estar sin uso, en perfectas condiciones y conservando su empaque original.\n'
          '• Garantía por fallas de fábrica: Si el producto presenta algún desperfecto de fabricación, te entregamos una unidad nueva de inmediato.',
    },
    {
      'categoria': 'Compatibilidad',
      'icono': Icons.phone_iphone_outlined,
      'pregunta': '¿Cómo verifico la compatibilidad con mi modelo de iPhone?',
      'respuesta':
          'Es fundamental confirmar el modelo exacto antes de ordenar, ya que los bordes y el módulo de cámaras varían:\n\n'
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
    final mensaje = Uri.encodeComponent('¡Hola ${AppConfig.appName}! Tengo una consulta sobre el catálogo de fundas.');
    final url = Uri.parse('https://wa.me/${AppConfig.whatsappNumero}?text=$mensaje');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondo,
      appBar: AppBar(
        title: const Text('Preguntas Frecuentes'),
        backgroundColor: AppColors.azul,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('faq').snapshots(),
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

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Banner informativo superior
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.azul, AppColors.azulClaro],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.azul.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.dorado.withValues(alpha: 0.25),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.help_center_outlined, color: Colors.white, size: 28),
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
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Acá respondemos las preguntas más comunes sobre compras, envíos y compatibilidad.',
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Lista de preguntas frecuentes
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: faqs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final item = faqs[i];
                    final icono = item['icono'] as IconData? ?? Icons.help_outline;

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.bordeSuave),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Theme(
                        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.fondo,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(icono, color: AppColors.azul, size: 20),
                          ),
                          title: Text(
                            item['pregunta'] ?? '',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textoPrincipal,
                            ),
                          ),
                          subtitle: Text(
                            item['categoria'] ?? 'Información',
                            style: const TextStyle(fontSize: 11, color: AppColors.textoSecundario),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.fondo,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  item['respuesta'] ?? '',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    height: 1.45,
                                    color: AppColors.textoSecundario,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Tarjeta de contacto WhatsApp directo
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.dorado.withValues(alpha: 0.5)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.support_agent, size: 36, color: AppColors.dorado),
                      const SizedBox(height: 8),
                      const Text(
                        '¿No encontraste lo que buscabas?',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Escribinos a nuestro WhatsApp y te atendemos de forma personalizada.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: AppColors.textoSecundario),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.chat_bubble_outline),
                          label: const Text('Contactar por WhatsApp'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.dorado,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: _abrirWhatsapp,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }
}
