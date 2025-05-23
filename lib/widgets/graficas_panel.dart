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

  @override
  void initState() {
    super.initState();
    // Depuración adicional
    print('Inicializando gráfica. Hora actual Colombia: ${horaActualColombia().hour}:${horaActualColombia().minute}');
    _cargarDatos();
    
    // Actualizar los datos cada minuto para mantenerlos sincronizados
    Timer.periodic(const Duration(minutes: 1), (Timer t) {
      if (mounted) {
        _cargarDatos();
        print("Actualizando datos de la gráfica: ${horaActualColombia().toString()}");
      }
    });
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
        });
        
        // Log de depuración
        print('Datos filtrados: ${_datosEnergia.length} registros hasta la hora $horaActual');
        if (_datosEnergia.isNotEmpty) {
          print('Rango horario: ${_formatearHora(_datosEnergia.first.hora)} - ${_formatearHora(_datosEnergia.last.hora)}');
        }
      }
    } catch (e) {
      setState(() {
        _cargando = false;
        _hayError = true;
      });
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
        const Icon(Icons.error_outline, size: 48, color: Colors.orange),
        const SizedBox(height: 16),
        const Text(
          'No se pudieron cargar los datos',
          style: TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: _cargarDatos,
          child: const Text('Reintentar'),
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
    
    // Identificar las horas con generación solar para mejor visualización
    final horasSolares = _datosEnergia.where((dato) => dato.energia > 0).toList();
    print('Horas con generación solar: ${horasSolares.length}');
    if (horasSolares.isNotEmpty) {
      print('Primera hora con generación: ${_formatearHora(horasSolares.first.hora)}');
      print('Última hora con generación: ${_formatearHora(horasSolares.last.hora)}');
    }
    
    return Column(
      children: [
        // Eliminar la etiqueta superior y colocarla junto a la gráfica
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
              // Gráfica a la derecha
              Expanded(
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: _calcularMaxY(),
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        // Eliminar la propiedad de color de fondo para usar el valor predeterminado
                        tooltipPadding: const EdgeInsets.all(8),
                        tooltipMargin: 8,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final dato = _datosEnergia[group.x.toInt()];
                          return BarTooltipItem(
                            '${_formatearHora(dato.hora)}\n${dato.energia.toStringAsFixed(2)} kWh',
                            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          );
                        },
                      ),
                      touchCallback: (event, response) {},
                      handleBuiltInTouches: true,
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 36,
                          getTitlesWidget: (double value, TitleMeta meta) {
                            // Mostrar sólo algunas horas para evitar sobrecarga
                            final index = value.toInt();
                            if (index < 0 || index >= _datosEnergia.length) {
                              return const SizedBox.shrink();
                            }
                            
                            // Si hay más de 12 datos, mostrar solo horas pares o cada 3 horas
                            if (_datosEnergia.length > 12) {
                              if (index % 3 != 0) {
                                return const SizedBox.shrink();
                              }
                            } else if (_datosEnergia.length > 8 && index % 2 != 0) {
                              return const SizedBox.shrink();
                            }
                            
                            // Obtener la hora del dato actual
                            final horaActual = _datosEnergia[index].hora;
                            
                            return Padding(
                              padding: const EdgeInsets.only(top: 10.0),
                              child: Transform.rotate(
                                angle: _datosEnergia.length > 8 ? 0.6 : 0, // Rotar etiquetas si hay muchos datos
                                child: Text(
                                  _formatearHora(horaActual),
                                  style: const TextStyle(
                                    fontSize: 10, 
                                    fontWeight: FontWeight.bold,
                                  ),
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
                    gridData: const FlGridData(
                      show: true,
                      drawHorizontalLine: true,
                      drawVerticalLine: false,
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
                    barGroups: _crearBarras(),
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

  List<BarChartGroupData> _crearBarras() {
    // Ajustar el ancho de las barras según la cantidad de datos
    double barWidth = _datosEnergia.length > 12 ? 12 : 16;
    
    return _datosEnergia.asMap().entries.map((entry) {
      final index = entry.key;
      final dato = entry.value;
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: dato.energia,
            color: _colorPorEnergia(dato.energia),
            width: barWidth,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(6),
            ),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: _calcularMaxY(),
              color: Colors.grey.withOpacity(0.1),
            ),
          ),
        ],
      );
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

  // Método mejorado para formatear la hora
  String _formatearHora(int hora) {
    // Usar la hora de Colombia como base para asegurar consistencia
    final ahora = horaActualColombia();
    
    // Crear un DateTime con la hora específica pero del mismo día
    final DateTime fechaHora = DateTime(ahora.year, ahora.month, ahora.day, hora);
    
    // Usar el formato estándar de la aplicación para consistencia
    return formatearHoraColombia(fechaHora).split(':')[0] + formatearHoraColombia(fechaHora).substring(formatearHoraColombia(fechaHora).length - 3);
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
