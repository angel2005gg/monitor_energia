import 'dart:math' as Math;

import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/utilidades.dart';

class ApiService {
  static Future<Map<String, dynamic>> obtenerDatos() async {
    // Añadir parámetro de timestamp para evitar caché
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final url = Uri.parse('http://192.168.0.11:1880/datos?t=$timestamp');
    
    // Establecer headers para evitar caché
    final headers = {
      'Cache-Control': 'no-cache, no-store, must-revalidate',
      'Pragma': 'no-cache',
      'Expires': '0',
    };
    
    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      print('Datos actualizados: ${response.body}'); // Log para depuración
      return json.decode(response.body);
    } else {
      throw Exception('Error al obtener datos: ${response.statusCode}');
    }
  }
  
  static Future<List<Map<String, dynamic>>> obtenerDatosPorHora() async {
    // Añadir parámetro de timestamp para evitar caché
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final url = Uri.parse('http://192.168.0.11:1880/datos/horas?t=$timestamp');
    
    // Establecer headers para evitar caché
    final headers = {
      'Cache-Control': 'no-cache, no-store, must-revalidate',
      'Pragma': 'no-cache',
      'Expires': '0',
    };
    
    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        print('Datos de horas actualizados: ${response.body}'); // Log para depuración
        List<dynamic> data = json.decode(response.body);
        return data.map((item) => item as Map<String, dynamic>).toList();
      } else {
        throw Exception('Error al obtener datos por hora: ${response.statusCode}');
      }
    } catch (e) {
      // Si no hay datos reales, devolver datos de ejemplo para desarrollo
      print('Error al obtener datos por hora: $e');
      return _generarDatosEjemplo();
    }
  }
  
  // Función mejorada para generar datos de ejemplo adaptados a horario solar
  static List<Map<String, dynamic>> _generarDatosEjemplo() {
    final List<Map<String, dynamic>> datos = [];
    
    // Obtener hora actual de Colombia
    final DateTime ahora = horaActualColombia();
    final int horaActual = ahora.hour;
    
    // Hora de inicio de generación solar (6 AM)
    final int horaInicio = 6;
    
    // Hora fin de generación solar (6 PM)
    final int horaFin = 18;
    
    print('Generando datos para el horario solar desde ${horaInicio}h hasta máximo ${horaFin}h');
    
    // Generar datos para todas las horas del día (para mantener la escala completa)
    for (int i = 0; i < 24; i++) {
      // Solo incluir datos hasta la hora actual
      if (i <= horaActual) {
        // La energía solo se genera entre las 6 AM y 6 PM
        double energiaGenerada = 0.0;
        
        if (i >= horaInicio && i <= horaFin) {
          // Simular una curva de generación solar: 
          // - Comienza baja en la mañana
          // - Aumenta hacia el mediodía
          // - Disminuye hacia la tarde
          double horaRelativa = (i - horaInicio).toDouble(); // Corregido: usar .toDouble() en lugar de as double
          double factorHora = 1.0 - Math.pow((horaRelativa - 6) / 6, 2); // Factor máximo al mediodía
          
          // Valores de energía simulados que son mayores en horas centrales del día
          energiaGenerada = 3.0 * factorHora + (i % 2 == 0 ? 0.3 : -0.2);
        }
        
        datos.add({
          'hora': i,
          'energia': energiaGenerada,
          'timestamp': DateTime(ahora.year, ahora.month, ahora.day, i).millisecondsSinceEpoch
        });
      }
    }
    
    print('Generados ${datos.length} registros de datos');
    return datos;
  }
}
