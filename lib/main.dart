import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart'; // generado por `flutterfire configure`
import 'theme/app_theme.dart';
import 'providers/carrito_provider.dart';
import 'screens/catalogo_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
        home: const CatalogoScreen(),
      ),
    );
  }
}
