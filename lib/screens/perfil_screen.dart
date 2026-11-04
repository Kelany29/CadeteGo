import 'package:flutter/material.dart';

class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi Perfil')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person, size: 80, color: Theme.of(context).primaryColor),
            const SizedBox(height: 20),
            const Text('Kelany Blanco', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const Text('Repartidor Activo'),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => Navigator.pushReplacementNamed(context, '/'),
              child: const Text('Cerrar Sesión'),
            )
          ],
        ),
      ),
    );
  }
}