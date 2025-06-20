import 'dart:math' as Math;

import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/utilidades.dart';

class ApiService {
  // ✅ CAMBIAR: Nueva URL del servidor global con API key
  static const String _baseUrl = 'http://190.85.61.187:1882';
  static const String _apiKey = 'B800281080147uf'; // ← NUEVA: Clave de API
  
  static Future<Map<String, dynamic>> obtenerDatos() async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final url = Uri.parse('$_baseUrl/datos?apikey=$_apiKey&t=$timestamp');
    
    final headers = {
      'Cache-Control': 'no-cache, no-store, must-revalidate',
      'Pragma': 'no-cache',
      'Expires': '0',
    };
    
    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      print('Datos actualizados: ${response.body}');
      
      final datos = json.decode(response.body);
      
      // ← QUITAR: Ya no simular datos que no existen
      // if (!datos.containsKey('porcentajeEficiencia')) {
      //   datos['porcentajeEficiencia'] = '18.7';
      // }
      // 
      // if (!datos.containsKey('factorDePotencia')) {
      //   datos['factorDePotencia'] = '20.481';
      // }
      
      // NUEVA VALIDACIÓN: Verificar si los datos son válidos
      bool datosValidos = _validarDatos(datos);
      
      if (!datosValidos) {
        print('Datos recibidos pero inválidos (sistema desconectado): ${response.body}');
        throw Exception('Sistema desconectado - datos no disponibles');
      }
      
      return datos;
    } else if (response.statusCode == 403) {
      throw Exception('Acceso denegado - API key inválida');
    } else {
      throw Exception('Error al obtener datos: ${response.statusCode}');
    }
  }
  
  // NUEVA FUNCIÓN: Validar que los datos sean reales
  static bool _validarDatos(Map<String, dynamic> datos) {
    final camposCriticos = [
      'energiaGeneradaHoy',
      'potenciaInstantanea',
      'energiaEsteMes',
      'energiaTotal',
      'energiaEsteAño',
      'energiaMesPasado'
    ];
    
    for (String campo in camposCriticos) {
      final valor = datos[campo];
      
      if (valor == null || 
          valor.toString().isEmpty || 
          valor.toString().toLowerCase().contains('no disponible') ||
          valor.toString().toLowerCase().contains('no available') ||
          valor.toString().trim() == '') {
        print('Campo inválido detectado: $campo = $valor');
        return false;
      }
    }
    
    print('Todos los datos son válidos');
    return true;
  }
  
  // ✅ ACTUALIZAR: Usar nueva API con clave
  static Future<List<Map<String, dynamic>>> obtenerDatosPorHora() async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    // ← CAMBIO: Agregar parámetro para obtener datos cada 10 minutos
    final url = Uri.parse('$_baseUrl/datos/horas?apikey=$_apiKey&precision=10min&t=$timestamp');
    
    final headers = {
      'Cache-Control': 'no-cache, no-store, must-revalidate',
      'Pragma': 'no-cache',
      'Expires': '0',
    };
    
    try {
      print('🔄 Solicitando datos de alta precisión: $url');
      final response = await http.get(url, headers: headers);
      
      print('📡 Status Code: ${response.statusCode}');
      print('📋 Respuesta completa: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('📊 Datos decodificados: $data');
        
        if (data is Map<String, dynamic> && data.containsKey('energiaHoras')) {
          print('✅ Estructura correcta encontrada');
          List<Map<String, dynamic>> datosFormateados = [];
          
          if (data['energiaHoras'] != null && data['energiaHoras'] is List) {
            // Obtener la fecha actual en Colombia
            final fechaHoyColombia = horaActualColombia();
            final fechaHoyStr = '${fechaHoyColombia.year}-${fechaHoyColombia.month.toString().padLeft(2, '0')}-${fechaHoyColombia.day.toString().padLeft(2, '0')}';
            
            print('📅 Fecha de hoy Colombia: $fechaHoyStr');
            
            // ← CAMBIO: Procesar TODOS los puntos de datos (cada 10 minutos)
            List<Map<String, dynamic>> puntosDetallados = [];
            
            for (var item in data['energiaHoras']) {
              try {
                DateTime timestampUTC = DateTime.parse(item['timestamp']);
                DateTime timestampColombia = timestampUTC.subtract(Duration(hours: 5));
                
                // Verificar si es del día actual
                String fechaItem = '${timestampColombia.year}-${timestampColombia.month.toString().padLeft(2, '0')}-${timestampColombia.day.toString().padLeft(2, '0')}';
                
                if (fechaItem == fechaHoyStr) {
                  int hora = timestampColombia.hour;
                  int minuto = timestampColombia.minute;
                  
                  // Filtro: Solo horas entre 6 AM (6) y 7 PM (19)
                  if (hora >= 6 && hora <= 19) {
                    double energia = (item['energia'] ?? 0).toDouble();
                    
                    // ← NUEVO: Crear timestamp exacto con hora y minuto
                    double timestampDecimal = hora + (minuto / 60.0); // Ejemplo: 14.5 = 2:30 PM
                    
                    puntosDetallados.add({
                      'hora': hora,
                      'minuto': minuto,
                      'timestampDecimal': timestampDecimal,
                      'energia': energia,
                      'timestamp': timestampColombia.millisecondsSinceEpoch,
                    });
                    
                    print('⏰ Punto: ${hora}:${minuto.toString().padLeft(2, '0')} (${timestampDecimal.toStringAsFixed(2)}) - Energía: ${energia.toStringAsFixed(2)}');
                  } else {
                    print('🌙 Hora: $hora:$minuto (fuera del rango 6-19) - ignorando');
                  }
                }
              } catch (e) {
                print('❌ Error procesando timestamp ${item['timestamp']}: $e');
              }
            }
            
            // ← ORDENAR por timestamp decimal para línea suave
            puntosDetallados.sort((a, b) => a['timestampDecimal'].compareTo(b['timestampDecimal']));
            
            // ← NUEVO: Si no hay suficientes puntos, interpolar para suavizar
            if (puntosDetallados.length < 10) {
              print('⚠️ Pocos puntos disponibles (${puntosDetallados.length}), manteniendo datos reales');
              return puntosDetallados;
            }
            
            // ← CREAR puntos interpolados para mayor suavidad (opcional)
            List<Map<String, dynamic>> puntosInterpolados = [];
            
            for (int i = 0; i < puntosDetallados.length - 1; i++) {
              var puntoActual = puntosDetallados[i];
              var puntoSiguiente = puntosDetallados[i + 1];
              
              // Agregar punto actual
              puntosInterpolados.add(puntoActual);
              
              // ← INTERPOLAR puntos intermedios si hay más de 20 minutos de diferencia
              double diferenciaMinutos = (puntoSiguiente['timestampDecimal'] - puntoActual['timestampDecimal']) * 60;
              
              if (diferenciaMinutos > 20) {
                // Crear 1-2 puntos interpolados
                int puntosAInterpolar = (diferenciaMinutos / 15).floor().clamp(1, 3);
                
                for (int j = 1; j <= puntosAInterpolar; j++) {
                  double factor = j / (puntosAInterpolar + 1);
                  double timestampInterpolado = puntoActual['timestampDecimal'] + 
                    (puntoSiguiente['timestampDecimal'] - puntoActual['timestampDecimal']) * factor;
                  double energiaInterpolada = puntoActual['energia'] + 
                    (puntoSiguiente['energia'] - puntoActual['energia']) * factor;
                  
                  int horaInterpolada = timestampInterpolado.floor();
                  int minutoInterpolado = ((timestampInterpolado - horaInterpolada) * 60).round();
                  
                  puntosInterpolados.add({
                    'hora': horaInterpolada,
                    'minuto': minutoInterpolado,
                    'timestampDecimal': timestampInterpolado,
                    'energia': energiaInterpolada,
                    'timestamp': DateTime.now().millisecondsSinceEpoch,
                    'interpolado': true, // Marcar como interpolado
                  });
                  
                  print('🔄 Punto interpolado: ${horaInterpolada}:${minutoInterpolado.toString().padLeft(2, '0')} - Energía: ${energiaInterpolada.toStringAsFixed(2)}');
                }
              }
            }
            
            // Agregar último punto
            if (puntosDetallados.isNotEmpty) {
              puntosInterpolados.add(puntosDetallados.last);
            }
            
            print('📊 Datos de alta precisión procesados: ${puntosInterpolados.length} puntos (${puntosDetallados.length} reales)');
            
            return puntosInterpolados.isEmpty ? [] : puntosInterpolados;
          }
        }
        
        throw Exception('Estructura de datos no reconocida');
      } else if (response.statusCode == 403) {
        throw Exception('Acceso denegado - API key inválida');
      } else {
        throw Exception('Error al obtener datos por hora: ${response.statusCode}');
      }
    } catch (e) {
      print('💥 Excepción completa: $e');
      throw Exception('Error de conexión en datos por hora: $e');
    }
  }

  // ✅ ACTUALIZAR: Usar nueva API con clave - datos por mes
  static Future<List<Map<String, dynamic>>> obtenerDatosPorMes() async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    // ✅ CAMBIAR: Agregar API key a la URL
    final url = Uri.parse('$_baseUrl/datos/mes?apikey=$_apiKey&t=$timestamp');
    
    final headers = {
      'Cache-Control': 'no-cache, no-store, must-revalidate',
      'Pragma': 'no-cache',
      'Expires': '0',
    };
    
    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      print('Datos mensuales actualizados: ${response.body}');
      final data = json.decode(response.body);
      
      // Procesar los datos de la nueva estructura
      List<Map<String, dynamic>> datosFormateados = [];
      
      if (data['energiaDias'] != null) {
        // ✅ MEJORADO: Filtrar por el mes actual en Colombia
        final fechaActualColombia = horaActualColombia();
        final mesActual = fechaActualColombia.month;
        final anioActual = fechaActualColombia.year;
        
        print('📅 Filtrando por mes actual: $mesActual/$anioActual');
        
        for (var item in data['energiaDias']) {
          try {
            // Extraer el día de la fecha
            DateTime fecha = DateTime.parse(item['fecha']);
            
            // ✅ CORREGIDO: Solo incluir datos del mes actual
            if (fecha.month == mesActual && fecha.year == anioActual) {
              int dia = fecha.day;
              double energia = (item['energia'] ?? 0).toDouble();
              
              datosFormateados.add({
                'dia': dia,
                'energia': energia,
                'timestamp': fecha.millisecondsSinceEpoch
              });
              
              print('✅ Incluido día $dia del mes actual con energía $energia');
            }
          } catch (e) {
            print('❌ Error procesando fecha ${item['fecha']}: $e');
          }
        }
      }
      
      print('Datos mensuales procesados: ${datosFormateados.length} registros');
      return datosFormateados;
    } else if (response.statusCode == 403) {
      // ✅ NUEVO: Manejar error de acceso denegado
      throw Exception('Acceso denegado - API key inválida');
    } else {
      throw Exception('Error al obtener datos mensuales: ${response.statusCode}');
    }
  }

  // ✅ ACTUALIZAR: Usar nueva API con clave - datos por año
  static Future<List<Map<String, dynamic>>> obtenerDatosPorAnio() async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    // ✅ CAMBIAR: Agregar API key a la URL
    final url = Uri.parse('$_baseUrl/datos/anio?apikey=$_apiKey&t=$timestamp');
    
    final headers = {
      'Cache-Control': 'no-cache, no-store, must-revalidate',
      'Pragma': 'no-cache',
      'Expires': '0',
    };
    
    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      print('Datos anuales actualizados: ${response.body}');
      final data = json.decode(response.body);
      
      // Procesar los datos de la nueva estructura
      List<Map<String, dynamic>> datosFormateados = [];
      
      if (data['energiaMeses'] != null) {
        // ✅ MEJORADO: Filtrar por el año actual en Colombia
        final fechaActualColombia = horaActualColombia();
        final anioActual = fechaActualColombia.year;
        
        print('📅 Filtrando por año actual: $anioActual');
        
        for (var item in data['energiaMeses']) {
          try {
            // Extraer el mes de la cadena "2025-01"
            String mesStr = item['mes'];
            List<String> partes = mesStr.split('-');
            int anio = int.parse(partes[0]);
            int mes = int.parse(partes[1]);
            
            // ✅ CORREGIDO: Solo incluir datos del año actual
            if (anio == anioActual) {
              double energia = (item['energia'] ?? 0).toDouble();
              
              datosFormateados.add({
                'mes': mes,
                'energia': energia,
                'timestamp': DateTime(anio, mes, 1).millisecondsSinceEpoch
              });
              
              print('✅ Incluido mes $mes del año actual con energía $energia');
            }
          } catch (e) {
            print('❌ Error procesando mes ${item['mes']}: $e');
          }
        }
      }
      
      print('Datos anuales procesados: ${datosFormateados.length} registros');
      return datosFormateados;
    } else if (response.statusCode == 403) {
      // ✅ NUEVO: Manejar error de acceso denegado
      throw Exception('Acceso denegado - API key inválida');
    } else {
      throw Exception('Error al obtener datos anuales: ${response.statusCode}');
    }
  }

  // ✅ ACTUALIZAR: Función para datos por hora con filtro
  static Future<List<Map<String, dynamic>>> obtenerDatosPorHoraConFiltro(String inicio, String fin) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    // ← CAMBIO: Agregar parámetro de precisión también al filtro
    final url = Uri.parse('$_baseUrl/datos/horas?apikey=$_apiKey&inicio=$inicio&fin=$fin&precision=10min&t=$timestamp');
    
    final headers = {
      'Cache-Control': 'no-cache, no-store, must-revalidate',
      'Pragma': 'no-cache',
      'Expires': '0',
    };
    
    try {
      print('🔄 Solicitando datos filtrados de alta precisión: $url');
      final response = await http.get(url, headers: headers);
      
      print('📡 Status Code: ${response.statusCode}');
      print('📋 Respuesta completa: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('📊 Datos decodificados: $data');
        
        if (data is Map<String, dynamic> && data.containsKey('energiaHoras')) {
          print('✅ Estructura correcta encontrada');
          List<Map<String, dynamic>> datosFormateados = [];
          
          if (data['energiaHoras'] != null && data['energiaHoras'] is List) {
            // Extraer la fecha del parámetro inicio
            DateTime fechaInicio = DateTime.parse(inicio.split('T')[0]);
            final fechaBuscadaStr = '${fechaInicio.year}-${fechaInicio.month.toString().padLeft(2, '0')}-${fechaInicio.day.toString().padLeft(2, '0')}';
            
            print('📅 Fecha buscada desde filtro: $fechaBuscadaStr (inicio: $inicio)');
            
            // ← CAMBIO: Procesar TODOS los puntos detallados
            List<Map<String, dynamic>> puntosDetallados = [];
            
            for (var item in data['energiaHoras']) {
              try {
                DateTime timestampUTC = DateTime.parse(item['timestamp']);
                DateTime timestampColombia = timestampUTC.subtract(Duration(hours: 5));
                
                // Verificar si es de la fecha seleccionada
                String fechaItem = '${timestampColombia.year}-${timestampColombia.month.toString().padLeft(2, '0')}-${timestampColombia.day.toString().padLeft(2, '0')}';
                
                if (fechaItem == fechaBuscadaStr) {
                  int hora = timestampColombia.hour;
                  int minuto = timestampColombia.minute;
                  
                  // Filtro: Solo horas entre 6 AM (6) y 7 PM (19)
                  if (hora >= 6 && hora <= 19) {
                    double energia = (item['energia'] ?? 0).toDouble();
                    
                    // Normalizar si es muy alta
                    if (energia > 12.0) {
                      energia = energia / 10;
                    }
                    
                    // ← NUEVO: Crear timestamp exacto con hora y minuto
                    double timestampDecimal = hora + (minuto / 60.0);
                    
                    puntosDetallados.add({
                      'hora': hora,
                      'minuto': minuto,
                      'timestampDecimal': timestampDecimal,
                      'energia': energia,
                      'timestamp': timestampColombia.millisecondsSinceEpoch,
                    });
                    
                    print('⏰ Punto filtrado: ${hora}:${minuto.toString().padLeft(2, '0')} (${timestampDecimal.toStringAsFixed(2)}) - Energía: ${energia.toStringAsFixed(2)}');
                  }
                }
              } catch (e) {
                print('❌ Error procesando timestamp ${item['timestamp']}: $e');
              }
            }
            
            // ← ORDENAR por timestamp decimal
            puntosDetallados.sort((a, b) => a['timestampDecimal'].compareTo(b['timestampDecimal']));
            
            print('📊 Datos filtrados de alta precisión: ${puntosDetallados.length} puntos para $fechaBuscadaStr');
            
            return puntosDetallados;
          }
        }
        
        throw Exception('Estructura de datos no reconocida');
      } else if (response.statusCode == 403) {
        throw Exception('Acceso denegado - API key inválida');
      } else {
        throw Exception('Error al obtener datos por hora con filtro: ${response.statusCode}');
      }
    } catch (e) {
      print('💥 Error en datos por hora con filtro: $e');
      throw Exception('Error de conexión en datos por hora con filtro: $e');
    }
  }

  // ✅ ACTUALIZAR: Función para datos por mes con filtro
  static Future<List<Map<String, dynamic>>> obtenerDatosPorMesConFiltro(String inicio, String fin) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    // ✅ CAMBIAR: Agregar API key a la URL
    final url = Uri.parse('$_baseUrl/datos/mes?apikey=$_apiKey&inicio=$inicio&fin=$fin&t=$timestamp');
    
    final headers = {
      'Cache-Control': 'no-cache, no-store, must-revalidate',
      'Pragma': 'no-cache',
      'Expires': '0',
    };
    
    try {
      print('🔄 Solicitando datos mensuales filtrados: $inicio a $fin');
      final response = await http.get(url, headers: headers);
      
      print('📡 Status Code mensual: ${response.statusCode}');
      print('📋 Respuesta mensual completa: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('📊 Datos mensuales decodificados: $data');
        
        // Procesar los datos de la nueva estructura
        List<Map<String, dynamic>> datosFormateados = [];
        
        if (data['energiaDias'] != null) {
          // ✅ CORREGIDO: Extraer mes y año del parámetro inicio
          DateTime fechaInicio = DateTime.parse(inicio);
          int mesSeleccionado = fechaInicio.month;
          int anioSeleccionado = fechaInicio.year;
          
          print('📅 Filtrando datos mensuales por: $mesSeleccionado/$anioSeleccionado');
          
          for (var item in data['energiaDias']) {
            try {
              // Extraer el día de la fecha
              DateTime fecha = DateTime.parse(item['fecha']);
              
              print('🔍 Procesando fecha mensual: ${fecha.day}/${fecha.month}/${fecha.year}');
              
              // ✅ CORREGIDO: Solo incluir datos del mes/año seleccionado
              if (fecha.month == mesSeleccionado && fecha.year == anioSeleccionado) {
                int dia = fecha.day;
                double energia = (item['energia'] ?? 0).toDouble();
                
                datosFormateados.add({
                  'dia': dia,
                  'energia': energia,
                  'timestamp': fecha.millisecondsSinceEpoch
                });
                
                print('✅ Incluido día $dia del mes $mesSeleccionado/$anioSeleccionado con energía $energia');
              } else {
                print('❌ Excluido: ${fecha.day}/${fecha.month}/${fecha.year} (esperado: mes $mesSeleccionado/$anioSeleccionado)');
              }
            } catch (e) {
              print('❌ Error procesando fecha mensual ${item['fecha']}: $e');
            }
          }
          
          // ✅ MEJORADO: Si no hay datos del mes seleccionado, NO mostrar datos de otros meses
          if (datosFormateados.isEmpty) {
            print('⚠️ No hay datos para el mes seleccionado: $mesSeleccionado/$anioSeleccionado');
            // No hacer fallback a otros meses - el usuario seleccionó un mes específico
          }
          
          print('📊 Datos mensuales procesados para $mesSeleccionado/$anioSeleccionado: ${datosFormateados.length} registros');
          return datosFormateados;
        }
        
        throw Exception('Estructura de datos mensuales no reconocida');
      } else if (response.statusCode == 403) {
        // ✅ NUEVO: Manejar error de acceso denegado
        throw Exception('Acceso denegado - API key inválida');
      } else {
        throw Exception('Error al obtener datos mensuales con filtro: ${response.statusCode}');
      }
    } catch (e) {
      print('💥 Error en datos mensuales con filtro: $e');
      throw Exception('Error de conexión en datos mensuales con filtro: $e');
    }
  }

  // ✅ ACTUALIZAR: Función para datos por año con filtro
  static Future<List<Map<String, dynamic>>> obtenerDatosPorAnioConFiltro(String inicio, String fin) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    // ✅ CAMBIAR: Agregar API key a la URL
    final url = Uri.parse('$_baseUrl/datos/anio?apikey=$_apiKey&inicio=$inicio&fin=$fin&t=$timestamp');
    
    final headers = {
      'Cache-Control': 'no-cache, no-store, must-revalidate',
      'Pragma': 'no-cache',
      'Expires': '0',
    };
    
    try {
      print('🔄 Solicitando datos anuales filtrados: $inicio a $fin');
      final response = await http.get(url, headers: headers);
      
      print('📡 Status Code anual: ${response.statusCode}');
      print('📋 Respuesta anual completa: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('📊 Datos anuales decodificados: $data');
        
        // Procesar los datos de la nueva estructura
        List<Map<String, dynamic>> datosFormateados = [];
        
        if (data['energiaMeses'] != null) {
          // ✅ CORREGIDO: Extraer año del parámetro inicio
          List<String> partesInicio = inicio.split('-');
          int anioSeleccionado = int.parse(partesInicio[0]);
          
          print('📅 Filtrando datos anuales por año: $anioSeleccionado');
          
          for (var item in data['energiaMeses']) {
            try {
              // Extraer el mes de la cadena "2025-01"
              String mesStr = item['mes'];
              List<String> partes = mesStr.split('-');
              int anio = int.parse(partes[0]);
              int mes = int.parse(partes[1]);
              
              print('🔍 Procesando mes anual: $mes/$anio');
              
              // ✅ CORREGIDO: Solo incluir datos del año seleccionado
              if (anio == anioSeleccionado) {
                double energia = (item['energia'] ?? 0).toDouble();
                
                datosFormateados.add({
                  'mes': mes,
                  'energia': energia,
                  'timestamp': DateTime(anio, mes, 1).millisecondsSinceEpoch
                });
                
                print('✅ Incluido mes $mes del año $anio con energía $energia');
              } else {
                print('❌ Excluido: $mes/$anio (esperado año: $anioSeleccionado)');
              }
            } catch (e) {
              print('❌ Error procesando mes anual ${item['mes']}: $e');
            }
          }
          
          // ✅ MEJORADO: Si no hay datos del año seleccionado, NO mostrar datos de otros años
          if (datosFormateados.isEmpty) {
            print('⚠️ No hay datos para el año seleccionado: $anioSeleccionado');
            // No hacer fallback a otros años - el usuario seleccionó un año específico
          }
          
          print('📊 Datos anuales procesados para $anioSeleccionado: ${datosFormateados.length} registros');
          return datosFormateados;
        }
        
        throw Exception('Estructura de datos anuales no reconocida');
      } else if (response.statusCode == 403) {
        // ✅ NUEVO: Manejar error de acceso denegado
        throw Exception('Acceso denegado - API key inválida');
      } else {
        throw Exception('Error al obtener datos anuales con filtro: ${response.statusCode}');
      }
    } catch (e) {
      print('💥 Error en datos anuales con filtro: $e');
      throw Exception('Error de conexión en datos anuales con filtro: $e');
    }
  }
}
