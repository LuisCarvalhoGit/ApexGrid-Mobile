import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class TelemetrySyncService {

  late final Dio _dio;

  // Telemovel de DEBUG na mesma rede, Usar IP do PC na rede Wi-Fi (ex: 'http://192.168.1.65:5144/api')
  final String _baseUrl = "http://192.168.1.174:5144/api";

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

    try {

      // Criar o envelope Multipart correspondente ao UploadRideRequest do C#
      final formData = FormData.fromMap({
        'UserId': userId,
        'MotorcycleModel': motorcycleModel,
        // O C# espera datas no formato ISO 8601
        'StartTime': startTime.toUtc().toIso8601String(),
        'EndTime': endTime.toUtc().toIso8601String(),
        'TotalDistanceKm': totalDistanceKm,
        'MaxSpeedKmh': maxSpeedKmh,
        'MaxLeanAngleDegrees': maxLeanAngleDegrees,
        'MaxGForce': maxGForce,
        // O ficheiro físico a ser anexado
        'TelemetryFile': await MultipartFile.fromFile(
          csvFile.path,
          filename: csvFile.uri.pathSegments.last, // Extrai o nome do ficheiro (ex: ride_01.csv)
        ),
      });

      final response = await _dio.post("/rides", data: formData);

      // Validar
      if (response.statusCode == 201) {
        debugPrint('✅ Viagem sincronizada com sucesso! ID gerado: ${response.data['id']}');
        return true;
      }

      return false;

    } on DioException catch (e) {
      // Tratamento de erros
      debugPrint('❌ Erro de rede ao sincronizar: ${e.message}');
      if (e.response != null) {
        debugPrint('❌ Detalhes do servidor: ${e.response?.data}');
      }
      return false;
    } catch (e) {
      debugPrint('❌ Erro inesperado no telemóvel: $e');
      return false;
    }
    
  }
}