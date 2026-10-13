import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';
import 'providers/carrito_provider.dart';
import 'package:go_router/go_router.dart';
import 'app_router.dart';
import 'providers/busqueda_catalogo.dart';
import 'providers/empleado_sesion.dart';

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

class RoyalApp extends StatefulWidget {
  const RoyalApp({super.key});

  @override
  State<RoyalApp> createState() => _RoyalAppState();
}

class _RoyalAppState extends State<RoyalApp> {
  late final GoRouter _router = crearRouter();

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CarritoProvider()),
        ChangeNotifierProvider(create: (_) => ThemeController()),
        ChangeNotifierProvider(create: (_) => EmpleadoSesion()),
        ChangeNotifierProvider(create: (_) => BusquedaCatalogo()),
      ],
      child: Consumer<ThemeController>(
        builder: (context, tema, _) => MaterialApp.router(
          title: 'Royal',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: tema.modo,
          themeAnimationDuration: AppDurations.lenta,
          routerConfig: _router,
          locale: const Locale('es'),
          supportedLocales: const [Locale('es'), Locale('en')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
        ),
      ),
    );
  }
}
