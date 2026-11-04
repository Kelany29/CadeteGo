import 'package:flutter/material.dart';

class DetalleScreen extends StatelessWidget {
  const DetalleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del Pedido')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Dirección:', style: TextStyle(fontWeight: FontWeight.bold)),
            const Text('Calle Falsa 123, B° Centro', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            const Text('Notas del cliente: Tocar timbre fuerte.'),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.map),
                label: const Text('Abrir en GPS'),
                onPressed: () {}, 
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.check),
                label: const Text('Marcar Entregado'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: () {}, 
              ),
            ),
          ],
        ),
      ),
    );
  }
}