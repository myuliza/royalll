import 'package:flutter/widgets.dart';

/// Texto del buscador global. Lo escribe la barra superior (o el campo del catálogo en móvil)
/// y lo usa el filtro existente del catálogo.
class BusquedaCatalogo extends ChangeNotifier {
  final TextEditingController controller = TextEditingController();
  final FocusNode focoCatalogo = FocusNode(debugLabel: 'busqueda-catalogo');

  BusquedaCatalogo() {
    controller.addListener(notifyListeners);
  }

  /// Texto normalizado (minúsculas, sin espacios extremos) que usa el filtro.
  String get consulta => controller.text.trim().toLowerCase();

  void limpiar() => controller.clear();

  @override
  void dispose() {
    controller.dispose();
    focoCatalogo.dispose();
    super.dispose();
  }
}
