import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'providers/carrito_provider.dart';
import 'screens/home_screen.dart';

import 'utils/catalogo_seeder.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Sincronizar catálogo automáticamente para asegurar que todas las fotos apunten a los .jpg existentes
  CatalogoSeeder.sincronizarFotosYNomenclatura().catchError((e) {
    debugPrint('Error en sincronización automática: $e');
    return 0;
  });
  runApp(const RoyalApp());
}

class RoyalApp extends StatelessWidget {
  const RoyalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CarritoProvider(),
      child: MaterialApp(
        title: 'Royal',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        home: const HomeScreen(),
      ),
    );
  }
}