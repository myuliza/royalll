import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Estado de la sesión de empleado (solo lectura):
/// escucha FirebaseAuth y verifica el rol en `users/{uid}` (employee / admin),
/// igual que la pantalla de acceso. No escribe nada en Firebase.
class EmpleadoSesion extends ChangeNotifier {
  StreamSubscription<User?>? _sub;
  bool _cargando = true;
  bool _esEmpleado = false;

  bool get cargando => _cargando;
  bool get esEmpleado => _esEmpleado;

  EmpleadoSesion() {
    _sub = FirebaseAuth.instance.authStateChanges().listen(_verificar);
  }

  /// Constructor para tests (sin Firebase).
  @visibleForTesting
  EmpleadoSesion.prueba({bool esEmpleado = false})
      : _cargando = false,
        _esEmpleado = esEmpleado;

  Future<void> _verificar(User? user) async {
    if (user == null) {
      _actualizar(cargando: false, esEmpleado: false);
      return;
    }
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final role = (doc.data()?['role'] ?? '').toString().toLowerCase();
      _actualizar(cargando: false, esEmpleado: doc.exists && (role == 'employee' || role == 'admin'));
    } catch (e) {
      debugPrint('No se pudo verificar el rol de empleado: $e');
      _actualizar(cargando: false, esEmpleado: false);
    }
  }

  void _actualizar({required bool cargando, required bool esEmpleado}) {
    if (_cargando == cargando && _esEmpleado == esEmpleado) return;
    _cargando = cargando;
    _esEmpleado = esEmpleado;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
