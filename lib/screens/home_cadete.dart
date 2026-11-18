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
  Map < String , MapaDatos > _perfilesMap = {};
  bool _cargandoPerfiles = false;

  @override
  void initState() {
    super.initState();
    _cargarCacheLocal();
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
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('cache_perfiles_cadete', jsonEncode(mapa));
      }
    } catch (_) {
      // Si está offline, usa lo que cargó de caché
    } finally {
      _cargandoPerfiles = false;
    }
  }

  Future<void> _cargarCacheLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final String? datosGuardados = prefs.getString('cache_pedidos_cadete');
    final String? perfilesGuardados = prefs.getString('cache_perfiles_cadete');

    if (mounted) {
      setState(() {
        if (datosGuardados != null) {
          final List<dynamic> decodificado = jsonDecode(datosGuardados);
          _pedidosCache = decodificado.cast < MapaDatos >();
        }
        if (perfilesGuardados != null) {
          final Map<String, dynamic> decodPerfiles = jsonDecode(perfilesGuardados);
          _perfilesMap = decodPerfiles.map(
            (key, value) => MapEntry(key, Map < String , dynamic >.from(value)),
          );
        }
      });
    }
  }

  Future<void> _guardarCacheLocal(ListaPedidos pedidos) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cache_pedidos_cadete', jsonEncode(pedidos));
  }

  String _formatearFechaHora(dynamic fechaRaw) {
    if (fechaRaw == null) return '';
    final dt = DateTime.tryParse(fechaRaw.toString())?.toLocal();
    if (dt == null) return '';
    final dia = dt.day.toString().padLeft(2, '0');
    final mes = dt.month.toString().padLeft(2, '0');
    final hora = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$dia/$mes $hora:$min hs';
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

  Widget _construirListaCategoria(ListaPedidos lista, bool tieneEnvioActivo, String mensajeVacio) {
    if (lista.isEmpty) {
      return Center(
        child: Text(mensajeVacio, style: const TextStyle(color: Colors.black54)),
      );
    }

    return ListView.builder(
      itemCount: lista.length,
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      itemBuilder: (context, index) {
        final pedido = lista[index];
        final estado = pedido['estado'] ?? 'Pendiente';
        final monto = (pedido['monto'] as num?)?.toDouble() ?? 0.0;
        final esMioActivo = pedido['cadete_id'] == _userId && estado == 'En camino';
        final bloqueado = tieneEnvioActivo && estado == 'Pendiente';

        final localId = pedido['local_id']?.toString();
        final local = localId != null ? _perfilesMap[localId] : null;
        final nombreLocal = local?['nombre'] ?? 'Comercio Local';
        final dirOrigen = local?['direccion'] ?? 'Dirección del local no especificada';
        final fechaTexto = _formatearFechaHora(pedido['creado_en']);

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
              'Retiro: $nombreLocal (\$${monto.toStringAsFixed(0)})',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: bloqueado ? Colors.black54 : Colors.black87,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 3),
                Text('Origen: $dirOrigen', style: const TextStyle(fontSize: 12, color: Colors.black87)),
                Text(
                  'Destino: ${pedido['direccion_entrega'] ?? 'Sin dirección'}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87),
                ),
                if (fechaTexto.isNotEmpty)
                  Text('Horario: $fechaTexto', style: const TextStyle(fontSize: 11, color: Colors.black54)),
                if (esMioActivo)
                  Text('TU ENVÍO EN CURSO', style: TextStyle(fontSize: 12, color: Colors.blue[800], fontWeight: FontWeight.bold)),
                if (bloqueado)
                  const Text('Bloqueado hasta finalizar tu envío', style: TextStyle(fontSize: 11, color: Colors.deepOrange)),
              ],
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.pushNamed(context, '/detalle', arguments: pedido);
            },
          ),
        );
      },
    );
  }

  Widget _construirContenido(ListaPedidos pedidos, {bool esOffline = false}) {
    final bool tieneEnvioActivo = pedidos.any(
      (p) => p['cadete_id'] == _userId && p['estado'] == 'En camino',
    );

    final ListaPedidos pendientes = [];
    final ListaPedidos enCamino = [];
    final ListaPedidos entregados = [];
    final ListaPedidos cancelados = [];

    for (final p in pedidos) {
      final est = p['estado'] ?? 'Pendiente';
      if (est == 'Pendiente') {
        pendientes.add(p);
      } else if (est == 'En camino') {
        enCamino.add(p);
      } else if (est == 'Entregado') {
        entregados.add(p);
      } else if (est == 'Cancelado') {
        cancelados.add(p);
      }
    }

    return Column(
      children: [
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

        if (tieneEnvioActivo)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            padding: const EdgeInsets.all(10),
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
                    'Tenés un envío en curso. Entregalo para tomar otro.',
                    style: TextStyle(color: Colors.blue[900], fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ],
            ),
          )
        else if (pendientes.isNotEmpty)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            padding: const EdgeInsets.all(10),
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
                    pendientes.length == 1
                        ? '¡Hay 1 pedido disponible para retirar!'
                        : '¡Hay ${pendientes.length} pedidos disponibles para retirar!',
                    style: TextStyle(color: Colors.green[900], fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
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
              _construirListaCategoria(pendientes, tieneEnvioActivo, 'No hay pedidos pendientes.'),
              _construirListaCategoria(enCamino, tieneEnvioActivo, 'No hay pedidos en camino.'),
              _construirListaCategoria(entregados, tieneEnvioActivo, 'No hay pedidos entregados.'),
              _construirListaCategoria(cancelados, tieneEnvioActivo, 'No hay pedidos cancelados.'),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
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
              return _construirContenido(_pedidosCache, esOffline: true);
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              if (_pedidosCache.isNotEmpty) {
                return _construirContenido(_pedidosCache, esOffline: true);
              }
              return const Center(child: CircularProgressIndicator());
            }

            final pedidos = snapshot.data ?? [];
            if (pedidos.any((p) => p['local_id'] != null && !_perfilesMap.containsKey(p['local_id'].toString()))) {
              _cargarPerfiles();
            }
            _guardarCacheLocal(pedidos);

            return _construirContenido(pedidos, esOffline: false);
          },
        ),
      ),
    );
  }
}