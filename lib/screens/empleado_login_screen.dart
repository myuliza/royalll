import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'empleado_dashboard_screen.dart';

class EmpleadoLoginScreen extends StatefulWidget {
  const EmpleadoLoginScreen({super.key});

  @override
  State<EmpleadoLoginScreen> createState() => _EmpleadoLoginScreenState();
}

class _EmpleadoLoginScreenState extends State<EmpleadoLoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  String? _error;
  bool _cargando = false;

  Future<void> _iniciarSesion() async {
    setState(() {
      _error = null;
      _cargando = true;
    });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );
      // Por ahora solo confirmamos que entró; el dashboard lo agregamos en el próximo paso.
// DESPUÉS:
if (mounted) {
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (_) => const EmpleadoDashboardScreen()),
  );
}
    } on FirebaseAuthException catch (e) {
      setState(() {
        _error = e.code == 'invalid-credential'
            ? 'Email o contraseña incorrectos'
            : 'Error: ${e.code}';
      });
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Acceso empleado')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Contraseña'),
            ),
            const SizedBox(height: 20),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            ElevatedButton(
              onPressed: _cargando ? null : _iniciarSesion,
              child: _cargando
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Ingresar'),
            ),
          ],
        ),
      ),
    );
  }
}