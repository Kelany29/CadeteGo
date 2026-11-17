import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Conexión en tiempo real a la tabla 'pedidos'
  final _pedidosStream = Supabase.instance.client
      .from('pedidos')
      .stream(primaryKey: ['id'])
      .order('estado', ascending: false);

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
      // Mantenemos los espacios en los diamantes para que el editor no te los borre
      body: StreamBuilder < List < Map < String , dynamic > > > (
        stream: _pedidosStream,
        builder: (context, snapshot) {
          
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  'Error exacto: ${snapshot.error}', 
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          // ESTA ES LA LÍNEA QUE FALTABA: Define qué es 'pedidos' de forma segura
          final pedidos = snapshot.data ?? [];
          
          if (pedidos.isEmpty) {
            return const Center(child: Text('No hay pedidos asignados.'));
          }

          return ListView.builder(
            itemCount: pedidos.length,
            itemBuilder: (context, index) {
              final pedido = pedidos[index];
              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  leading: Icon(Icons.location_on, color: Theme.of(context).primaryColor),
                  title: Text(pedido['direccion'] ?? 'Sin dirección', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Estado: ${pedido['estado']}'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    
                    Navigator.pushNamed(context, '/detalle', arguments: pedido);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}