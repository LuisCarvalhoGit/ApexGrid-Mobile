import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../models/session_data_point.dart';

class MapMatchingService {
  static Future<List<LatLng>> snapToRoads(List<SessionDataPoint> timeline) async {
    try {
      // 1. Extrair APENAS pontos GPS únicos
      final uniqueGps = <LatLng>[];
      for (var p in timeline) {
        if (p.latitude != 0 && p.longitude != 0) {
          if (uniqueGps.isEmpty || 
              uniqueGps.last.latitude != p.latitude || 
              uniqueGps.last.longitude != p.longitude) {
            uniqueGps.add(LatLng(p.latitude, p.longitude));
          }
        }
      }

      if (uniqueGps.isEmpty) return [];

      // 2. A API pública falha se tiver >100 coordenadas. Fazemos sampling inteligente
      int step = (uniqueGps.length / 90).ceil().clamp(1, 9999).toInt();
      final sampledPoints = <String>[];
      
      for (int i = 0; i < uniqueGps.length; i += step) {
        sampledPoints.add('${uniqueGps[i].longitude},${uniqueGps[i].latitude}');
      }

      // Garante que o último ponto da viagem não fica de fora
      if (sampledPoints.last != '${uniqueGps.last.longitude},${uniqueGps.last.latitude}') {
         sampledPoints.add('${uniqueGps.last.longitude},${uniqueGps.last.latitude}');
      }

      final String coordinates = sampledPoints.join(';');
      final url = Uri.parse(
        'http://router.project-osrm.org/match/v1/driving/$coordinates?overview=full&geometries=geojson'
      );

      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 'Ok' && data['matchings'].isNotEmpty) {
          final List<dynamic> coords = data['matchings'][0]['geometry']['coordinates'];
          return coords.map((c) => LatLng(c[1].toDouble(), c[0].toDouble())).toList();
        }
      } else {
        print('OSRM falhou com status: ${response.statusCode}. A usar rota normal.');
      }
    } catch (e) {
      print('Erro no Map Matching: $e');
    }
    
    // Fallback: Se não houver internet, devolve a linha normal
    return timeline.where((p) => p.latitude != 0).map((p) => LatLng(p.latitude, p.longitude)).toList();
  }
}