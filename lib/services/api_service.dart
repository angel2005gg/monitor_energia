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
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final url = Uri.parse('http://192.168.0.11:1880/datos/horas?t=$timestamp');
    
    final headers = {
      'Cache-Control': 'no-cache, no-store, must-revalidate',
      'Pragma': 'no-cache',
      'Expires': '0',
    };
    
    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      print('Datos de horas actualizados: ${response.body}');
      List<dynamic> data = json.decode(response.body);
      return data.map((item) => item as Map<String, dynamic>).toList();
    } else {
      // ← CAMBIAR: NO devolver datos de ejemplo, lanzar excepción
      throw Exception('Error al obtener datos por hora: ${response.statusCode}');
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
    
    print('Generando datos solo para el horario solar desde ${horaInicio}h hasta ${horaFin}h');
    
    // Generar datos SOLO para las horas desde las 6 AM hasta la hora actual
    for (int i = horaInicio; i <= Math.min(horaFin, horaActual); i++) {
      // La energía solo se genera en este rango horario (ya estamos dentro del rango)
      double energiaGenerada = 0.0;
      
      // Simular una curva de generación solar: 
      // - Comienza baja en la mañana
      // - Aumenta hacia el mediodía
      // - Disminuye hacia la tarde
      double horaRelativa = (i - horaInicio).toDouble();
      double factorHora = 1.0 - Math.pow((horaRelativa - 6) / 6, 2); // Factor máximo al mediodía
      
      // Valores de energía simulados que son mayores en horas centrales del día
      energiaGenerada = 3.0 * factorHora + (i % 2 == 0 ? 0.3 : -0.2);
      if (energiaGenerada < 0) energiaGenerada = 0.05; // Valor mínimo para visualización
      
      datos.add({
        'hora': i,
        'energia': energiaGenerada,
        'timestamp': DateTime(ahora.year, ahora.month, ahora.day, i).millisecondsSinceEpoch
      });
    }
    
    print('Generados ${datos.length} registros de datos solares desde las ${horaInicio}h');
    if (datos.isNotEmpty) {
      print('Rango de datos: ${datos.first['hora']}h - ${datos.last['hora']}h');
    }
    
    return datos;
  }

  static Future<List<Map<String, dynamic>>> obtenerDatosPorMes() async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final url = Uri.parse('http://192.168.0.11:1880/datos/mes?t=$timestamp');
    
    final headers = {
      'Cache-Control': 'no-cache, no-store, must-revalidate',
      'Pragma': 'no-cache',
      'Expires': '0',
    };
    
    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      print('Datos mensuales actualizados: ${response.body}');
      List<dynamic> data = json.decode(response.body);
      return data.map((item) => item as Map<String, dynamic>).toList();
    } else {
      // ← CAMBIAR: NO devolver datos de ejemplo, lanzar excepción
      throw Exception('Error al obtener datos mensuales: ${response.statusCode}');
    }
  }

  static Future<List<Map<String, dynamic>>> obtenerDatosPorAnio() async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final url = Uri.parse('http://192.168.0.11:1880/datos/anio?t=$timestamp');
    
    final headers = {
      'Cache-Control': 'no-cache, no-store, must-revalidate',
      'Pragma': 'no-cache',
      'Expires': '0',
    };
    
    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      print('Datos anuales actualizados: ${response.body}');
      List<dynamic> data = json.decode(response.body);
      return data.map((item) => item as Map<String, dynamic>).toList();
    } else {
      // ← CAMBIAR: NO devolver datos de ejemplo, lanzar excepción
      throw Exception('Error al obtener datos anuales: ${response.statusCode}');
    }
  }

  static List<Map<String, dynamic>> _generarDatosMesEjemplo() {
    final List<Map<String, dynamic>> datos = [];
    final DateTime ahora = horaActualColombia();
    final int diaActual = ahora.day;
    
    for (int i = 1; i <= diaActual; i++) {
      double energiaGenerada = 15.0 + (i % 7) * 5.0 + (Math.Random().nextDouble() * 10);
      
      datos.add({
        'dia': i,
        'energia': energiaGenerada,
        'timestamp': DateTime(ahora.year, ahora.month, i).millisecondsSinceEpoch
      });
    }
    
    return datos;
  }

  static List<Map<String, dynamic>> _generarDatosAnioEjemplo() {
    final List<Map<String, dynamic>> datos = [];
    final DateTime ahora = horaActualColombia();
    final int mesActual = ahora.month;
    
    for (int i = 1; i <= mesActual; i++) {
      double energiaGenerada = 200.0 + (i * 25.0) + (Math.Random().nextDouble() * 100);
      
      datos.add({
        'mes': i,
        'energia': energiaGenerada,
        'timestamp': DateTime(ahora.year, i, 1).millisecondsSinceEpoch
      });
    }
    
    return datos;
  }
}
