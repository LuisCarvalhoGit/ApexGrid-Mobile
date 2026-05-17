import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  final Dio _dio = Dio();
  final _storage = const FlutterSecureStorage();
  
  // O IP real do PC onde a API C# está a correr
  final String _baseUrl = 'https://apexgrid-api.onrender.com/api/Auth'; 

  // Chaves para o Secure Storage
  static const String _tokenKey = 'jwt_token';
  static const String _userNameKey = 'user_name';

  Future<bool> register(String name, String email, String password) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/register',
        data: {
          'name': name,
          'email': email,
          'password': password,
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("❌ Erro no Registo: $e");
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final token = response.data['token'];
        final name = response.data['name'];

        // Guardar o Token e o Nome no chip encriptado do telemóvel!
        await _storage.write(key: _tokenKey, value: token);
        await _storage.write(key: _userNameKey, value: name);
        
        debugPrint("✅ Login efetuado! Token trancado no cofre.");
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("❌ Erro no Login: $e");
      return false;
    }
  }

  // Função para ler o Token quando precisarmos de enviar uma viagem
  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  // Função para fazer Logout
  Future<void> logout() async {
    await _storage.deleteAll();
    debugPrint("👋 Logout efetuado. Cofre limpo.");
  }
}