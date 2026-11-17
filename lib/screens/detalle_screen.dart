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
  bool _verificando = true;
  bool _tieneOtroEnvioActivo = false;
  bool _yaInicializado = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_yaInicializado) {
      _yaInicializado = true;
      _verificarEstadoCadete();
    }
  }

  Future<void> _verificarEstadoCadete() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    final pedido = ModalRoute.of(context)!.settings.arguments as MapaDatos;

    if (userId != null) {
      final activos = await Supabase.instance.client
          .from('pedidos')
          .select('id')
          .eq('cadete_id', userId)
          .eq('estado', 'En camino');

      final tieneOtro = (activos as List).any((item) => item['id'] != pedido['id']);
      if (mounted) {
        setState(() {
          _tieneOtroEnvioActivo = tieneOtro;
          _verificando = false;
        });
      }
    } else {
      if (mounted) setState(() => _verificando = false);
    }
  }

  // Abre Google Maps con ruta paso a paso en modo moto desde la ubicación GPS actual
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

    final direccion = pedido['direccion_entrega'] ?? 'Sin dirección';
    final estado = pedido['estado'] ?? 'Pendiente';
    final monto = (pedido['monto'] as num?)?.toDouble() ?? 0.0;
    final calificacion = pedido['calificacion'];

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del Envío')),
      body: _verificando
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Dirección de entrega:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.grey)),
                  Text(direccion, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),

                  Row(
                    children: [
                      Chip(
                        avatar: const Icon(Icons.attach_money, color: Colors.green),
                        label: Text('Monto: \$${monto.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                      const SizedBox(width: 10),
                      Chip(
                        label: Text('Estado: $estado', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),

                  const Text('Observaciones:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.grey)),
                  Text(
                    (pedido['notas'] == null || pedido['notas'].toString().isEmpty)
                        ? 'Sin observaciones'
                        : pedido['notas'],
                    style: const TextStyle(fontSize: 16),
                  ),

                  if (calificacion != null) ...[
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        const Text('Calificación del servicio: ', style: TextStyle(fontWeight: FontWeight.bold)),
                        ...List.generate(
                          5,
                          (i) => Icon(
                            i < calificacion ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                            size: 22,
                          ),
                        ),
                      ],
                    ),
                  ],

                  const Spacer(),

                  // Botón de Ruta GPS en Moto (Disponible para ver el recorrido)
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.navigation, color: Colors.green),
                      label: const Text('Iniciar Ruta GPS (Moto)', style: TextStyle(fontSize: 17, color: Colors.green, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.green, width: 2),
                      ),
                      onPressed: () => _abrirRutaMoto(direccion),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Acciones exclusivas del Cadete
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
                      const SizedBox(height: 12),
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
                      const SizedBox(height: 12),
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
    );
  }
}