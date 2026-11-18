import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

typedef MapaDatos = Map < String , dynamic >;
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

  Map < String , MapaDatos > _perfilesMap = {};
  bool _cargandoPerfiles = false;

  @override
  void initState() {
    super.initState();
    _cargarPerfiles();
  }

  Future<void> _cargarPerfiles() async {
    if (_cargandoPerfiles) return;
    _cargandoPerfiles = true;
    try {
      final data = await Supabase.instance.client.from('perfiles').select();
      final Map < String , MapaDatos > mapa = {};
      for (final p in (data as List)) {
        mapa[p['id'].toString()] = Map < String , dynamic >.from(p);
      }
      if (mounted) {
        setState(() => _perfilesMap = mapa);
      }
    } finally {
      _cargandoPerfiles = false;
    }
  }

  String _formatearFechaHora(dynamic fechaRaw) {
    if (fechaRaw == null) return 'Sin fecha';
    final dt = DateTime.tryParse(fechaRaw.toString())?.toLocal();
    if (dt == null) return 'Sin fecha';
    final dia = dt.day.toString().padLeft(2, '0');
    final mes = dt.month.toString().padLeft(2, '0');
    final anio = dt.year;
    final hora = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$dia/$mes/$anio $hora:$min hs';
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

  void _mostrarDialogoCalificar(MapaDatos pedido) {
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
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          child: Column(
            children: [
              Icon(icono, color: color, size: 24),
              const SizedBox(height: 4),
              Text(
                valor,
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: color),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                titulo,
                style: const TextStyle(fontSize: 11, color: Colors.black54, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _construirListaCategoria(ListaPedidos lista, String mensajeVacio) {
    if (lista.isEmpty) {
      return Center(
        child: Text(mensajeVacio, style: const TextStyle(color: Colors.black54)),
      );
    }

    return ListView.builder(
      itemCount: lista.length,
      padding: const EdgeInsets.only(top: 8, bottom: 85, left: 10, right: 10),
      itemBuilder: (context, index) {
        final pedido = lista[index];
        final estado = pedido['estado'] ?? 'Pendiente';
        final monto = (pedido['monto'] as num?)?.toDouble() ?? 0.0;
        final calificacion = pedido['calificacion'];
        final cadeteId = pedido['cadete_id']?.toString();
        final cadete = cadeteId != null ? _perfilesMap[cadeteId] : null;
        final fechaTexto = _formatearFechaHora(pedido['creado_en']);

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
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),
                Text('Enviado: $fechaTexto', style: const TextStyle(fontSize: 12)),
                Text(
                  cadete != null
                      ? 'Cadete: ${cadete['nombre']} (${cadete['telefono'] ?? 'Sin tel.'})'
                      : 'Cadete: Sin asignar aún',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: cadete != null ? Colors.blue[800] : Colors.orange[800],
                  ),
                ),
              ],
            ),
            isThreeLine: true,
            trailing: estado == 'Entregado'
                ? (calificacion == null
                    ? ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber[700],
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        icon: const Icon(Icons.star, size: 15),
                        label: const Text('Calificar', style: TextStyle(fontSize: 11)),
                        onPressed: () => _mostrarDialogoCalificar(pedido),
                      )
                    : Chip(
                        avatar: const Icon(Icons.star, color: Colors.amber, size: 16),
                        label: Text('$calificacion/5', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ))
                : const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.pushNamed(context, '/detalle', arguments: pedido);
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
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

            // Si aparece un cadete nuevo que no está en caché, refrescamos perfiles
            if (pedidos.any((p) => p['cadete_id'] != null && !_perfilesMap.containsKey(p['cadete_id'].toString()))) {
              _cargarPerfiles();
            }

            double totalVendido = 0;
            final ListaPedidos pendientes = [];
            final ListaPedidos enCamino = [];
            final ListaPedidos entregados = [];
            final ListaPedidos cancelados = [];

            for (final p in pedidos) {
              final est = p['estado'] ?? 'Pendiente';
              final monto = (p['monto'] as num?)?.toDouble() ?? 0.0;
              if (est == 'Pendiente') {
                pendientes.add(p);
              } else if (est == 'En camino') {
                enCamino.add(p);
              } else if (est == 'Entregado') {
                entregados.add(p);
                totalVendido += monto;
              } else if (est == 'Cancelado') {
                cancelados.add(p);
              }
            }

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
                  child: Row(
                    children: [
                      _tarjetaKpi('Vendido', '\$${totalVendido.toStringAsFixed(0)}', Icons.attach_money, Colors.green[700]!),
                      const SizedBox(width: 8),
                      _tarjetaKpi('En curso', '${pendientes.length + enCamino.length}', Icons.delivery_dining, Colors.orange[700]!),
                      const SizedBox(width: 8),
                      _tarjetaKpi('Entregados', '${entregados.length}', Icons.check_circle, Colors.blue[700]!),
                    ],
                  ),
                ),
                TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  labelColor: Colors.green[800],
                  unselectedLabelColor: Colors.grey[600],
                  indicatorColor: Colors.green[700],
                  tabs: [
                    Tab(text: 'Pendientes (${pendientes.length})'),
                    Tab(text: 'En camino (${enCamino.length})'),
                    Tab(text: 'Entregados (${entregados.length})'),
                    Tab(text: 'Cancelados (${cancelados.length})'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _construirListaCategoria(pendientes, 'No hay pedidos pendientes.'),
                      _construirListaCategoria(enCamino, 'No hay pedidos en camino.'),
                      _construirListaCategoria(entregados, 'Aún no hay pedidos entregados.'),
                      _construirListaCategoria(cancelados, 'No hay pedidos cancelados.'),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}