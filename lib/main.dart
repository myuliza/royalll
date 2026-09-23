import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'providers/carrito_provider.dart';
import 'screens/home_screen.dart';

Future<void> seedProducto() async {
  await FirebaseFirestore.instance.collection('productos').add({
    'nombre': 'Funda iPhone 13 Transparente',
    'categoria': 'transparente',
    'modelosCompatibles': ['iPhone 13', 'iPhone 13 Pro'],
    'precio': 85000,
    'colorHex': '#FFFFFF',
    'personalizable': false,
    'stock': 10,
    'fotosUrls': <String>[],
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await seedProducto(); // ← temporal, sacar después de confirmar en Firestore
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