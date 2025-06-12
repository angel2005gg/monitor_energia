import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';
import '../utils/utilidades.dart';

class GraficasPanel extends StatefulWidget {
  const GraficasPanel({super.key});

  @override
  State<GraficasPanel> createState() => _GraficasPanelState();
}

class _GraficasPanelState extends State<GraficasPanel> {
  List<DatoEnergia> _datosEnergia = [];
  bool _cargando = true;
  bool _hayError = false;
  Timer? _timer; // ← AGREGAR variable para el timer

  @override
  void initState() {
    super.initState();
    // Depuración adicional
    print('Inicializando gráfica. Hora actual Colombia: ${horaActualColombia().hour}:${horaActualColombia().minute}');
    _cargarDatos();
    
    // CAMBIAR el timer para que sea más frecuente cuando hay error
    _iniciarTimer();
  }

  void _iniciarTimer() {
    _timer?.cancel(); // Cancelar timer anterior si existe
    
    // Si hay error, verificar cada 10 segundos, si no cada minuto
    final duracion = _hayError ? Duration(seconds: 10) : Duration(minutes: 1);
    
    _timer = Timer.periodic(duracion, (Timer t) {
      if (mounted) {
        _cargarDatos();
        print("Actualizando datos de la gráfica: ${horaActualColombia().toString()}");
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // ← CANCELAR timer al destruir el widget
    super.dispose();
  }

  // Método para cargar datos mejorado
  Future<void> _cargarDatos() async {
    try {
      final datos = await ApiService.obtenerDatosPorHora();
      final horaActual = horaActualColombia().hour;
      
      if (mounted) {
        setState(() {
          // Filtrar datos para asegurarnos de que no hay horas futuras
          _datosEnergia = datos
            .where((dato) => dato['hora'] <= horaActual)
            .map((dato) => DatoEnergia(
              hora: dato['hora'],
              energia: dato['energia'],
            ))
            .toList();
            
          _cargando = false;
          bool errorAnterior = _hayError; // ← GUARDAR estado anterior
          _hayError = false;
          
          // Si cambió de error a éxito, reiniciar timer
          if (errorAnterior && !_hayError) {
            print('🟢 Conexión restablecida - reiniciando timer normal');
            _iniciarTimer();
          }
        });
        
        // Log de depuración
        print('Datos filtrados: ${_datosEnergia.length} registros hasta la hora $horaActual');
        if (_datosEnergia.isNotEmpty) {
          print('Rango horario: ${_formatearHora(_datosEnergia.first.hora)} - ${_formatearHora(_datosEnergia.last.hora)}');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cargando = false;
          bool errorAnterior = _hayError; // ← GUARDAR estado anterior
          _hayError = true;
          
          // Si cambió de éxito a error, acelerar timer
          if (!errorAnterior && _hayError) {
            print('🔴 Conexión perdida - acelerando verificaciones');
            _iniciarTimer();
          }
        });
      }
      print('Error cargando datos para la gráfica: $e');
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
            const Text(
              'Energía Generada por Hora',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Datos del ${_formatearFecha(horaActualColombia())}',
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

  Widget _construirGrafica() {
    // Si no hay datos, mostrar mensaje
    if (_datosEnergia.isEmpty) {
      return const Center(
        child: Text(
          'No hay datos disponibles para mostrar',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    // Añadir depuración antes de renderizar
    print('Renderizando gráfica con ${_datosEnergia.length} datos');
    
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              // Etiqueta del eje Y a la izquierda
              Padding(
                padding: const EdgeInsets.only(right: 4.0),
                child: RotatedBox(
                  quarterTurns: 3,
                  child: Text(
                    'Energía (kWh)', 
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)
                  ),
                ),
              ),
              // Gráfica a la derecha - CAMBIO DE BarChart A LineChart
              Expanded(
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawHorizontalLine: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: Colors.grey.withOpacity(0.3),
                          strokeWidth: 1,
                        );
                      },
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 36,
                          interval: 1, // ← AGREGAR ESTA LÍNEA
                          getTitlesWidget: (double value, TitleMeta meta) {
                            final index = value.toInt();
                            if (index < 0 || index >= _datosEnergia.length) {
                              return const SizedBox.shrink();
                            }
                            
                            // NUEVA LÓGICA SIN DUPLICADOS
                            bool mostrarHora = false;
                            
                            if (_datosEnergia.length <= 6) {
                              mostrarHora = true; // Mostrar todas las horas
                            } else if (_datosEnergia.length <= 12) {
                              mostrarHora = (index % 2 == 0); // Cada 2 horas
                            } else {
                              mostrarHora = (index % 3 == 0); // Cada 3 horas
                            }
                            
                            // Siempre mostrar primera y última
                            if (index == 0 || index == _datosEnergia.length - 1) {
                              mostrarHora = true;
                            }
                            
                            if (!mostrarHora) {
                              return const SizedBox.shrink();
                            }
                            
                            final horaActual = _datosEnergia[index].hora;
                            
                            return Padding(
                              padding: const EdgeInsets.only(top: 10.0),
                              child: Text(
                                _formatearHora(horaActual),
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
                    minX: 0,
                    maxX: (_datosEnergia.length - 1).toDouble(),
                    minY: 0,
                    maxY: _calcularMaxY(),
                    lineBarsData: [
                      LineChartBarData(
                        spots: _crearPuntosLinea(),
                        isCurved: true, // Línea curva suave
                        curveSmoothness: 0.3,
                        color: Colors.blue,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 4,
                              color: _colorPorEnergia(_datosEnergia[index].energia),
                              strokeWidth: 2,
                              strokeColor: Colors.white,
                            );
                          },
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
                            final index = barSpot.x.toInt();
                            if (index >= 0 && index < _datosEnergia.length) {
                              final dato = _datosEnergia[index];
                              return LineTooltipItem(
                                '${_formatearHora(dato.hora)}\n${dato.energia.toStringAsFixed(2)} kWh',
                                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              );
                            }
                            return null;
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
        // Leyenda y títulos
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Hora del día', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  List<FlSpot> _crearPuntosLinea() {
    return _datosEnergia.asMap().entries.map((entry) {
      final index = entry.key;
      final dato = entry.value;
      return FlSpot(index.toDouble(), dato.energia);
    }).toList();
  }

  double _calcularMaxY() {
    // Calcular el valor máximo y añadir un poco más para espacio superior
    double max = 0;
    for (var dato in _datosEnergia) {
      if (dato.energia > max) {
        max = dato.energia;
      }
    }
    return max * 1.2; // 20% más para espacio superior
  }

  Color _colorPorEnergia(double energia) {
    // Escala de colores basada en la cantidad de energía
    if (energia <= 0) return Colors.grey;
    if (energia < 1) return Colors.lightBlue;
    if (energia < 2) return Colors.blue;
    if (energia < 3) return Colors.green;
    if (energia < 4) return Colors.amber;
    return Colors.orange;
  }

  // Método simplificado para formatear la hora
  String _formatearHora(int hora) {
    // Formateo simple y directo
    if (hora == 0) return '12 AM';
    if (hora < 12) return '${hora} AM';
    if (hora == 12) return '12 PM';
    return '${hora - 12} PM';
  }

  String _formatearFecha(DateTime fecha) {
    final meses = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    ];
    return '${fecha.day} de ${meses[fecha.month - 1]} de ${fecha.year}';
  }
}

// Clase para representar los datos de energía
class DatoEnergia {
  final int hora;
  final double energia;

  DatoEnergia({required this.hora, required this.energia});
}
