import 'package:flutter/material.dart';

/// Convierte '#RRGGBB' en [Color]; si no se puede, devuelve [porDefecto].
Color colorDesdeHex(String hex, {Color porDefecto = Colors.grey}) {
  try {
    final buffer = StringBuffer();
    if (hex.length == 6 || hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  } catch (_) {
    return porDefecto;
  }
}

/// Indica si un color es muy claro (para dibujarle un borde visible).
bool esColorClaro(Color c) => c.computeLuminance() > 0.8;

/// Datos visuales de cada categoría de funda.
class CategoriaInfo {
  final String id;
  final String etiqueta;
  final IconData icono;
  final Color color;
  const CategoriaInfo(this.id, this.etiqueta, this.icono, this.color);
}

class Categorias {
  static const todas = [
    CategoriaInfo('solido', 'Sólido', Icons.phone_iphone_rounded, Color(0xFF0369A1)),
    CategoriaInfo('silicona', 'Silicona', Icons.water_drop_outlined, Color(0xFF0F766E)),
    CategoriaInfo('transparente', 'Transparente', Icons.blur_on_rounded, Color(0xFF64748B)),
    CategoriaInfo('cuero', 'Cuero', Icons.workspace_premium_outlined, Color(0xFF92400E)),
    CategoriaInfo('dualtek', 'DualTek', Icons.shield_outlined, Color(0xFF5B4FCF)),
    CategoriaInfo('magsafe', 'MagSafe', Icons.radio_button_checked_rounded, Color(0xFFBE185D)),
    CategoriaInfo('personalizada', 'Diseños', Icons.palette_outlined, Color(0xFFEA580C)),
  ];

  static CategoriaInfo de(String id) => todas.firstWhere(
        (c) => c.id == id,
        orElse: () => CategoriaInfo(id, _capitalizar(id), Icons.category_outlined, const Color(0xFF475569)),
      );

  static String etiqueta(String id) => id == 'todas' ? 'Todas' : de(id).etiqueta;

  static String _capitalizar(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
