import 'package:http/http.dart' as http;
import 'dart:convert';

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
}
