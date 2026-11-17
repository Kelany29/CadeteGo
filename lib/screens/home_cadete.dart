import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef MapaDatos = Map < String , dynamic >;
typedef ListaPedidos = List < Map < String , dynamic > >;

class HomeCadeteScreen extends StatefulWidget {
  const HomeCadeteScreen({super.key});

  @override
  State<HomeCadeteScreen> createState() => _HomeCadeteScreenState();
}

class _HomeCadeteScreenState extends State<HomeCadeteScreen> {
  final _userId = Supabase.instance.client.auth.currentUser?.id;

  final _pedidosStream = Supabase.instance.client
      .from('pedidos')
      .stream(primaryKey: ['id'])
      .order('creado_en', ascending: false);

  ListaPedidos _pedidosCache = [];

  @override
  void initState() {
    super.initState();
    _cargarCacheLocal();
  }

  Future<void> _cargarCacheLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final String? datosGuardados = prefs.getString('cache_pedidos_cadete');
    if (datosGuardados != null && mounted) {
      final List<dynamic> decodificado = jsonDecode(datosGuardados);
      setState(() {
        _pedidosCache = decodificado.cast < MapaDatos >();
      });
    }
  }

  Future<void> _guardarCacheLocal(ListaPedidos pedidos) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cache_pedidos_cadete', jsonEncode(pedidos));
  }

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

  Widget _construirLista(ListaPedidos pedidos, {bool esOffline = false}) {
    // Verificamos si este cadete ya tiene un pedido activo ("En camino")
    final bool tieneEnvioActivo = pedidos.any(
      (p) => p['cadete_id'] == _userId && p['estado'] == 'En camino',
    );

    // Contamos cuántos pedidos hay libres para tomar
    final int disponibles = pedidos.where((p) => p['estado'] == 'Pendiente').length;

    return Column(
      children: [
        // Banner de Modo Offline
        if (esOffline)
          Container(
            width: double.infinity,
            color: Colors.amber[800],
            padding: const EdgeInsets.all(8),
            child: const Text(
              'Sin conexión: Mostrando última copia guardada',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),

        // Banner de Regla de Negocio: Bloqueo por envío activo o Alerta de disponibles
        if (tieneEnvioActivo)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              border: Border.all(color: Colors.blue),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[800]),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Tenés un envío en curso. Marcalo como entregado para poder tomar otro pedido.',
                    style: TextStyle(color: Colors.blue[900], fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          )
        else if (disponibles > 0)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[50],
              border: Border.all(color: Colors.green),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.notifications_active, color: Colors.green[800]),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    disponibles == 1
                        ? '¡Hay 1 pedido disponible listo para retirar!'
                        : '¡Hay $disponibles pedidos disponibles listos para retirar!',
                    style: TextStyle(color: Colors.green[900], fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

        // Lista de pedidos
        Expanded(
          child: pedidos.isEmpty
              ? const Center(child: Text('No hay pedidos registrados en este momento.'))
              : ListView.builder(
                  itemCount: pedidos.length,
                  padding: const EdgeInsets.only(top: 6, bottom: 16),
                  itemBuilder: (context, index) {
                    final pedido = pedidos[index];
                    final estado = pedido['estado'] ?? 'Pendiente';
                    final monto = (pedido['monto'] as num?)?.toDouble() ?? 0.0;
                    final esMioActivo = pedido['cadete_id'] == _userId && estado == 'En camino';
                    final bloqueado = tieneEnvioActivo && estado == 'Pendiente';

                    return Card(
                      elevation: esMioActivo ? 4 : 1,
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: esMioActivo
                            ? const BorderSide(color: Colors.blue, width: 2)
                            : BorderSide.none,
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _colorEstado(estado).withAlpha(40),
                          child: Icon(
                            bloqueado ? Icons.lock : Icons.delivery_dining,
                            color: bloqueado ? Colors.grey : _colorEstado(estado),
                          ),
                        ),
                        title: Text(
                          '${pedido['direccion_entrega'] ?? 'Sin dirección'} (\$${monto.toStringAsFixed(0)})',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: bloqueado ? Colors.black54 : Colors.black87,
                          ),
                        ),
                        subtitle: Text(
                          esMioActivo
                              ? 'TU ENVÍO EN CURSO'
                              : (bloqueado ? 'Pendiente (Bloqueado hasta finalizar tu envío)' : 'Estado: $estado'),
                          style: TextStyle(
                            color: esMioActivo
                                ? Colors.blue[800]
                                : (bloqueado ? Colors.grey : _colorEstado(estado)),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ruta de Entregas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.pushNamed(context, '/perfil'),
          )
        ],
      ),
      body: StreamBuilder < ListaPedidos > (
        stream: _pedidosStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _construirLista(_pedidosCache, esOffline: true);
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            if (_pedidosCache.isNotEmpty) {
              return _construirLista(_pedidosCache, esOffline: true);
            }
            return const Center(child: CircularProgressIndicator());
          }

          final pedidos = snapshot.data ?? [];
          _guardarCacheLocal(pedidos);

          return _construirLista(pedidos, esOffline: false);
        },
      ),
    );
  }
}