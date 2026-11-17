import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


typedef ListaPedidos = List < Map < String , dynamic > >;

class HomeLocalScreen extends StatefulWidget {
  const HomeLocalScreen({super.key});

  @override
  State<HomeLocalScreen> createState() => _HomeLocalScreenState();
}

class _HomeLocalScreenState extends State<HomeLocalScreen> {
  final userId = Supabase.instance.client.auth.currentUser!.id;

  late final _pedidosStream = Supabase.instance.client
      .from('pedidos')
      .stream(primaryKey: ['id'])
      .eq('local_id', userId)
      .order('creado_en', ascending: false);

  Color _colorEstado(String estado) {
    switch (estado) {
      case 'Pendiente':
        return Colors.orange;
      case 'En camino':
        return Colors.blue;
      case 'Entregado':
        return Colors.green;
      case 'Cancelado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  
  void _mostrarDialogoNuevoPedido() {
    String direccion = '';
    String montoTexto = '';
    String notas = '';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Despachar Nuevo Pedido'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Dirección del cliente *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                onChanged: (val) => direccion = val,
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Monto del pedido (\$)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (val) => montoTexto = val,
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Notas (ej: Timbre 2, paga con QR)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note),
                ),
                onChanged: (val) => notas = val,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (direccion.trim().isNotEmpty) {
                final double monto = double.tryParse(montoTexto.replaceAll(',', '.')) ?? 0.0;
                await Supabase.instance.client.from('pedidos').insert({
                  'local_id': userId,
                  'direccion_entrega': direccion.trim(),
                  'monto': monto,
                  'notas': notas.trim(),
                  'estado': 'Pendiente',
                });
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Crear Pedido'),
          )
        ],
      ),
    );
  }

 
  void _mostrarDialogoCalificar(Map < String , dynamic > pedido) {
    int estrellas = 5;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('Calificar al Cadete'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '¿Cómo fue la entrega en ${pedido['direccion_entrega']}?',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final valor = index + 1;
                    return IconButton(
                      icon: Icon(
                        valor <= estrellas ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 34,
                      ),
                      onPressed: () {
                        setStateDialog(() => estrellas = valor);
                      },
                    );
                  }),
                ),
                Text(
                  '$estrellas de 5 estrellas',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () async {
                  await Supabase.instance.client
                      .from('pedidos')
                      .update({'calificacion': estrellas})
                      .eq('id', pedido['id']);
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) {
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      const SnackBar(
                        content: Text('¡Gracias! Calificación enviada al cadete.'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
                child: const Text('Guardar'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _tarjetaKpi(String titulo, String valor, IconData icono, Color color) {
    return Expanded(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            children: [
              Icon(icono, color: color, size: 26),
              const SizedBox(height: 6),
              Text(
                valor,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                titulo,
                style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de mi Local'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.pushNamed(context, '/perfil'),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _mostrarDialogoNuevoPedido,
        icon: const Icon(Icons.add_location_alt),
        label: const Text('Nuevo Pedido'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder < ListaPedidos > (
        stream: _pedidosStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final pedidos = snapshot.data ?? [];

          
          double totalVendido = 0;
          int activos = 0;
          int entregados = 0;

          for (final p in pedidos) {
            final est = p['estado'] ?? 'Pendiente';
            final monto = (p['monto'] as num?)?.toDouble() ?? 0.0;
            if (est == 'Entregado') {
              entregados++;
              totalVendido += monto;
            } else if (est == 'Pendiente' || est == 'En camino') {
              activos++;
            }
          }

          return Column(
            children: [
              // Dashboard superior con las 3 tarjetas de métricas
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                child: Row(
                  children: [
                    _tarjetaKpi('Vendido', '\$${totalVendido.toStringAsFixed(0)}', Icons.attach_money, Colors.green[700]!),
                    const SizedBox(width: 8),
                    _tarjetaKpi('Activos', '$activos', Icons.delivery_dining, Colors.orange[700]!),
                    const SizedBox(width: 8),
                    _tarjetaKpi('Entregados', '$entregados', Icons.check_circle, Colors.blue[700]!),
                  ],
                ),
              ),
              const Divider(),

             
              Expanded(
                child: pedidos.isEmpty
                    ? const Center(
                        child: Text(
                          'No tenés pedidos registrados.\nTocá "Nuevo Pedido" para empezar.',
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.builder(
                        itemCount: pedidos.length,
                        padding: const EdgeInsets.only(bottom: 80, left: 8, right: 8),
                        itemBuilder: (context, index) {
                          final pedido = pedidos[index];
                          final estado = pedido['estado'] ?? 'Pendiente';
                          final monto = (pedido['monto'] as num?)?.toDouble() ?? 0.0;
                          final calificacion = pedido['calificacion'];

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 5),
                            child: ListTile(
                              leading: CircleAvatar(
                               backgroundColor: _colorEstado(estado).withAlpha(40),
                                child: Icon(Icons.fastfood, color: _colorEstado(estado)),
                              ),
                              title: Text(
                                '${pedido['direccion_entrega'] ?? 'Sin dirección'} (\$${monto.toStringAsFixed(0)})',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                'Estado: $estado',
                                style: TextStyle(color: _colorEstado(estado), fontWeight: FontWeight.w600),
                              ),
                              trailing: estado == 'Entregado'
                                  ? (calificacion == null
                                      ? ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.amber[700],
                                            padding: const EdgeInsets.symmetric(horizontal: 10),
                                          ),
                                          icon: const Icon(Icons.star, size: 16),
                                          label: const Text('Calificar', style: TextStyle(fontSize: 12)),
                                          onPressed: () => _mostrarDialogoCalificar(pedido),
                                        )
                                      : Chip(
                                          avatar: const Icon(Icons.star, color: Colors.amber, size: 18),
                                          label: Text('$calificacion/5', style: const TextStyle(fontWeight: FontWeight.bold)),
                                        ))
                                  : const Icon(Icons.arrow_forward_ios, size: 16),
                              onTap: () {
                                Navigator.pushNamed(context, '/detalle', arguments: pedido);
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}