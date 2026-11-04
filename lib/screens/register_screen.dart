import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  String email = '';
  String password = '';
  bool isLoading = false;

  Future<void> registrarUsuario() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => isLoading = true);

      try {
        // 1. Registra al usuario en Supabase Auth (esto envía el mail automático)
        await Supabase.instance.client.auth.signUp(
          email: email,
          password: password,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('¡Registro exitoso! Revisá tu correo para verificar la cuenta.'),
              backgroundColor: Colors.green,
            ),
          );
          // Lo mandamos de vuelta al Login para que espere ahí
          Navigator.pop(context); 
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
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Correo electrónico', border: OutlineInputBorder()),
                keyboardType: TextInputType.emailAddress,
                validator: (value) => (value == null || !value.contains('@')) ? 'Ingresá un correo válido' : null,
                onSaved: (value) => email = value!,
              ),
              const SizedBox(height: 15),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Contraseña (mínimo 8 caracteres)', border: OutlineInputBorder()),
                obscureText: true,
                validator: (value) => (value == null || value.length < 8) ? 'Mínimo 8 caracteres' : null,
                onSaved: (value) => password = value!,
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