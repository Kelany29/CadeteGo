import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String email = '';
  String password = '';
  bool isLoading = false;

  Future<void> iniciarSesion() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => isLoading = true);

      try {
       
        await Supabase.instance.client.auth.signInWithPassword(
          email: email,
          password: password,
        );

        
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      } on AuthException catch (e) {
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message), backgroundColor: Colors.red),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error inesperado: $e'), backgroundColor: Colors.red),
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
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.delivery_dining, size: 100, color: Theme.of(context).primaryColor),
              const SizedBox(height: 20),
              Text('CadeteGO', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
              const SizedBox(height: 40),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder(), prefixIcon: Icon(Icons.email)),
                keyboardType: TextInputType.emailAddress,
                validator: (value) => value!.isEmpty ? 'Ingresá tu correo' : null,
                onSaved: (value) => email = value!,
              ),
              const SizedBox(height: 15),
              TextFormField(
                obscureText: true, 
                decoration: const InputDecoration(labelText: 'Contraseña', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock)),
                validator: (value) => value!.isEmpty ? 'Ingresá tu contraseña' : null,
                onSaved: (value) => password = value!,
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isLoading ? null : iniciarSesion,
                  child: isLoading 
                      ? const CircularProgressIndicator(color: Colors.white) 
                      : const Text('Ingresar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 15),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/register'),
                child: Text('¿No tenés cuenta? Registrate acá', style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 16)),
              )
            ],
          ),
        ),
      ),
    );
  }
}