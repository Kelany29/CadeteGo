import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

typedef MapaDatos = Map < String , dynamic >;

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  MapaDatos? _perfil;
  bool _cargando = true;
  int _entregasCompletadas = 0;
  double _promedioEstrellas = 0.0;
  int _cantidadCalificaciones = 0;

  @override
  void initState() {
    super.initState();
    _cargarPerfil();
  }

  Future<void> _cargarPerfil() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final data = await Supabase.instance.client
          .from('perfiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      int completadas = 0;
      double promedio = 0.0;
      int cantCalif = 0;

      if (data != null && data['rol'] == 'cadete') {
        final entregas = await Supabase.instance.client
            .from('pedidos')
            .select('calificacion')
            .eq('cadete_id', user.id)
            .eq('estado', 'Entregado');

        final lista = entregas as List;
        completadas = lista.length;

        double suma = 0;
        for (final e in lista) {
          if (e['calificacion'] != null) {
            suma += (e['calificacion'] as num).toDouble();
            cantCalif++;
          }
        }
        if (cantCalif > 0) {
          promedio = suma / cantCalif;
        }
      }

      if (mounted) {
        setState(() {
          _perfil = data;
          _entregasCompletadas = completadas;
          _promedioEstrellas = promedio;
          _cantidadCalificaciones = cantCalif;
          _cargando = false;
        });
      }
    } else {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _cerrarSesion() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = Supabase.instance.client.auth.currentUser?.email ?? 'Sin correo';
    final rol = (_perfil?['rol'] ?? '').toString().toUpperCase();

    return Scaffold(
      appBar: AppBar(title: const Text('Mi Perfil')),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 45,
                      backgroundColor: Theme.of(context).primaryColor,
                      child: Icon(
                        rol == 'LOCAL' ? Icons.store : Icons.delivery_dining,
                        size: 50,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Tarjeta de Reputación para el Cadete
                  if (rol == 'CADETE')
                    Card(
                      color: Colors.amber[50],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.amber[300]!),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.star, color: Colors.amber, size: 26),
                                    const SizedBox(width: 4),
                                    Text(
                                      _cantidadCalificaciones > 0
                                          ? _promedioEstrellas.toStringAsFixed(1)
                                          : 'Nuevo',
                                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                Text(
                                  _cantidadCalificaciones > 0
                                      ? '$_cantidadCalificaciones reseña(s)'
                                      : 'Sin reseñas aún',
                                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                                ),
                              ],
                            ),
                            Container(height: 35, width: 1, color: Colors.amber[300]),
                            Column(
                              children: [
                                Text(
                                  '$_entregasCompletadas',
                                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green[800]),
                                ),
                                const Text(
                                  'Entregas realizadas',
                                  style: TextStyle(fontSize: 12, color: Colors.black54),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 20),
                  Text(
                    'Nombre: ${_perfil?['nombre'] ?? 'Usuario'}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text('Rol: $rol', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 10),
                  Text('Correo: $email', style: const TextStyle(fontSize: 16)),
                  if (_perfil?['telefono'] != null) ...[
                    const SizedBox(height: 10),
                    Text('Teléfono: ${_perfil!['telefono']}', style: const TextStyle(fontSize: 16)),
                  ],
                  if (rol == 'LOCAL') ...[
                    const SizedBox(height: 10),
                    Text('Rubro: ${_perfil?['rubro'] ?? '-'}', style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 10),
                    Text('Dirección: ${_perfil?['direccion'] ?? '-'}', style: const TextStyle(fontSize: 16)),
                  ],
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.logout),
                      label: const Text('Cerrar Sesión', style: TextStyle(fontSize: 18)),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700]),
                      onPressed: _cerrarSesion,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}