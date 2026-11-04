import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Pedidos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.pushNamed(context, '/perfil'),
          )
        ],
      ),
      body: ListView.builder(
        itemCount: 3, 
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.all(8),
            child: ListTile(
              leading: Icon(Icons.location_on, color: Theme.of(context).primaryColor),
              title: Text('Calle Falsa ${123 + index}'),
              subtitle: const Text('Estado: Pendiente'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => Navigator.pushNamed(context, '/detalle'),
            ),
          );
        },
      ),
    );
  }
}