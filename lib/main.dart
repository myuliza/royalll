import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';
import 'providers/carrito_provider.dart';
import 'screens/home_screen.dart';

import 'utils/catalogo_seeder.dart';

/// `flutter run --dart-define=SIN_SYNC=true` desactiva la sincronización automática
/// del catálogo (útil para probar sin escribir en Firestore). Sin el flag, todo sigue igual.
const bool _sinSync = bool.fromEnvironment('SIN_SYNC');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Sincronizar catálogo automáticamente para asegurar que todas las fotos apunten a los .jpg existentes
  if (!_sinSync) {
    CatalogoSeeder.sincronizarFotosYNomenclatura().catchError((e) {
      debugPrint('Error en sincronización automática: $e');
      return 0;
    });
  }
  runApp(const RoyalApp());
}

class RoyalApp extends StatelessWidget {
  const RoyalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CarritoProvider()),
        ChangeNotifierProvider(create: (_) => ThemeController()),
      ],
      child: Consumer<ThemeController>(
        builder: (context, tema, _) => MaterialApp(
          title: 'Royal',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: tema.modo,
          themeAnimationDuration: AppDurations.lenta,
          home: const HomeScreen(),
        ),
      ),
    );
  }
}
