import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLoginMode = true; // Alterna entre Login e Registo
  bool _isLoading = false;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController(); // Só para Registo

  void _submit() async {
    setState(() => _isLoading = true);

    final authService = ref.read(authServiceProvider);
    final authNotifier = ref.read(authStateProvider.notifier);

    bool success = false;

    if (_isLoginMode) {
      success = await authNotifier.login(_emailController.text, _passwordController.text);
    } else {
      // Tenta Registar
      success = await authService.register(_nameController.text, _emailController.text, _passwordController.text);
      if (success) {
        // Se o registo der certo, faz login automático
        success = await authNotifier.login(_emailController.text, _passwordController.text);
      }
    }

    setState(() => _isLoading = false);

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Erro na autenticação. Verifica os teus dados.'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.motorcycle, size: 80, color: Colors.blueAccent),
              const SizedBox(height: 16),
              Text(
                _isLoginMode ? 'Bem-vindo de volta' : 'Criar Nova Conta',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              
              if (!_isLoginMode) ...[
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nome Completo', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
              ],
              
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(_isLoginMode ? 'ENTRAR' : 'REGISTAR', style: const TextStyle(fontSize: 16)),
              ),
              
              TextButton(
                onPressed: () => setState(() => _isLoginMode = !_isLoginMode),
                child: Text(_isLoginMode ? 'Não tens conta? Regista-te' : 'Já tens conta? Entra aqui'),
              )
            ],
          ),
        ),
      ),
    );
  }
}