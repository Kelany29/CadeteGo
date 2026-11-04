import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; 

import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/detalle_screen.dart';
import 'screens/perfil_screen.dart';

Future<void> main() async {

  WidgetsFlutterBinding.ensureInitialized();
  
  
  await Supabase.initialize(
    url: 'https://jezcbdquppkjvoixfegj.supabase.co', 
    anonKey: 'sb_publishable_XrH-x4ftQrraHdMiPGdffQ_FrhiH6mF',
  );

  runApp(const CadeteGoApp());
}

class CadeteGoApp extends StatelessWidget {
  const CadeteGoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CadeteGO',
      theme: ThemeData(
        primaryColor: Colors.green[700],
        scaffoldBackgroundColor: const Color(0xFFF9F6EE), 
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.green[700],
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[700],
            foregroundColor: Colors.white,
          ),
        ),
      ),
     initialRoute: '/',
      routes: {
        '/': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/home': (context) => HomeScreen(),
        '/detalle': (context) => DetalleScreen(),
        '/perfil': (context) => PerfilScreen(),
      },
    );
  }
}