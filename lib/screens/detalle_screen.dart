import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

typedef MapaDatos = Map < String , dynamic >;

class DetalleScreen extends StatefulWidget {
  const DetalleScreen({super.key});

  @override
  State<DetalleScreen> createState() => _DetalleScreenState();
}

class _DetalleScreenState extends State<DetalleScreen> {
  bool _cargando = true;
  bool _tieneOtroEnvioActivo = false;
  bool _yaInicializado = false;

  MapaDatos? _perfilLocal;
  MapaDatos? _perfilCadete;
  double _promedioCadete = 0.0;
  int _entregasCadete = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_yaInicializado) {
      _yaInicializado = true;
      _cargarDatosCompletos();
    }
  }

  Future<void> _cargarDatosCompletos() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    final pedido = ModalRoute.of(context)!.settings.arguments as MapaDatos;

    try {
      bool tieneOtro = false;
      if (userId != null) {
        final activos = await Supabase.instance.client
            .from('pedidos')
            .select('id')
            .eq('cadete_id', userId)
            .eq('estado', 'En camino');
        tieneOtro = (activos as List).any((item) => item['id'] != pedido['id']);
      }

      MapaDatos? localData;
      if (pedido['local_id'] != null) {
        localData = await Supabase.instance.client
            .from('perfiles')
            .select()
            .eq('id', pedido['local_id'])
            .maybeSingle();
      }

      MapaDatos? cadeteData;
      double promedio = 0.0;
      int totalEntregas = 0;

      if (pedido['cadete_id'] != null) {
        cadeteData = await Supabase.instance.client
            .from('perfiles')
            .select()
            .eq('id', pedido['cadete_id'])
            .maybeSingle();

        final historial = await Supabase.instance.client
            .from('pedidos')
            .select('calificacion')
            .eq('cadete_id', pedido['cadete_id'])
            .eq('estado', 'Entregado');

        final lista = historial as List;
        totalEntregas = lista.length;
        double suma = 0;
        int cantCalif = 0;
        for (final item in lista) {
          if (item['calificacion'] != null) {
            suma += (item['calificacion'] as num).toDouble();
            cantCalif++;
          }
        }
        if (cantCalif > 0) promedio = suma / cantCalif;
      }

      if (mounted) {
        setState(() {
          _tieneOtroEnvioActivo = tieneOtro;
          _perfilLocal = localData;
          _perfilCadete = cadeteData;
          _promedioCadete = promedio;
          _entregasCadete = totalEntregas;
          _cargando = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _cargando = false);
    }
  }

  String _formatearFechaHora(dynamic fechaRaw) {
    if (fechaRaw == null) return 'Pendiente';
    final dt = DateTime.tryParse(fechaRaw.toString())?.toLocal();
    if (dt == null) return 'Pendiente';
    final dia = dt.day.toString().padLeft(2, '0');
    final mes = dt.month.toString().padLeft(2, '0');
    final anio = dt.year;
    final hora = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$dia/$mes/$anio a las $hora:$min hs';
  }

  Future<void> _abrirRutaMoto(String direccion) async {
    final String query = Uri.encodeComponent(direccion);
    final Uri url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$query&travelmode=motorcycle',
    );
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('No se pudo iniciar la navegación GPS para $direccion');
    }
  }

  Future<void> _actualizarEstado(String idPedido, String nuevoEstado, {String? notaExtra}) async {
    final cadeteId = Supabase.instance.client.auth.currentUser?.id;

    final MapaDatos datosActualizar = {
      'estado': nuevoEstado,
      'actualizado_en': DateTime.now().toUtc().toIso8601String(),
      if (nuevoEstado == 'En camino' && cadeteId != null) 'cadete_id': cadeteId,
      if (notaExtra != null && notaExtra.isNotEmpty) 'notas': notaExtra,
    };

    await Supabase.instance.client
        .from('pedidos')
        .update(datosActualizar)
        .eq('id', idPedido);

    if (mounted) {
      Navigator.pop(context);
    }
  }

  void _mostrarDialogoCancelar(MapaDatos pedido) {
    String motivo = '';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar / Reportar Problema'),
        content: TextField(
          decoration: const InputDecoration(
            labelText: 'Motivo (ej: Cliente no responde)',
            border: OutlineInputBorder(),
          ),
          onChanged: (val) => motivo = val,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Volver')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              final notaFinal = '${pedido['notas'] ?? ''} | CANCELADO: $motivo';
              _actualizarEstado(pedido['id'], 'Cancelado', notaExtra: notaFinal);
            },
            child: const Text('Confirmar Cancelación'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pedido = ModalRoute.of(context)!.settings.arguments as MapaDatos;
    final userId = Supabase.instance.client.auth.currentUser?.id;
    final esElLocalDueno = pedido['local_id'] == userId;

    final direccionDestino = pedido['direccion_entrega'] ?? 'Sin dirección';
    final estado = pedido['estado'] ?? 'Pendiente';
    final monto = (pedido['monto'] as num?)?.toDouble() ?? 0.0;
    final calificacion = pedido['calificacion'];

    final nombreLocal = _perfilLocal?['nombre'] ?? 'Comercio Local';
    final direccionOrigen = _perfilLocal?['direccion'] ?? 'Dirección no registrada';
    final telefonoLocal = _perfilLocal?['telefono'] ?? 'Sin teléfono';
    final rubroLocal = _perfilLocal?['rubro'] ?? 'General';

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del Envío')),
      body: SafeArea(
        child: _cargando
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Chip(
                                  label: Text('Estado: $estado', style: const TextStyle(fontWeight: FontWeight.bold)),
                                ),
                                Chip(
                                  avatar: const Icon(Icons.attach_money, color: Colors.green),
                                  label: Text('\$${monto.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                ),
                              ],
                            ),
                            const Divider(),
                            Row(
                              children: [
                                const Icon(Icons.schedule, size: 18, color: Colors.grey),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text('Despachado: ${_formatearFechaHora(pedido['creado_en'])}', style: const TextStyle(fontSize: 13)),
                                ),
                              ],
                            ),
                            if (pedido['actualizado_en'] != null) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.event_available, size: 18, color: Colors.green),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Última actualización ($estado): ${_formatearFechaHora(pedido['actualizado_en'])}',
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.store, color: Colors.green[700]),
                                const SizedBox(width: 8),
                                const Text('1. Punto de Retiro (Origen)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              ],
                            ),
                            const Divider(),
                            Text('Comercio: $nombreLocal ($rubroLocal)', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text('Dirección: $direccionOrigen', style: const TextStyle(fontSize: 15)),
                            const SizedBox(height: 4),
                            Text('Teléfono: $telefonoLocal', style: const TextStyle(fontSize: 14, color: Colors.black54)),
                            if (!esElLocalDueno && _perfilLocal?['direccion'] != null) ...[
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.directions, color: Colors.blue),
                                  label: const Text('GPS: Ir al Local (Retiro)', style: TextStyle(color: Colors.blue)),
                                  onPressed: () => _abrirRutaMoto(direccionOrigen),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.location_on, color: Colors.red[700]),
                                const SizedBox(width: 8),
                                const Text('2. Punto de Entrega (Destino)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              ],
                            ),
                            const Divider(),
                            Text(direccionDestino, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            Text(
                              'Notas: ${(pedido['notas'] == null || pedido['notas'].toString().isEmpty) ? 'Sin observaciones' : pedido['notas']}',
                              style: const TextStyle(fontSize: 14, color: Colors.black87),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.navigation, color: Colors.green),
                                label: const Text('GPS: Ruta al Cliente (Entrega)', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                                style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.green, width: 1.5)),
                                onPressed: () => _abrirRutaMoto(direccionDestino),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.delivery_dining, color: Colors.blue[800]),
                                const SizedBox(width: 8),
                                const Text('3. Cadete Asignado', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              ],
                            ),
                            const Divider(),
                            if (_perfilCadete == null)
                              const Text(
                                'Todavía ningún cadete tomó este pedido.',
                                style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w600),
                              )
                            else ...[
                              Text('Nombre: ${_perfilCadete!['nombre']}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text('Teléfono: ${_perfilCadete!['telefono'] ?? 'No informado'}', style: const TextStyle(fontSize: 14)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.star, color: Colors.amber, size: 18),
                                  const SizedBox(width: 4),
                                  Text(
                                    _promedioCadete > 0
                                        ? '${_promedioCadete.toStringAsFixed(1)} / 5.0 ($_entregasCadete entregas completadas)'
                                        : 'Sin calificaciones previas ($_entregasCadete entregas)',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ],
                            if (calificacion != null) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Text('Puntuación de este envío: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  ...List.generate(
                                    5,
                                    (i) => Icon(
                                      i < calificacion ? Icons.star : Icons.star_border,
                                      color: Colors.amber,
                                      size: 20,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (!esElLocalDueno) ...[
                      if (estado == 'Pendiente') ...[
                        if (_tieneOtroEnvioActivo)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Ya tenés otro pedido en curso. Entregalo antes de tomar este.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold),
                            ),
                          )
                        else
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.motorcycle),
                              label: const Text('Tomar Pedido (En camino)', style: TextStyle(fontSize: 18)),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                              onPressed: () => _actualizarEstado(pedido['id'], 'En camino'),
                            ),
                          ),
                      ],

                      if (estado == 'En camino' && pedido['cadete_id'] == userId) ...[
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.check_circle),
                            label: const Text('Marcar como Entregado', style: TextStyle(fontSize: 18)),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
                            onPressed: () => _actualizarEstado(pedido['id'], 'Entregado'),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          height: 45,
                          child: TextButton.icon(
                            icon: const Icon(Icons.cancel, color: Colors.red),
                            label: const Text('Reportar Problema / Cancelar', style: TextStyle(color: Colors.red, fontSize: 16)),
                            onPressed: () => _mostrarDialogoCancelar(pedido),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}