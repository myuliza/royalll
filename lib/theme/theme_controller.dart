import 'package:flutter/material.dart';

/// Modo de tema global (claro / oscuro). Arranca en claro.
class ThemeController extends ChangeNotifier {
  ThemeMode _modo = ThemeMode.light;

  ThemeMode get modo => _modo;
  bool get esOscuro => _modo == ThemeMode.dark;

  void alternar() {
    _modo = esOscuro ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }
}
