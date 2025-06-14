import 'dart:math' as Math;

import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/utilidades.dart';

class ApiService {
  // Cambiar la IP del servidor
  static const String _baseUrl = 'http://10.10.10.5:1880';
  
  static Future<Map<String, dynamic>> obtenerDatos() async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final url = Uri.parse('$_baseUrl/datos?t=$timestamp');
    
    final headers = {
      'Cache-Control': 'no-cache, no-store, must-revalidate',
      'Pragma': 'no-cache',
      'Expires': '0',
    };
    
    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      print('Datos actualizados: ${response.body}');
      
      final datos = json.decode(response.body);
      
      // NUEVA VALIDACIÓN: Verificar si los datos son válidos
      bool datosValidos = _validarDatos(datos);
      
      if (!datosValidos) {
        print('Datos recibidos pero inválidos (sistema desconectado): ${response.body}');
        throw Exception('Sistema desconectado - datos no disponibles');
      }
      
      return datos;
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
  
  // ACTUALIZADO: Usar nueva API de datos por hora
  static Future<List<Map<String, dynamic>>> obtenerDatosPorHora() async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final url = Uri.parse('$_baseUrl/datos/horas?t=$timestamp');
    
    final headers = {
      'Cache-Control': 'no-cache, no-store, must-revalidate',
      'Pragma': 'no-cache',
      'Expires': '0',
    };
    
    try {
      print('🔄 Solicitando datos de: $url');
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
            // NUEVO: Obtener la fecha actual en Colombia
            final fechaHoyColombia = horaActualColombia();
            final fechaHoyStr = '${fechaHoyColombia.year}-${fechaHoyColombia.month.toString().padLeft(2, '0')}-${fechaHoyColombia.day.toString().padLeft(2, '0')}';
            
            print('📅 Fecha de hoy Colombia: $fechaHoyStr');
            
            // NUEVO: Procesar y agrupar datos por hora del día actual
            Map<int, double> energiaPorHora = {};
            
            for (var item in data['energiaHoras']) {
              try {
                DateTime timestampUTC = DateTime.parse(item['timestamp']);
                DateTime timestampColombia = timestampUTC.subtract(Duration(hours: 5)); // Convertir a Colombia
                
                // Verificar si es del día actual
                String fechaItem = '${timestampColombia.year}-${timestampColombia.month.toString().padLeft(2, '0')}-${timestampColombia.day.toString().padLeft(2, '0')}';
                
                print('🔍 Procesando: $timestampUTC -> $timestampColombia (fecha: $fechaItem)');
                
                if (fechaItem == fechaHoyStr) {
                  int hora = timestampColombia.hour;
                  double energia = (item['energia'] ?? 0).toDouble();
                  
                  // Si ya existe datos para esta hora, sumar la energía
                  if (energiaPorHora.containsKey(hora)) {
                    energiaPorHora[hora] = energiaPorHora[hora]! + energia;
                  } else {
                    energiaPorHora[hora] = energia;
                  }
                  
                  print('⏰ Hora: $hora, Energía acumulada: ${energiaPorHora[hora]}');
                } else {
                  print('❌ Dato no es de hoy: $fechaItem (esperado: $fechaHoyStr)');
                }
              } catch (e) {
                print('❌ Error procesando timestamp ${item['timestamp']}: $e');
              }
            }
            
            // NUEVO: Convertir el mapa a lista ordenada
            List<int> horasOrdenadas = energiaPorHora.keys.toList()..sort();
            
            for (int hora in horasOrdenadas) {
              datosFormateados.add({
                'hora': hora,
                'energia': energiaPorHora[hora]!,
                'timestamp': DateTime.now().millisecondsSinceEpoch
              });
            }
            
            // Si no hay datos del día actual, mostrar los datos más recientes
            if (datosFormateados.isEmpty) {
              print('⚠️ No hay datos del día actual, usando datos más recientes...');
              
              // Encontrar la fecha más reciente
              DateTime fechaMasReciente = DateTime(2000);
              for (var item in data['energiaHoras']) {
                try {
                  DateTime timestampUTC = DateTime.parse(item['timestamp']);
                  DateTime timestampColombia = timestampUTC.subtract(Duration(hours: 5));
                  
                  if (timestampColombia.isAfter(fechaMasReciente)) {
                    fechaMasReciente = timestampColombia;
                  }
                } catch (e) {
                  // Ignorar timestamps malformados
                }
              }
              
              // Obtener todos los datos de la fecha más reciente
              String fechaMasRecienteStr = '${fechaMasReciente.year}-${fechaMasReciente.month.toString().padLeft(2, '0')}-${fechaMasReciente.day.toString().padLeft(2, '0')}';
              print('📅 Usando datos de la fecha más reciente: $fechaMasRecienteStr');
              
              Map<int, double> energiaPorHoraMasReciente = {};
              
              for (var item in data['energiaHoras']) {
                try {
                  DateTime timestampUTC = DateTime.parse(item['timestamp']);
                  DateTime timestampColombia = timestampUTC.subtract(Duration(hours: 5));
                  
                  String fechaItem = '${timestampColombia.year}-${timestampColombia.month.toString().padLeft(2, '0')}-${timestampColombia.day.toString().padLeft(2, '0')}';
                  
                  if (fechaItem == fechaMasRecienteStr) {
                    int hora = timestampColombia.hour;
                    double energia = (item['energia'] ?? 0).toDouble();
                    
                    if (energiaPorHoraMasReciente.containsKey(hora)) {
                      energiaPorHoraMasReciente[hora] = energiaPorHoraMasReciente[hora]! + energia;
                    } else {
                      energiaPorHoraMasReciente[hora] = energia;
                    }
                  }
                } catch (e) {
                  // Ignorar errores
                }
              }
              
              // Convertir a lista
              List<int> horasOrdenadasMasReciente = energiaPorHoraMasReciente.keys.toList()..sort();
              
              for (int hora in horasOrdenadasMasReciente) {
                datosFormateados.add({
                  'hora': hora,
                  'energia': energiaPorHoraMasReciente[hora]!,
                  'timestamp': DateTime.now().millisecondsSinceEpoch
                });
              }
            }
            
            print('📊 Datos formateados finales: $datosFormateados');
            print('📊 Total de datos procesados: ${datosFormateados.length}');
            
            return datosFormateados;
          }
        }
        
        throw Exception('Estructura de datos no reconocida');
      } else {
        throw Exception('Error al obtener datos por hora: ${response.statusCode}');
      }
    } catch (e) {
      print('💥 Excepción completa: $e');
      throw Exception('Error de conexión en datos por hora: $e');
    }
  }

  // ACTUALIZADO: Usar nueva API de datos por mes - MEJORAR LA FUNCIÓN ORIGINAL TAMBIÉN
  static Future<List<Map<String, dynamic>>> obtenerDatosPorMes() async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final url = Uri.parse('$_baseUrl/datos/mes?t=$timestamp');
    
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
    } else {
      throw Exception('Error al obtener datos mensuales: ${response.statusCode}');
    }
  }

  // ACTUALIZADO: Usar nueva API de datos por año - MEJORAR LA FUNCIÓN ORIGINAL TAMBIÉN
  static Future<List<Map<String, dynamic>>> obtenerDatosPorAnio() async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final url = Uri.parse('$_baseUrl/datos/anio?t=$timestamp');
    
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
    } else {
      throw Exception('Error al obtener datos anuales: ${response.statusCode}');
    }
  }

  // ← AGREGAR estas nuevas funciones al ApiService

  // Función para datos por hora con filtro
  static Future<List<Map<String, dynamic>>> obtenerDatosPorHoraConFiltro(String inicio, String fin) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final url = Uri.parse('$_baseUrl/datos/horas?inicio=$inicio&fin=$fin&t=$timestamp');
    
    final headers = {
      'Cache-Control': 'no-cache, no-store, must-revalidate',
      'Pragma': 'no-cache',
      'Expires': '0',
    };
    
    try {
      print('🔄 Solicitando datos filtrados de: $url');
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
            // ✅ CORREGIDO: Extraer la fecha del parámetro inicio en lugar de usar hoy
            DateTime fechaInicio = DateTime.parse(inicio.split('T')[0]);
            final fechaBuscadaStr = '${fechaInicio.year}-${fechaInicio.month.toString().padLeft(2, '0')}-${fechaInicio.day.toString().padLeft(2, '0')}';
            
            print('📅 Fecha buscada desde filtro: $fechaBuscadaStr (inicio: $inicio)');
            
            // ✅ CORREGIDO: Procesar y agrupar datos por hora de la fecha seleccionada
            Map<int, double> energiaPorHora = {};
            
            for (var item in data['energiaHoras']) {
              try {
                DateTime timestampUTC = DateTime.parse(item['timestamp']);
                DateTime timestampColombia = timestampUTC.subtract(Duration(hours: 5)); // Convertir a Colombia
                
                // ✅ CORREGIDO: Verificar si es de la fecha seleccionada (no siempre hoy)
                String fechaItem = '${timestampColombia.year}-${timestampColombia.month.toString().padLeft(2, '0')}-${timestampColombia.day.toString().padLeft(2, '0')}';
                
                print('🔍 Procesando: $timestampUTC -> $timestampColombia (fecha: $fechaItem)');
                
                if (fechaItem == fechaBuscadaStr) { // ✅ CAMBIO PRINCIPAL: Comparar con fecha seleccionada
                  int hora = timestampColombia.hour;
                  double energia = (item['energia'] ?? 0).toDouble();
                  
                  // Si ya existe datos para esta hora, sumar la energía
                  if (energiaPorHora.containsKey(hora)) {
                    energiaPorHora[hora] = energiaPorHora[hora]! + energia;
                  } else {
                    energiaPorHora[hora] = energia;
                  }
                  
                  print('⏰ Hora: $hora, Energía acumulada: ${energiaPorHora[hora]}');
                } else {
                  print('❌ Dato no es de la fecha buscada: $fechaItem (esperado: $fechaBuscadaStr)');
                }
              } catch (e) {
                print('❌ Error procesando timestamp ${item['timestamp']}: $e');
              }
            }
            
            // ✅ CORREGIDO: Convertir el mapa a lista ordenada
            List<int> horasOrdenadas = energiaPorHora.keys.toList()..sort();
            
            for (int hora in horasOrdenadas) {
              datosFormateados.add({
                'hora': hora,
                'energia': energiaPorHora[hora]!,
                'timestamp': DateTime.now().millisecondsSinceEpoch
              });
            }
            
            // ✅ MEJORADO: Si no hay datos de la fecha seleccionada, NO mostrar datos de otras fechas
            if (datosFormateados.isEmpty) {
              print('⚠️ No hay datos para la fecha seleccionada: $fechaBuscadaStr');
              // No hacer fallback a otras fechas - el usuario seleccionó una fecha específica
            }
            
            print('📊 Datos formateados finales para $fechaBuscadaStr: $datosFormateados');
            print('📊 Total de datos procesados: ${datosFormateados.length}');
            
            return datosFormateados;
          }
        }
        
        throw Exception('Estructura de datos no reconocida');
      } else {
        throw Exception('Error al obtener datos por hora con filtro: ${response.statusCode}');
      }
    } catch (e) {
      print('💥 Error en datos por hora con filtro: $e');
      throw Exception('Error de conexión en datos por hora con filtro: $e');
    }
  }

  // Función para datos por mes con filtro - CORREGIR COMPLETAMENTE
  static Future<List<Map<String, dynamic>>> obtenerDatosPorMesConFiltro(String inicio, String fin) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final url = Uri.parse('$_baseUrl/datos/mes?inicio=$inicio&fin=$fin&t=$timestamp');
    
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
      } else {
        throw Exception('Error al obtener datos mensuales con filtro: ${response.statusCode}');
      }
    } catch (e) {
      print('💥 Error en datos mensuales con filtro: $e');
      throw Exception('Error de conexión en datos mensuales con filtro: $e');
    }
  }

  // Función para datos por año con filtro - CORREGIR COMPLETAMENTE  
  static Future<List<Map<String, dynamic>>> obtenerDatosPorAnioConFiltro(String inicio, String fin) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final url = Uri.parse('$_baseUrl/datos/anio?inicio=$inicio&fin=$fin&t=$timestamp');
    
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
      } else {
        throw Exception('Error al obtener datos anuales con filtro: ${response.statusCode}');
      }
    } catch (e) {
      print('💥 Error en datos anuales con filtro: $e');
      throw Exception('Error de conexión en datos anuales con filtro: $e');
    }
  }
  
  // NUEVO: Función privada para procesar datos de horas (usada en obtenerDatosPorHora y obtenerDatosPorHoraConFiltro)
  static List<Map<String, dynamic>> _procesarDatosHoras(Map<String, dynamic> data) {
    List<Map<String, dynamic>> datosFormateados = [];
    
    if (data['energiaHoras'] != null && data['energiaHoras'] is List) {
      // NUEVO: Obtener la fecha actual en Colombia
      final fechaHoyColombia = horaActualColombia();
      final fechaHoyStr = '${fechaHoyColombia.year}-${fechaHoyColombia.month.toString().padLeft(2, '0')}-${fechaHoyColombia.day.toString().padLeft(2, '0')}';
      
      print('📅 Fecha de hoy Colombia: $fechaHoyStr');
      
      // NUEVO: Procesar y agrupar datos por hora del día actual
      Map<int, double> energiaPorHora = {};
      
      for (var item in data['energiaHoras']) {
        try {
          DateTime timestampUTC = DateTime.parse(item['timestamp']);
          DateTime timestampColombia = timestampUTC.subtract(Duration(hours: 5)); // Convertir a Colombia
          
          // Verificar si es del día actual
          String fechaItem = '${timestampColombia.year}-${timestampColombia.month.toString().padLeft(2, '0')}-${timestampColombia.day.toString().padLeft(2, '0')}';
          
          print('🔍 Procesando: $timestampUTC -> $timestampColombia (fecha: $fechaItem)');
          
          if (fechaItem == fechaHoyStr) {
            int hora = timestampColombia.hour;
            double energia = (item['energia'] ?? 0).toDouble();
            
            // Si ya existe datos para esta hora, sumar la energía
            if (energiaPorHora.containsKey(hora)) {
              energiaPorHora[hora] = energiaPorHora[hora]! + energia;
            } else {
              energiaPorHora[hora] = energia;
            }
            
            print('⏰ Hora: $hora, Energía acumulada: ${energiaPorHora[hora]}');
          } else {
            print('❌ Dato no es de hoy: $fechaItem (esperado: $fechaHoyStr)');
          }
        } catch (e) {
          print('❌ Error procesando timestamp ${item['timestamp']}: $e');
        }
      }
      
      // NUEVO: Convertir el mapa a lista ordenada
      List<int> horasOrdenadas = energiaPorHora.keys.toList()..sort();
      
      for (int hora in horasOrdenadas) {
        datosFormateados.add({
          'hora': hora,
          'energia': energiaPorHora[hora]!,
          'timestamp': DateTime.now().millisecondsSinceEpoch
        });
      }
    }
    
    return datosFormateados;
  }
}
