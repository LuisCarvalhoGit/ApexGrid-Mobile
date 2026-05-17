import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../services/auth_service.dart';

// Provemos o AuthService para toda a app
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

// Este provider gere o estado da sessão (true = logado, false = não logado)
final authStateProvider = StateNotifierProvider<AuthNotifier, bool>((ref) {
  return AuthNotifier(ref.read(authServiceProvider));
});

class AuthNotifier extends StateNotifier<bool> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(false) {
    checkAuthStatus();
  }

  // Verifica se há um token trancado no cofre ao abrir a app
  Future<void> checkAuthStatus() async {
    final token = await _authService.getToken();
    state = token != null; // Se tiver token, muda o estado para true (Logado)
  }

  Future<bool> login(String email, String password) async {
    final success = await _authService.login(email, password);
    if (success) state = true;
    return success;
  }

  Future<void> logout() async {
    await _authService.logout();
    state = false;
  }
}