import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Datos comunes
  String email = '';
  String password = '';
  String nombre = '';
  String telefono = '';
  String rol = 'cadete'; 

  // Datos específicos para locales
  String direccion = '';
  String rubro = '';

  bool isLoading = false;

Future<void> registrarUsuario() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => isLoading = true);

      try {
        // Enviamos todos los datos en 'data'; el Trigger de Supabase armará el perfil solo
        await Supabase.instance.client.auth.signUp(
          email: email,
          password: password,
          emailRedirectTo: 'cadetego://login-callback',
          data: {
            'rol': rol,
            'nombre': nombre,
            'telefono': telefono,
            'direccion': rol == 'local' ? direccion : null,
            'rubro': rol == 'local' ? rubro : null,
          },
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('¡Registro exitoso! Ya podés iniciar sesión.'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context); // Vuelve al login
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al registrar: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => isLoading = false);
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear Cuenta')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              
              Image.asset('assets/logo.jpg', height: 120),
              const SizedBox(height: 20),
              Text(
                'Unirse a CadeteGO',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
              ),
              const SizedBox(height: 20),

             
              DropdownButtonFormField<String>(
                value: rol,
                decoration: const InputDecoration(labelText: '¿Qué tipo de usuario sos?', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'cadete', child: Text('Soy Cadete (Repartidor)')),
                  DropdownMenuItem(value: 'local', child: Text('Tengo un Local Comercial')),
                ],
                onChanged: (val) {
                  setState(() {
                    rol = val!;
                  });
                },
              ),
              const SizedBox(height: 15),

              // Datos comunes
              TextFormField(
                decoration: InputDecoration(
                  labelText: rol == 'local' ? 'Nombre del Local' : 'Nombre Completo',
                  border: const OutlineInputBorder(),
                ),
                validator: (val) => val!.isEmpty ? 'Completá este campo' : null,
                onSaved: (val) => nombre = val!,
              ),
              const SizedBox(height: 15),

              TextFormField(
                decoration: const InputDecoration(labelText: 'Teléfono', border: OutlineInputBorder()),
                keyboardType: TextInputType.phone,
                validator: (val) => val!.isEmpty ? 'Completá tu teléfono' : null,
                onSaved: (val) => telefono = val!,
              ),
              const SizedBox(height: 15),

              // Campos exclusivos para locales (Aparición dinámica)
              if (rol == 'local') ...[
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Dirección del Local', border: OutlineInputBorder()),
                  validator: (val) => val!.isEmpty ? 'Completá la ubicación' : null,
                  onSaved: (val) => direccion = val!,
                ),
                const SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Rubro del Local', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'Hamburguesería / Fast Food', child: Text('Hamburguesería / Fast Food')),
                    DropdownMenuItem(value: 'Kiosco', child: Text('Kiosco')),
                    DropdownMenuItem(value: 'Pizzería', child: Text('Pizzería')),
                    DropdownMenuItem(value: 'Almacén / Verdulería', child: Text('Almacén / Verdulería')),
                    DropdownMenuItem(value: 'Otro', child: Text('Otro')),
                  ],
                  validator: (val) => val == null ? 'Seleccioná un rubro' : null,
                  onChanged: (val) => setState(() => rubro = val!),
                ),
                const SizedBox(height: 15),
              ],

              TextFormField(
                decoration: const InputDecoration(labelText: 'Correo electrónico', border: OutlineInputBorder()),
                keyboardType: TextInputType.emailAddress,
                validator: (val) => !val!.contains('@') ? 'Correo no válido' : null,
                onSaved: (val) => email = val!,
              ),
              const SizedBox(height: 15),

              TextFormField(
                decoration: const InputDecoration(labelText: 'Contraseña (mínimo 8 caracteres)', border: OutlineInputBorder()),
                obscureText: true,
                validator: (val) => val!.length < 8 ? 'Mínimo 8 caracteres' : null,
                onSaved: (val) => password = val!,
              ),
              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isLoading ? null : registrarUsuario,
                  child: isLoading 
                      ? const CircularProgressIndicator(color: Colors.white) 
                      : const Text('Registrarse', style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
