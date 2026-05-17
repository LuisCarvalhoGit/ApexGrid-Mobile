import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TelemetrySyncService {
  late final Dio _dio;
  final String _baseUrl = 'https://apexgrid-api.onrender.com/api'; 
  final _storage = const FlutterSecureStorage();

  TelemetrySyncService() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
    ));
  }

  Future<bool> uploadRide({
    required String userId,
    required String motorcycleModel,
    required DateTime startTime,
    required DateTime endTime,
    required double totalDistanceKm,
    required double maxSpeedKmh,
    required double maxLeanAngleDegrees,
    required double maxGForce,
    required File csvFile,
  }) async {
    
    // Vai buscar o Token JWT Real ao Cofre Encriptado
    final token = await _storage.read(key: 'jwt_token');
    
    if (token == null) {
      debugPrint("❌ Sincronização cancelada: Sem Token JWT (Sessão não iniciada).");
      return false;
    }

    try {
      final formData = FormData.fromMap({
        'UserId': userId, // Mais tarde podemos ir buscar isto ao JWT!
        'MotorcycleModel': motorcycleModel,
        'StartTime': startTime.toUtc().toIso8601String(),
        'EndTime': endTime.toUtc().toIso8601String(),
        'TotalDistanceKm': totalDistanceKm,
        'MaxSpeedKmh': maxSpeedKmh,
        'MaxLeanAngleDegrees': maxLeanAngleDegrees,
        'MaxGForce': maxGForce,
        'TelemetryFile': await MultipartFile.fromFile(
          csvFile.path,
          filename: csvFile.uri.pathSegments.last,
        ),
      });

      // Dispara para o servidor C# COM o Token Real
      final response = await _dio.post(
        '/rides', 
        data: formData,
        options: Options(
          headers: {
            "Authorization": "Bearer $token", 
          }
        )
      );

      return response.statusCode == 201;

    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        debugPrint("⚠️ BACKEND: Token JWT expirou! O utilizador precisa de fazer Login novamente.");
        // Opcional: Aqui poderíamos disparar o ref.read(authStateProvider.notifier).logout();
      } else {
        debugPrint("❌ Erro grave no upload: ${e.message}");
      }
      return false;
    }
  }
}