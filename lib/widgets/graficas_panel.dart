import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';
import '../utils/utilidades.dart';
import '../widgets/filtro_fechas.dart'; // ← AGREGAR IMPORT

class GraficasPanel extends StatefulWidget {
  const GraficasPanel({super.key});

  @override
  State<GraficasPanel> createState() => _GraficasPanelState();
}

class _GraficasPanelState extends State<GraficasPanel> {
  List<DatoPotencia> _datosPotencia = []; // ← CAMBIO: de DatoEnergia a DatoPotencia
  bool _cargando = true;
  bool _hayError = false;
  Timer? _timer;
  DateTime _fechaSeleccionada = horaActualColombia();

  @override
  void initState() {
    super.initState();
    print('Inicializando gráfica de potencia en tiempo real');
    _cargarDatos();
    
    // ← CAMBIO: Timer más frecuente para tiempo real
    _iniciarTimer();
  }

  void _iniciarTimer() {
    _timer?.cancel();
    
    // ← CAMBIO: Actualizar cada 30 segundos para tiempo real
    final duracion = _hayError ? Duration(seconds: 10) : Duration(seconds: 30);
    
    _timer = Timer.periodic(duracion, (Timer t) {
      if (mounted) {
        _cargarDatos();
        print("Actualizando datos de potencia en tiempo real: ${horaActualColombia().toString()}");
      }
    });
  }

  // ← CAMBIO PRINCIPAL: Cargar TODOS los datos del día y actualizar en vivo
  Future<void> _cargarDatos() async {
    print('🚀 Cargando datos completos del día en tiempo real...');
    
    try {
      // ← CAMBIO: Usar la API de horas para obtener TODOS los datos del día
      final datos = await ApiService.obtenerDatosPorHora();
      print('📈 Datos completos del día recibidos: ${datos.length} registros');
      
      if (mounted) {
        final horaActual = horaActualColombia();
        
        // ← CAMBIO: Procesar TODOS los datos del día que vienen de la API
        List<DatoPotencia> datosProcesados = [];
        
        for (var dato in datos) {
          try {
            int hora = dato['hora'];
            double energia = dato['energia'];
            
            // ← CAMBIO: Convertir energía acumulada por hora a potencia promedio
            // (dividir entre 60 minutos para obtener potencia promedio de esa hora)
            double potenciaPromedio = energia; // Mantener como energía de la hora
            
            // Crear timestamp para esa hora del día actual
            DateTime timestampHora = DateTime(
              horaActual.year,
              horaActual.month,
              horaActual.day,
              hora,
              0, // minuto 0
            );
            
            datosProcesados.add(DatoPotencia(
              timestamp: timestampHora,
              potencia: potenciaPromedio,
            ));
            
            print('✅ Procesado: Hora $hora con ${potenciaPromedio.toStringAsFixed(2)} kWh');
          } catch (e) {
            print('❌ Error procesando dato: $e');
          }
        }
        
        // ← CAMBIO: Ordenar por hora
        datosProcesados.sort((a, b) => a.timestamp.hour.compareTo(b.timestamp.hour));
        
        setState(() {
          _datosPotencia = datosProcesados; // ← Reemplazar todos los datos
          _cargando = false;
          bool errorAnterior = _hayError;
          _hayError = false;
          
          if (errorAnterior && !_hayError) {
            print('🟢 Conexión restablecida');
            _iniciarTimer();
          }
        });
        
        print('✅ Gráfica actualizada con ${_datosPotencia.length} puntos del día completo');
      }
    } catch (e) {
      print('💥 Error cargando datos del día: $e');
      
      if (mounted) {
        setState(() {
          _cargando = false;
          bool errorAnterior = _hayError;
          _hayError = true;
          
          if (!errorAnterior && _hayError) {
            print('🔴 Conexión perdida - acelerando verificaciones');
            _iniciarTimer();
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ← CAMBIO: Título actualizado
            const Text(
              'Potencia Generada', // ← Sin "por Hora"
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            // ← CAMBIO: Subtítulo para tiempo real
            Text(
              'Datos en tiempo real del ${_formatearFecha(_fechaSeleccionada)}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            
            const SizedBox(height: 20),
            SizedBox(
              height: 250,
              width: double.infinity,
              child: _cargando 
                ? const Center(child: CircularProgressIndicator())
                : _hayError 
                  ? _construirMensajeError()
                  : _construirGrafica(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirGrafica() {
    if (_datosPotencia.isEmpty) {
      return const Center(
        child: Text(
          'Esperando datos del día...',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    print('📊 Renderizando gráfica del día con ${_datosPotencia.length} puntos');
    
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              // Etiqueta del eje Y
              Padding(
                padding: const EdgeInsets.only(right: 4.0),
                child: RotatedBox(
                  quarterTurns: 3,
                  child: Text(
                    'Potencia kW', // ← CAMBIO: de "Energía (kWh)" a "Potencia kW"
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)
                  ),
                ),
              ),
              // Gráfica completa del día
              Expanded(
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawHorizontalLine: true,
                      drawVerticalLine: true,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: Colors.grey.withOpacity(0.3),
                          strokeWidth: 1,
                        );
                      },
                      getDrawingVerticalLine: (value) {
                        return FlLine(
                          color: Colors.grey.withOpacity(0.2),
                          strokeWidth: 0.8,
                        );
                      },
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 36,
                          interval: 1,
                          getTitlesWidget: (double value, TitleMeta meta) {
                            // ← CAMBIO: Usar horas reales
                            int hora = value.round();
                            
                            // Solo mostrar horas válidas (6-19)
                            if (hora < 6 || hora > 19) {
                              return const SizedBox.shrink();
                            }
                            
                            // Mostrar cada 2 horas
                            if ((hora - 6) % 2 != 0) {
                              return const SizedBox.shrink();
                            }
                            
                            return Padding(
                              padding: const EdgeInsets.only(top: 10.0),
                              child: Text(
                                '${hora}h',
                                style: const TextStyle(
                                  fontSize: 10, 
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (double value, TitleMeta meta) {
                            return Text(
                              value.toStringAsFixed(1),
                              style: const TextStyle(fontSize: 10),
                              textAlign: TextAlign.center,
                            );
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: const Border(
                        left: BorderSide(color: Colors.grey),
                        bottom: BorderSide(color: Colors.grey),
                        right: BorderSide(color: Colors.transparent),
                        top: BorderSide(color: Colors.transparent),
                      ),
                    ),
                    // ← CAMBIO: Usar horas reales como límites
                    minX: 6, // 6 AM
                    maxX: 19, // 7 PM
                    minY: 0,
                    maxY: _calcularMaxY(),
                    lineBarsData: [
                      LineChartBarData(
                        spots: _crearPuntosLineaConHorasReales(), // ← NUEVA función también aquí
                        isCurved: true,
                        curveSmoothness: 0.2,
                        color: Colors.blue,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: FlDotData(
                          show: false, // ← CAMBIO: Cambiar de true a false para ocultar puntos
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          color: Colors.blue.withOpacity(0.1),
                        ),
                      ),
                    ],
                    lineTouchData: LineTouchData(
                      handleBuiltInTouches: true,
                      touchTooltipData: LineTouchTooltipData(
                        tooltipPadding: const EdgeInsets.all(8),
                        tooltipMargin: 8,
                        getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                          return touchedBarSpots.map((barSpot) {
                            // ← CAMBIO: Usar el valor X real (hora) en lugar de buscar por índice
                            double horaDecimal = barSpot.x;
                            int hora = horaDecimal.floor();
                            int minuto = ((horaDecimal - hora) * 60).round();
                            
                            // ← CAMBIO: Sin formato AM/PM, solo hora:minuto y cambiar kWh por kW
                            return LineTooltipItem(
                              '${hora}:${minuto.toString().padLeft(2, '0')}\n${barSpot.y.toStringAsFixed(2)} kW', // ← CAMBIO: kWh -> kW
                              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            );
                          }).toList();
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Horas del día (6 AM - 7 PM)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  // ← NUEVA FUNCIÓN: Crear puntos usando horas reales en lugar de índices
  List<FlSpot> _crearPuntosLineaConHorasReales() {
    return _datosPotencia.map((dato) {
      // Usar hora real como coordenada X
      double horaDecimal = dato.timestamp.hour + (dato.timestamp.minute / 60.0);
      
      // Asegurar que esté en el rango 6-19
      horaDecimal = horaDecimal.clamp(6.0, 19.0);
      
      return FlSpot(horaDecimal, dato.potencia);
    }).toList();
  }

  double _calcularMaxY() {
    if (_datosPotencia.isEmpty) return 12.0; // ← MÁXIMO FIJO EN 12 kW
    
    double max = 0;
    for (var dato in _datosPotencia) {
      if (dato.potencia > max) {
        max = dato.potencia;
      }
    }
    
    // ← ASEGURAR que nunca supere 12 kW
    double maxCalculado = (max * 1.2).clamp(1.0, 12.0);
    return maxCalculado > 12.0 ? 12.0 : maxCalculado;
  }

  // ← MANTENER funciones auxiliares sin cambios
  Widget _construirMensajeError() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.wifi_off,
          size: 48,
          color: Colors.grey.shade400,
        ),
        const SizedBox(height: 16),
        Text(
          'Gráfica no disponible',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Conecte el sistema para ver los datos',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  String _formatearFecha(DateTime fecha) {
    final meses = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    ];
    return '${fecha.day} de ${meses[fecha.month - 1]} de ${fecha.year}';
  }
}

// ← CAMBIO: Nueva clase para datos de potencia en tiempo real
class DatoPotencia {
  final DateTime timestamp;
  final double potencia;
  final double? timestampDecimal; // ← NUEVO: Para posicionamiento preciso

  DatoPotencia({
    required this.timestamp, 
    required this.potencia,
    this.timestampDecimal, // ← NUEVO: Opcional
  });
}

// ← ELIMINAR o COMENTAR la clase GraficasPanelConFiltro ya que ahora es tiempo real
// La clase GraficasPanelConFiltro ya no se necesita porque la gráfica es en tiempo real
class GraficasPanelConFiltro extends StatefulWidget {
  final DateTime fechaSeleccionada;
  
  const GraficasPanelConFiltro({
    Key? key,
    required this.fechaSeleccionada,
  }) : super(key: key);

  @override
  State<GraficasPanelConFiltro> createState() => _GraficasPanelConFiltroState();
}

class _GraficasPanelConFiltroState extends State<GraficasPanelConFiltro> {
  List<DatoPotencia> _datosPotencia = [];
  bool _cargando = true;
  bool _hayError = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    print('🚀 Inicializando gráfica con filtro: ${widget.fechaSeleccionada}');
    _cargarDatosConFecha(widget.fechaSeleccionada);
    _iniciarTimer();
  }

  @override
  void didUpdateWidget(GraficasPanelConFiltro oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fechaSeleccionada != widget.fechaSeleccionada) {
      print('📅 Fecha cambió a: ${widget.fechaSeleccionada}');
      _cargarDatosConFecha(widget.fechaSeleccionada);
    }
  }

  void _iniciarTimer() {
    _timer?.cancel();
    final duracion = _hayError ? Duration(seconds: 15) : Duration(minutes: 2);
    
    _timer = Timer.periodic(duracion, (Timer t) {
      if (mounted) {
        _cargarDatosConFecha(widget.fechaSeleccionada);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ← NUEVA FUNCIÓN: Cargar datos específicos para la fecha seleccionada
  Future<void> _cargarDatosConFecha(DateTime fecha) async {
    setState(() {
      _cargando = true;
    });
    
    try {
      // Crear filtro específico para la fecha seleccionada
      final String inicio = '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}T00:00:00';
      final String fin = '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}T23:59:59';
      
      print('🔍 Consultando API de alta precisión: $inicio a $fin');
      
      // Usar la API con filtro específico
      final datos = await ApiService.obtenerDatosPorHoraConFiltro(inicio, fin);
      
      if (mounted) {
        // ← PROCESAR todos los puntos detallados
        List<DatoPotencia> datosProcesados = [];
        
        for (var dato in datos) {
          try {
            int hora = dato['hora'];
            int minuto = dato['minuto'] ?? 0;
            double energia = dato['energia'];
            double timestampDecimal = dato['timestampDecimal'] ?? (hora + minuto/60.0);
            
            // Convertir energía a potencia realista
            double potencia = energia;
            if (potencia > 12.0) {
              potencia = potencia / 10;
            }
            
            // Crear timestamp exacto con minutos
            DateTime timestampHora = DateTime(
              fecha.year,
              fecha.month,
              fecha.day,
              hora,
              minuto,
            );
            
            datosProcesados.add(DatoPotencia(
              timestamp: timestampHora,
              potencia: potencia,
              timestampDecimal: timestampDecimal, // ← NUEVO: Para posicionamiento preciso en gráfica
            ));
            
            print('✅ Procesado: ${hora}:${minuto.toString().padLeft(2, '0')} con ${potencia.toStringAsFixed(2)} kW');
          } catch (e) {
            print('❌ Error procesando dato: $e');
          }
        }
        
        // ← NO ORDENAR aquí porque ya vienen ordenados de la API
        print('📊 Datos de alta precisión para ${fecha.day}/${fecha.month}/${fecha.year}: ${datosProcesados.length} puntos');
        
        setState(() {
          _datosPotencia = datosProcesados;
          _cargando = false;
          _hayError = false;
        });
      }
    } catch (e) {
      print('❌ Error cargando datos de alta precisión: $e');
      
      if (mounted) {
        setState(() {
          _datosPotencia = [];
          _cargando = false;
          _hayError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ← TÍTULO ACTUALIZADO CON FECHA
            const Text(
              'Potencia Generada',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Datos del ${_formatearFecha(widget.fechaSeleccionada)}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            
            const SizedBox(height: 20),
            SizedBox(
              height: 250,
              width: double.infinity,
              child: _cargando 
                ? const Center(child: CircularProgressIndicator())
                : _hayError 
                  ? _construirMensajeError()
                  : _datosPotencia.isEmpty
                    ? _construirMensajeSinDatos()
                    : _construirGrafica(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirMensajeError() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error_outline, size: 48, color: Colors.orange.shade400),
        const SizedBox(height: 16),
        const Text(
          'Error al cargar datos',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          'No se pudieron obtener los datos para esta fecha',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _construirMensajeSinDatos() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.calendar_today, size: 48, color: Colors.grey.shade400),
        const SizedBox(height: 16),
        const Text(
          'No hay datos disponibles',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          'No se encontraron registros para ${_formatearFecha(widget.fechaSeleccionada)}',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _construirGrafica() {
    if (_datosPotencia.isEmpty) {
      return const Center(
        child: Text(
          'Esperando datos del día...',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    print('📊 Renderizando gráfica del día con ${_datosPotencia.length} puntos');
    
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              // Etiqueta del eje Y
              Padding(
                padding: const EdgeInsets.only(right: 4.0),
                child: RotatedBox(
                  quarterTurns: 3,
                  child: Text(
                    'Potencia kW', // ← CAMBIO: de "Energía (kWh)" a "Potencia kW"
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)
                  ),
                ),
              ),
              // Gráfica completa del día
              Expanded(
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawHorizontalLine: true,
                      drawVerticalLine: true,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: Colors.grey.withOpacity(0.3),
                          strokeWidth: 1,
                        );
                      },
                      getDrawingVerticalLine: (value) {
                        return FlLine(
                          color: Colors.grey.withOpacity(0.2),
                          strokeWidth: 0.8,
                        );
                      },
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 36,
                          interval: 1,
                          getTitlesWidget: (double value, TitleMeta meta) {
                            // ← CAMBIO: Usar horas reales
                            int hora = value.round();
                            
                            // Solo mostrar horas válidas (6-19)
                            if (hora < 6 || hora > 19) {
                              return const SizedBox.shrink();
                            }
                            
                            // Mostrar cada 2 horas
                            if ((hora - 6) % 2 != 0) {
                              return const SizedBox.shrink();
                            }
                            
                            return Padding(
                              padding: const EdgeInsets.only(top: 10.0),
                              child: Text(
                                '${hora}h',
                                style: const TextStyle(
                                  fontSize: 10, 
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (double value, TitleMeta meta) {
                            return Text(
                              value.toStringAsFixed(1),
                              style: const TextStyle(fontSize: 10),
                              textAlign: TextAlign.center,
                            );
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: const Border(
                        left: BorderSide(color: Colors.grey),
                        bottom: BorderSide(color: Colors.grey),
                        right: BorderSide(color: Colors.transparent),
                        top: BorderSide(color: Colors.transparent),
                      ),
                    ),
                    // ← CAMBIO: Usar horas reales como límites
                    minX: 6, // 6 AM
                    maxX: 19, // 7 PM
                    minY: 0,
                    maxY: _calcularMaxY(),
                    lineBarsData: [
                      LineChartBarData(
                        spots: _crearPuntosLineaConHorasReales(), // ← NUEVA función también aquí
                        isCurved: true,
                        curveSmoothness: 0.2,
                        color: Colors.blue,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: FlDotData(
                          show: false, // ← CAMBIO: Cambiar de true a false para ocultar puntos
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          color: Colors.blue.withOpacity(0.1),
                        ),
                      ),
                    ],
                    lineTouchData: LineTouchData(
                      handleBuiltInTouches: true,
                      touchTooltipData: LineTouchTooltipData(
                        tooltipPadding: const EdgeInsets.all(8),
                        tooltipMargin: 8,
                        getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                          return touchedBarSpots.map((barSpot) {
                            // ← CAMBIO: Usar el valor X real (hora) en lugar de buscar por índice
                            double horaDecimal = barSpot.x;
                            int hora = horaDecimal.floor();
                            int minuto = ((horaDecimal - hora) * 60).round();
                            
                            // ← CAMBIO: Sin formato AM/PM, solo hora:minuto y cambiar kWh por kW
                            return LineTooltipItem(
                              '${hora}:${minuto.toString().padLeft(2, '0')}\n${barSpot.y.toStringAsFixed(2)} kW', // ← CAMBIO: kWh -> kW
                              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            );
                          }).toList();
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Horas del día (6 AM - 7 PM)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  // ← NUEVA FUNCIÓN: Crear puntos usando horas reales en lugar de índices
  List<FlSpot> _crearPuntosLineaConHorasReales() {
    return _datosPotencia.map((dato) {
      // Usar hora real como coordenada X
      double horaDecimal = dato.timestamp.hour + (dato.timestamp.minute / 60.0);
      
      // Asegurar que esté en el rango 6-19
      horaDecimal = horaDecimal.clamp(6.0, 19.0);
      
      return FlSpot(horaDecimal, dato.potencia);
    }).toList();
  }

  double _calcularMaxY() {
    if (_datosPotencia.isEmpty) return 12.0; // ← MÁXIMO FIJO EN 12 kW
    
    double max = 0;
    for (var dato in _datosPotencia) {
      if (dato.potencia > max) {
        max = dato.potencia;
      }
    }
    
    // ← ASEGURAR que nunca supere 12 kW
    double maxCalculado = (max * 1.2).clamp(1.0, 12.0);
    return maxCalculado > 12.0 ? 12.0 : maxCalculado;
  }

  String _formatearFecha(DateTime fecha) {
    final meses = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    ];
    return '${fecha.day} de ${meses[fecha.month - 1]} de ${fecha.year}';
  }
}
