import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/session_data_point.dart'; // O novo import

class CsvStorageService {
  
  Future<String> saveSession(List<SessionDataPoint> buffer) async {
    final directory = await getApplicationDocumentsDirectory();
    // Usamos a data atual para dar um nome único ao ficheiro
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'apexgrid_telemetry_$timestamp.csv';
    final file = File('${directory.path}/$fileName');

    final bufferOut = StringBuffer();
    
    // 1. O Cabeçalho (Gold Standard para importação em Python/Excel)
    bufferOut.writeln('Time(ms),LeanAngle(deg),GForce_Lat(X),GForce_Accel(Y),Latitude,Longitude,Speed(kmh)');

    // 2. Escrever os dados formatados
    for (final point in buffer) {
      bufferOut.writeln(
        '${point.timeMs},'
        '${point.leanAngle.toStringAsFixed(2)},'
        '${point.gForceX.toStringAsFixed(3)},'
        '${point.gForceY.toStringAsFixed(3)},'
        '${point.latitude},'
        '${point.longitude},'
        '${point.speedKmh.toStringAsFixed(1)}'
      );
    }

    // 3. Guardar em disco de uma só vez (I/O eficiente)
    await file.writeAsString(bufferOut.toString());
    return file.path;
  }
}