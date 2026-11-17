import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_local.dart';
import 'screens/home_cadete.dart';
import 'screens/detalle_screen.dart';
import 'screens/perfil_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Cargamos las variables de entorno ocultas
  await dotenv.load(fileName: ".env");

  // 2. Inicializamos Supabase leyendo de forma segura desde el .env
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(const CadeteGoApp());
}

class CadeteGoApp extends StatelessWidget {
  const CadeteGoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CadeteGO',
      debugShowCheckedModeBanner: false, // Oculta la cinta roja de "DEBUG" en la esquina
      theme: ThemeData(
        primaryColor: Colors.green[700],
        scaffoldBackgroundColor: const Color(0xFFF9F6EE), // Fondo crema que combina con tu logo
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
        '/': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home_local': (context) => const HomeLocalScreen(),
        '/home_cadete': (context) => const HomeCadeteScreen(),
        '/detalle': (context) => const DetalleScreen(),
        '/perfil': (context) => const PerfilScreen(),
      },
    );
  }
}