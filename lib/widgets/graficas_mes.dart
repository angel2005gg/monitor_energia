import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';
import '../utils/utilidades.dart';

class GraficasMes extends StatefulWidget {
  const GraficasMes({super.key});

  @override
  State<GraficasMes> createState() => _GraficasMesState();
}

class _GraficasMesState extends State<GraficasMes> {
  List<DatoEnergiaMes> _datosEnergia = [];
  bool _cargando = true;
  bool _hayError = false;

  @override
  void initState() {
    super.initState();
    print('Inicializando gráfica mensual');
    _cargarDatos();
    
    Timer.periodic(const Duration(minutes: 5), (Timer t) {
      if (mounted) {
        _cargarDatos();
        print("Actualizando datos de la gráfica mensual: ${horaActualColombia().toString()}");
      }
    });
  }

  Future<void> _cargarDatos() async {
    try {
      final datos = await ApiService.obtenerDatosPorMes();
      final diaActual = horaActualColombia().day;
      
      if (mounted) {
        setState(() {
          _datosEnergia = datos
            .where((dato) => dato['dia'] <= diaActual)
            .map((dato) => DatoEnergiaMes(
              dia: dato['dia'],
              energia: dato['energia'],
            ))
            .toList();
            
          _cargando = false;
          _hayError = false; // ← SIN ERROR si carga bien
        });
        
        print('Datos mensuales filtrados: ${_datosEnergia.length} registros hasta el día $diaActual');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cargando = false;
          _hayError = true; // ← CON ERROR cuando no hay conexión
        });
      }
      print('Error cargando datos mensuales: $e');
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
              'Energía Generada por Día del Mes',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Datos del ${_formatearFechaMes(horaActualColombia())}',
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
    if (_datosEnergia.isEmpty) {
      return const Center(
        child: Text(
          'No hay datos mensuales disponibles',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
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
              Expanded(
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: _calcularMaxY(),
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        tooltipPadding: const EdgeInsets.all(8),
                        tooltipMargin: 8,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final dato = _datosEnergia[group.x.toInt()];
                          return BarTooltipItem(
                            'Día ${dato.dia}\n${dato.energia.toStringAsFixed(2)} kWh',
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
                            final index = value.toInt();
                            if (index < 0 || index >= _datosEnergia.length) {
                              return const SizedBox.shrink();
                            }
                            
                            // Mostrar cada 5 días para evitar sobrecarga
                            if (_datosEnergia.length > 15 && index % 5 != 0) {
                              return const SizedBox.shrink();
                            } else if (_datosEnergia.length > 10 && index % 3 != 0) {
                              return const SizedBox.shrink();
                            }
                            
                            final dia = _datosEnergia[index].dia;
                            
                            return Padding(
                              padding: const EdgeInsets.only(top: 10.0),
                              child: Text(
                                '$dia',
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
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Día del mes', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  List<BarChartGroupData> _crearBarras() {
    double barWidth = _datosEnergia.length > 20 ? 8 : 12;
    
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
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
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
    double max = 0;
    for (var dato in _datosEnergia) {
      if (dato.energia > max) {
        max = dato.energia;
      }
    }
    return max * 1.2;
  }

  Color _colorPorEnergia(double energia) {
    if (energia <= 0) return Colors.grey;
    if (energia < 5) return Colors.lightBlue;
    if (energia < 15) return Colors.blue;
    if (energia < 25) return Colors.green;
    if (energia < 35) return Colors.amber;
    return Colors.orange;
  }

  String _formatearFechaMes(DateTime fecha) {
    final meses = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    ];
    return '${meses[fecha.month - 1]} de ${fecha.year}';
  }
}

class DatoEnergiaMes {
  final int dia;
  final double energia;

  DatoEnergiaMes({required this.dia, required this.energia});
}