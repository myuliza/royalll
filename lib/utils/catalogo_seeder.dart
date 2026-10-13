import 'package:cloud_firestore/cloud_firestore.dart';

class CatalogoSeeder {
  /// Lista de fundas basada exclusivamente en los archivos presentes
  /// en la carpeta assets/fundas/ (extensiÃ³n .jpg).
  static final List<Map<String, dynamic>> catalogoSemilla = [
    // â”€â”€â”€ iPhone 11 â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    {
      'nombre': 'Funda iPhone 11 Negro',
      'categoria': 'solido',
      'codigoColor': 'Negro',
      'modelosCompatibles': ["iPhone 11"],
      'precio': 90000,
      'colorHex': '#000000',
      'personalizable': false,
      'stock': 20,
      'fotosUrls': ["assets/fundas/funda_iphone_11_negro.jpg"],
      'imagenUrl': 'assets/fundas/funda_iphone_11_negro.jpg',
      'enDescuento': true,
      'porcentajeDescuento': 15,
    },
    {
      'nombre': 'Funda iPhone 11 Pro DualTek Gris',
      'categoria': 'dualtek',
      'codigoColor': 'Gris',
      'modelosCompatibles': ["iPhone 11 Pro"],
      'precio': 110000,
      'colorHex': '#64748B',
      'personalizable': false,
      'stock': 15,
      'fotosUrls': ["assets/fundas/funda_iphone_11_pro_dualtek_gris.jpg"],
      'imagenUrl': 'assets/fundas/funda_iphone_11_pro_dualtek_gris.jpg',
      'enDescuento': false,
      'porcentajeDescuento': 0,
    },
    {
      'nombre': 'Funda iPhone 11 Pro Max DualTek Negro',
      'categoria': 'dualtek',
      'codigoColor': 'Negro',
      'modelosCompatibles': ["iPhone 11 Pro Max"],
      'precio': 115000,
      'colorHex': '#000000',
      'personalizable': false,
      'stock': 15,
      'fotosUrls': ["assets/fundas/funda_iphone_11_pro_max_dualtek_negro.jpg"],
      'imagenUrl': 'assets/fundas/funda_iphone_11_pro_max_dualtek_negro.jpg',
      'enDescuento': false,
      'porcentajeDescuento': 0,
    },
    {
      'nombre': 'Funda iPhone 11 Pro Rojo',
      'categoria': 'solido',
      'codigoColor': 'Rojo',
      'modelosCompatibles': ["iPhone 11 Pro"],
      'precio': 95000,
      'colorHex': '#DC2626',
      'personalizable': false,
      'stock': 18,
      'fotosUrls': ["assets/fundas/funda_iphone_11_pro_rojo.jpg"],
      'imagenUrl': 'assets/fundas/funda_iphone_11_pro_rojo.jpg',
      'enDescuento': true,
      'porcentajeDescuento': 10,
    },

    // â”€â”€â”€ iPhone 13 â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    {
      'nombre': 'Funda iPhone 13 Cuero Lila',
      'categoria': 'cuero',
      'codigoColor': 'Lila',
      'modelosCompatibles': ["iPhone 13"],
      'precio': 120000,
      'colorHex': '#7E22CE',
      'personalizable': false,
      'stock': 12,
      'fotosUrls': ["assets/fundas/funda_iphone_13_cuero_lila.jpg"],
      'imagenUrl': 'assets/fundas/funda_iphone_13_cuero_lila.jpg',
      'enDescuento': false,
      'porcentajeDescuento': 0,
    },
    {
      'nombre': 'Funda iPhone 13 Cuero Verde',
      'categoria': 'cuero',
      'codigoColor': 'Verde',
      'modelosCompatibles': ["iPhone 13"],
      'precio': 120000,
      'colorHex': '#16A34A',
      'personalizable': false,
      'stock': 12,
      'fotosUrls': ["assets/fundas/funda_iphone_13_cuero_verde.jpg"],
      'imagenUrl': 'assets/fundas/funda_iphone_13_cuero_verde.jpg',
      'enDescuento': false,
      'porcentajeDescuento': 0,
    },
    {
      'nombre': 'Funda iPhone 13 Pro DualTek Nightfall',
      'categoria': 'dualtek',
      'codigoColor': 'Nightfall',
      'modelosCompatibles': ["iPhone 13 Pro"],
      'precio': 115000,
      'colorHex': '#0B2545',
      'personalizable': false,
      'stock': 14,
      'fotosUrls': ["assets/fundas/funda_iphone_13_pro_dualtek_nightfall.jpg"],
      'imagenUrl': 'assets/fundas/funda_iphone_13_pro_dualtek_nightfall.jpg',
      'enDescuento': false,
      'porcentajeDescuento': 0,
    },
    {
      'nombre': 'Funda iPhone 13 Silicona Azul',
      'categoria': 'silicona',
      'codigoColor': 'Azul',
      'modelosCompatibles': ["iPhone 13"],
      'precio': 95000,
      'colorHex': '#0B2545',
      'personalizable': false,
      'stock': 24,
      'fotosUrls': ["assets/fundas/funda_iphone_13_silicona_azul.jpg"],
      'imagenUrl': 'assets/fundas/funda_iphone_13_silicona_azul.jpg',
      'enDescuento': false,
      'porcentajeDescuento': 0,
    },
    {
      'nombre': 'Funda iPhone 13 Silicona Rojo',
      'categoria': 'silicona',
      'codigoColor': 'Rojo',
      'modelosCompatibles': ["iPhone 13"],
      'precio': 90000,
      'colorHex': '#DC2626',
      'personalizable': false,
      'stock': 24,
      'fotosUrls': ["assets/fundas/funda_iphone_13_silicona_rojo.jpg"],
      'imagenUrl': 'assets/fundas/funda_iphone_13_silicona_rojo.jpg',
      'enDescuento': false,
      'porcentajeDescuento': 0,
    },
    {
      'nombre': 'Funda iPhone 13 Silicona Rosa',
      'categoria': 'silicona',
      'codigoColor': 'Rosa',
      'modelosCompatibles': ["iPhone 13"],
      'precio': 90000,
      'colorHex': '#F472B6',
      'personalizable': false,
      'stock': 24,
      'fotosUrls': ["assets/fundas/funda_iphone_13_silicona_rosa.jpg"],
      'imagenUrl': 'assets/fundas/funda_iphone_13_silicona_rosa.jpg',
      'enDescuento': false,
      'porcentajeDescuento': 0,
    },
    {
      'nombre': 'Funda iPhone 13 Transparente',
      'categoria': 'transparente',
      'codigoColor': 'transparente 001',
      'modelosCompatibles': ["iPhone 13"],
      'precio': 85000,
      'colorHex': '#E5E7EB',
      'personalizable': false,
      'stock': 25,
      'fotosUrls': ["assets/fundas/funda_iphone_13_transparente.jpg"],
      'imagenUrl': 'assets/fundas/funda_iphone_13_transparente.jpg',
      'enDescuento': false,
      'porcentajeDescuento': 0,
    },
    {
      'nombre': 'Funda iPhone 13 Transparente TPU',
      'categoria': 'transparente',
      'codigoColor': 'transparente TPU',
      'modelosCompatibles': ["iPhone 13"],
      'precio': 80000,
      'colorHex': '#E5E7EB',
      'personalizable': false,
      'stock': 25,
      'fotosUrls': ["assets/fundas/funda_iphone_13_transparente_tpu.jpg"],
      'imagenUrl': 'assets/fundas/funda_iphone_13_transparente_tpu.jpg',
      'enDescuento': false,
      'porcentajeDescuento': 0,
    },

    // â”€â”€â”€ iPhone 14 â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    {
      'nombre': 'Funda iPhone 14 Azul',
      'categoria': 'solido',
      'codigoColor': 'Azul',
      'modelosCompatibles': ["iPhone 14"],
      'precio': 95000,
      'colorHex': '#0B2545',
      'personalizable': false,
      'stock': 26,
      'fotosUrls': ["assets/fundas/funda_iphone_14_azul.jpg"],
      'imagenUrl': 'assets/fundas/funda_iphone_14_azul.jpg',
      'enDescuento': true,
      'porcentajeDescuento': 15,
    },
    {
      'nombre': 'Funda iPhone 14 MagSafe Azul',
      'categoria': 'magsafe',
      'codigoColor': 'Azul',
      'modelosCompatibles': ["iPhone 14"],
      'precio': 130000,
      'colorHex': '#0B2545',
      'personalizable': false,
      'stock': 18,
      'fotosUrls': ["assets/fundas/funda_iphone_14_magsafe_azul.jpg"],
      'imagenUrl': 'assets/fundas/funda_iphone_14_magsafe_azul.jpg',
      'enDescuento': false,
      'porcentajeDescuento': 0,
    },
    {
      'nombre': 'Funda iPhone 14 MagSafe Verde',
      'categoria': 'magsafe',
      'codigoColor': 'Verde',
      'modelosCompatibles': ["iPhone 14"],
      'precio': 130000,
      'colorHex': '#16A34A',
      'personalizable': false,
      'stock': 18,
      'fotosUrls': ["assets/fundas/funda_iphone_14_magsafe_verde.jpg"],
      'imagenUrl': 'assets/fundas/funda_iphone_14_magsafe_verde.jpg',
      'enDescuento': false,
      'porcentajeDescuento': 0,
    },
    {
      'nombre': 'Funda iPhone 14 Negro',
      'categoria': 'solido',
      'codigoColor': 'Negro',
      'modelosCompatibles': ["iPhone 14"],
      'precio': 90000,
      'colorHex': '#000000',
      'personalizable': false,
      'stock': 26,
      'fotosUrls': ["assets/fundas/funda_iphone_14_negro.jpg"],
      'imagenUrl': 'assets/fundas/funda_iphone_14_negro.jpg',
      'enDescuento': true,
      'porcentajeDescuento': 15,
    },
    {
      'nombre': 'Funda iPhone 14 Plus DualTek Antioch',
      'categoria': 'dualtek',
      'codigoColor': 'Antioch',
      'modelosCompatibles': ["iPhone 14 Plus"],
      'precio': 120000,
      'colorHex': '#334155',
      'personalizable': false,
      'stock': 14,
      'fotosUrls': ["assets/fundas/funda_iphone_14_plus_dualtek_antioch.jpg"],
      'imagenUrl': 'assets/fundas/funda_iphone_14_plus_dualtek_antioch.jpg',
      'enDescuento': false,
      'porcentajeDescuento': 0,
    },
    {
      'nombre': 'Funda iPhone 14 Rojo',
      'categoria': 'solido',
      'codigoColor': 'Rojo',
      'modelosCompatibles': ["iPhone 14"],
      'precio': 90000,
      'colorHex': '#DC2626',
      'personalizable': false,
      'stock': 26,
      'fotosUrls': ["assets/fundas/funda_iphone_14_rojo.jpg"],
      'imagenUrl': 'assets/fundas/funda_iphone_14_rojo.jpg',
      'enDescuento': true,
      'porcentajeDescuento': 15,
    },
    {
      'nombre': 'Funda iPhone 14 Rosa',
      'categoria': 'solido',
      'codigoColor': 'Rosa',
      'modelosCompatibles': ["iPhone 14"],
      'precio': 90000,
      'colorHex': '#F472B6',
      'personalizable': false,
      'stock': 26,
      'fotosUrls': ["assets/fundas/funda_iphone_14_rosa.jpg"],
      'imagenUrl': 'assets/fundas/funda_iphone_14_rosa.jpg',
      'enDescuento': true,
      'porcentajeDescuento': 15,
    },
    {
      'nombre': 'Funda iPhone 14 Transparente',
      'categoria': 'transparente',
      'codigoColor': 'transparente 002',
      'modelosCompatibles': ["iPhone 14"],
      'precio': 90000,
      'colorHex': '#E5E7EB',
      'personalizable': false,
      'stock': 25,
      'fotosUrls': ["assets/fundas/funda_iphone_14_transparente.jpg"],
      'imagenUrl': 'assets/fundas/funda_iphone_14_transparente.jpg',
      'enDescuento': true,
      'porcentajeDescuento': 10,
    },

    // â”€â”€â”€ iPhone 15 â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    {
      'nombre': 'Funda iPhone 15 Amarillo',
      'categoria': 'solido',
      'codigoColor': 'Amarillo',
      'modelosCompatibles': ["iPhone 15"],
      'precio': 90000,
      'colorHex': '#FBBF24',
      'personalizable': false,
      'stock': 28,
      'fotosUrls': ["assets/fundas/funda_iphone_15_amarillo.jpg"],
      'imagenUrl': 'assets/fundas/funda_iphone_15_amarillo.jpg',
      'enDescuento': false,
      'porcentajeDescuento': 0,
    },
    {
      'nombre': 'Funda iPhone 15 Azul',
      'categoria': 'solido',
      'codigoColor': 'Azul',
      'modelosCompatibles': ["iPhone 15"],
      'precio': 95000,
      'colorHex': '#0B2545',
      'personalizable': false,
      'stock': 28,
      'fotosUrls': ["assets/fundas/funda_iphone_15_azul.jpg"],
      'imagenUrl': 'assets/fundas/funda_iphone_15_azul.jpg',
      'enDescuento': false,
      'porcentajeDescuento': 0,
    },
    {
      'nombre': 'Funda iPhone 15 Lila',
      'categoria': 'solido',
      'codigoColor': 'Lila',
      'modelosCompatibles': ["iPhone 15"],
      'precio': 90000,
      'colorHex': '#7E22CE',
      'personalizable': false,
      'stock': 28,
      'fotosUrls': ["assets/fundas/funda_iphone_15_lila.jpg"],
      'imagenUrl': 'assets/fundas/funda_iphone_15_lila.jpg',
      'enDescuento': false,
      'porcentajeDescuento': 0,
    },
    {
      'nombre': 'Funda iPhone 15 Negro',
      'categoria': 'solido',
      'codigoColor': 'Negro',
      'modelosCompatibles': ["iPhone 15"],
      'precio': 90000,
      'colorHex': '#000000',
      'personalizable': false,
      'stock': 28,
      'fotosUrls': ["assets/fundas/funda_iphone_15_negro.jpg"],
      'imagenUrl': 'assets/fundas/funda_iphone_15_negro.jpg',
      'enDescuento': false,
      'porcentajeDescuento': 0,
    },
    {
      'nombre': 'Funda iPhone 15 Plus MagSafe Azul',
      'categoria': 'magsafe',
      'codigoColor': 'Azul',
      'modelosCompatibles': ["iPhone 15 Plus"],
      'precio': 135000,
      'colorHex': '#0B2545',
      'personalizable': false,
      'stock': 18,
      'fotosUrls': ["assets/fundas/funda_iphone_15_plus_magsafe_azul.jpg"],
      'imagenUrl': 'assets/fundas/funda_iphone_15_plus_magsafe_azul.jpg',
      'enDescuento': false,
      'porcentajeDescuento': 0,
    },
    {
      'nombre': 'Funda iPhone 15 Plus MagSafe Transparente',
      'categoria': 'magsafe',
      'codigoColor': 'transparente 003',
      'modelosCompatibles': ["iPhone 15 Plus"],
      'precio': 135000,
      'colorHex': '#E5E7EB',
      'personalizable': false,
      'stock': 18,
      'fotosUrls': ["assets/fundas/funda_iphone_15_plus_magsafe_transparente.jpg"],
      'imagenUrl': 'assets/fundas/funda_iphone_15_plus_magsafe_transparente.jpg',
      'enDescuento': false,
      'porcentajeDescuento': 0,
    },
    {
      'nombre': 'Funda iPhone 15 Pro Max DualTek Negro',
      'categoria': 'dualtek',
      'codigoColor': 'Negro',
      'modelosCompatibles': ["iPhone 15 Pro Max"],
      'precio': 130000,
      'colorHex': '#000000',
      'personalizable': false,
      'stock': 15,
      'fotosUrls': ["assets/fundas/funda_iphone_15_pro_max_dualtek_negro.jpg"],
      'imagenUrl': 'assets/fundas/funda_iphone_15_pro_max_dualtek_negro.jpg',
      'enDescuento': false,
      'porcentajeDescuento': 0,
    },
    {
      'nombre': 'Funda iPhone 15 Pro Max Slim Shell Transparente',
      'categoria': 'transparente',
      'codigoColor': 'transparente 004',
      'modelosCompatibles': ["iPhone 15 Pro Max"],
      'precio': 115000,
      'colorHex': '#E5E7EB',
      'personalizable': false,
      'stock': 20,
      'fotosUrls': ["assets/fundas/funda_iphone_15_pro_max_slim_shell_transparente.jpg"],
      'imagenUrl': 'assets/fundas/funda_iphone_15_pro_max_slim_shell_transparente.jpg',
      'enDescuento': false,
      'porcentajeDescuento': 0,
    },
    {
      'nombre': 'Funda iPhone 15 Rojo',
      'categoria': 'solido',
      'codigoColor': 'Rojo',
      'modelosCompatibles': ["iPhone 15"],
      'precio': 90000,
      'colorHex': '#DC2626',
      'personalizable': false,
      'stock': 28,
      'fotosUrls': ["assets/fundas/funda_iphone_15_rojo.jpg"],
      'imagenUrl': 'assets/fundas/funda_iphone_15_rojo.jpg',
      'enDescuento': false,
      'porcentajeDescuento': 0,
    },
    {
      'nombre': 'Funda iPhone 15 Transparente',
      'categoria': 'transparente',
      'codigoColor': 'transparente 005',
      'modelosCompatibles': ["iPhone 15"],
      'precio': 90000,
      'colorHex': '#E5E7EB',
      'personalizable': false,
      'stock': 25,
      'fotosUrls': ["assets/fundas/funda_iphone_15_transparente.jpg"],
      'imagenUrl': 'assets/fundas/funda_iphone_15_transparente.jpg',
      'enDescuento': false,
      'porcentajeDescuento': 0,
    },

    // â”€â”€â”€ iPhone 16 â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    {
      'nombre': 'Funda iPhone 16 Pro Max Negro',
      'categoria': 'solido',
      'codigoColor': 'Negro',
      'modelosCompatibles': ["iPhone 16 Pro Max"],
      'precio': 110000,
      'colorHex': '#000000',
      'personalizable': false,
      'stock': 20,
      'fotosUrls': ["assets/fundas/funda_iphone_16_pro_max_negro.jpg"],
      'imagenUrl': 'assets/fundas/funda_iphone_16_pro_max_negro.jpg',
      'enDescuento': false,
      'porcentajeDescuento': 0,
    },
    {
      'nombre': 'Funda iPhone 16 Verde',
      'categoria': 'solido',
      'codigoColor': 'Verde',
      'modelosCompatibles': ["iPhone 16"],
      'precio': 100000,
      'colorHex': '#16A34A',
      'personalizable': false,
      'stock': 22,
      'fotosUrls': ["assets/fundas/funda_iphone_16_verde.jpg"],
      'imagenUrl': 'assets/fundas/funda_iphone_16_verde.jpg',
      'enDescuento': false,
      'porcentajeDescuento': 0,
    },

    // â”€â”€â”€ iPhone 17 â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    {
      'nombre': 'Funda iPhone 17 Azul',
      'categoria': 'solido',
      'codigoColor': 'Azul',
      'modelosCompatibles': ["iPhone 17"],
      'precio': 105000,
      'colorHex': '#0B2545',
      'personalizable': false,
      'stock': 32,
      'fotosUrls': ["assets/fundas/funda_iphone_17_azul.jpg"],
      'imagenUrl': 'assets/fundas/funda_iphone_17_azul.jpg',
      'enDescuento': true,
      'porcentajeDescuento': 15,
    },
    {
      'nombre': 'Funda iPhone 17 MagSafe Lavanda',
      'categoria': 'magsafe',
      'codigoColor': 'Lavanda',
      'modelosCompatibles': ["iPhone 17"],
      'precio': 140000,
      'colorHex': '#7C3AED',
      'personalizable': false,
      'stock': 18,
      'fotosUrls': ["assets/fundas/funda_iphone_17_magsafe_lavanda.jpg"],
      'imagenUrl': 'assets/fundas/funda_iphone_17_magsafe_lavanda.jpg',
      'enDescuento': false,
      'porcentajeDescuento': 0,
    },
    {
      'nombre': 'Funda iPhone 17 MagSafe Purple Fog',
      'categoria': 'magsafe',
      'codigoColor': 'Purple Fog',
      'modelosCompatibles': ["iPhone 17"],
      'precio': 140000,
      'colorHex': '#7E22CE',
      'personalizable': false,
      'stock': 18,
      'fotosUrls': ["assets/fundas/funda_iphone_17_magsafe_purple_fog.jpg"],
      'imagenUrl': 'assets/fundas/funda_iphone_17_magsafe_purple_fog.jpg',
      'enDescuento': false,
      'porcentajeDescuento': 0,
    },
    {
      'nombre': 'Funda iPhone 17 Pro MagSafe Verde',
      'categoria': 'magsafe',
      'codigoColor': 'Verde',
      'modelosCompatibles': ["iPhone 17 Pro"],
      'precio': 145000,
      'colorHex': '#16A34A',
      'personalizable': false,
      'stock': 15,
      'fotosUrls': ["assets/fundas/funda_iphone_17_pro_magsafe_verde.jpg"],
      'imagenUrl': 'assets/fundas/funda_iphone_17_pro_magsafe_verde.jpg',
      'enDescuento': false,
      'porcentajeDescuento': 0,
    },
    {
      'nombre': 'Funda iPhone 17 Pro Max Negro',
      'categoria': 'solido',
      'codigoColor': 'Negro',
      'modelosCompatibles': ["iPhone 17 Pro Max"],
      'precio': 115000,
      'colorHex': '#000000',
      'personalizable': false,
      'stock': 20,
      'fotosUrls': ["assets/fundas/funda_iphone_17_pro_max_negro.jpg"],
      'imagenUrl': 'assets/fundas/funda_iphone_17_pro_max_negro.jpg',
      'enDescuento': true,
      'porcentajeDescuento': 15,
    },
    {
      'nombre': 'Funda iPhone 17 Pro Negro',
      'categoria': 'solido',
      'codigoColor': 'Negro',
      'modelosCompatibles': ["iPhone 17 Pro"],
      'precio': 110000,
      'colorHex': '#000000',
      'personalizable': false,
      'stock': 20,
      'fotosUrls': ["assets/fundas/funda_iphone_17_pro_negro.jpg"],
      'imagenUrl': 'assets/fundas/funda_iphone_17_pro_negro.jpg',
      'enDescuento': true,
      'porcentajeDescuento': 15,
    },
    {
      'nombre': 'Funda iPhone 17 Rojo',
      'categoria': 'solido',
      'codigoColor': 'Rojo',
      'modelosCompatibles': ["iPhone 17"],
      'precio': 100000,
      'colorHex': '#DC2626',
      'personalizable': false,
      'stock': 32,
      'fotosUrls': ["assets/fundas/funda_iphone_17_rojo.jpg"],
      'imagenUrl': 'assets/fundas/funda_iphone_17_rojo.jpg',
      'enDescuento': true,
      'porcentajeDescuento': 15,
    },
    {
      'nombre': 'Funda iPhone 17 Verde',
      'categoria': 'solido',
      'codigoColor': 'Verde',
      'modelosCompatibles': ["iPhone 17"],
      'precio': 100000,
      'colorHex': '#16A34A',
      'personalizable': false,
      'stock': 32,
      'fotosUrls': ["assets/fundas/funda_iphone_17_verde.jpg"],
      'imagenUrl': 'assets/fundas/funda_iphone_17_verde.jpg',
      'enDescuento': true,
      'porcentajeDescuento': 15,
    },

    // â”€â”€â”€ iPhone 18 â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    {
      'nombre': 'Funda iPhone 18 Pro Max Negro',
      'categoria': 'solido',
      'codigoColor': 'Negro',
      'modelosCompatibles': ["iPhone 18 Pro Max"],
      'precio': 130000,
      'colorHex': '#000000',
      'personalizable': false,
      'stock': 15,
      'fotosUrls': ["assets/fundas/funda_iphone_18_pro_max_negro.jpg"],
      'imagenUrl': 'assets/fundas/funda_iphone_18_pro_max_negro.jpg',
      'enDescuento': false,
      'porcentajeDescuento': 0,
    },
    {
      'nombre': 'Funda iPhone 18 Pro Max Transparente',
      'categoria': 'transparente',
      'codigoColor': 'transparente 006',
      'modelosCompatibles': ["iPhone 18 Pro Max"],
      'precio': 125000,
      'colorHex': '#E5E7EB',
      'personalizable': false,
      'stock': 15,
      'fotosUrls': ["assets/fundas/funda_iphone_18_pro_max_transparente.jpg"],
      'imagenUrl': 'assets/fundas/funda_iphone_18_pro_max_transparente.jpg',
      'enDescuento': false,
      'porcentajeDescuento': 0,
    },
  ];

  /// Limpia los documentos repetidos en la colecciÃ³n `productos`
  /// conservando Ãºnicamente una instancia por nombre.
  static Future<int> limpiarDuplicados() async {
    final col = FirebaseFirestore.instance.collection('productos');
    final snapshot = await col.get();
    final Map<String, String> vistos = {};
    int eliminados = 0;

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final nombre = (data['nombre'] ?? '').toString().trim().toLowerCase();
      if (nombre.isEmpty) continue;

      if (vistos.containsKey(nombre)) {
        await col.doc(doc.id).delete();
        eliminados++;
      } else {
        vistos[nombre] = doc.id;
      }
    }

    return eliminados;
  }

  /// Inicializa datos semilla si la colecciÃ³n estÃ¡ vacÃ­a.
  static Future<int> inicializarDatosSemillaSiVacio() async {
    final col = FirebaseFirestore.instance.collection('productos');
    final snapshot = await col.get();

    final Set<String> existentes = snapshot.docs
        .map((d) => (d.data()['nombre'] ?? '').toString().trim().toLowerCase())
        .toSet();

    int insertados = 0;
    for (final item in catalogoSemilla) {
      final n = (item['nombre'] as String).toLowerCase();
      if (!existentes.contains(n)) {
        await col.add(item);
        insertados++;
      }
    }

    return insertados;
  }

  /// Sincroniza y actualiza todos los documentos del catÃ¡logo en Firebase:
  /// Si la foto tiene extensiÃ³n .png o no existe, la reemplaza por la foto oficial .jpg.
  static Future<int> sincronizarFotosYNomenclatura() async {
    final col = FirebaseFirestore.instance.collection('productos');
    final snapshot = await col.get();

    // Crear mapa rÃ¡pido: nombre en minÃºsculas -> item de catalogoSemilla
    final Map<String, Map<String, dynamic>> semillasPorNombre = {};
    for (final item in catalogoSemilla) {
      semillasPorNombre[(item['nombre'] as String).toLowerCase().trim()] = item;
    }

    int actualizados = 0;
    int idx = 0;

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final rawNombre = (data['nombre'] ?? '').toString();
      final refSeed = semillasPorNombre[rawNombre.toLowerCase().trim()] ??
          catalogoSemilla[idx % catalogoSemilla.length];

      final fotos = data['fotosUrls'];
      bool tieneFotoValida = false;
      if (fotos is List && fotos.isNotEmpty) {
        final primera = fotos.first.toString().trim();
        // Si termina en .png o no termina en .jpg, no es vÃ¡lida
        if (primera.isNotEmpty && primera.endsWith('.jpg')) {
          tieneFotoValida = true;
        }
      }

      final updates = <String, dynamic>{
        'nombre': refSeed['nombre'],
        'categoria': refSeed['categoria'],
        'colorHex': refSeed['colorHex'],
        'codigoColor': refSeed['codigoColor'],
        'modelosCompatibles': refSeed['modelosCompatibles'],
      };

      if (!tieneFotoValida) {
        updates['fotosUrls'] = refSeed['fotosUrls'];
        updates['imagenUrl'] = refSeed['imagenUrl'];
      }

      await col.doc(doc.id).update(updates);
      actualizados++;
      idx++;
    }

    if (snapshot.docs.isEmpty) {
      actualizados = await inicializarDatosSemillaSiVacio();
    }

    return actualizados;
  }

  /// Limpia y reemplaza toda la colecciÃ³n de Firestore con las 42 fundas oficiales de assets/fundas/.
  static Future<int> restablecerCatalogoOficial() async {
    final col = FirebaseFirestore.instance.collection('productos');
    final snapshot = await col.get();

    for (final doc in snapshot.docs) {
      await col.doc(doc.id).delete();
    }

    int insertados = 0;
    for (final item in catalogoSemilla) {
      await col.add(item);
      insertados++;
    }

    return insertados;
  }
}

