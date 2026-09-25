/// Función utilitaria global para dar formato a precios en guaraníes.
/// Ejemplo: 85000 -> "85.000 Gs"
String formatPrice(num amount) {
  final s = amount.round().toString();
  final buffer = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    final posFromEnd = s.length - i;
    buffer.write(s[i]);
    if (posFromEnd > 1 && posFromEnd % 3 == 1) buffer.write('.');
  }
  return '${buffer.toString()} Gs';
}
