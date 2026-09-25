/// Configuración global centralizada de la aplicación Royal.
class AppConfig {
  AppConfig._(); // Clase no instanciable

  /// Número de WhatsApp para atención al cliente en formato internacional (+595 991 345 198).
  ///
  /// FORMATO wa.me: código de país Paraguay (595) + número móvil sin el 0 inicial.
  /// Número local: 0991345198 -> Internacional: 595991345198
  static const String whatsappNumero = '595991345198';

  /// Nombre de la marca — aparece en los mensajes de WhatsApp y en la app.
  static const String appName = 'Royal';
}
