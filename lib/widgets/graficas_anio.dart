import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';
import '../utils/utilidades.dart';

class GraficasAnio extends StatefulWidget {
  const GraficasAnio({super.key});

  @override
  State<GraficasAnio> createState() => _GraficasAnioState();
}

class _GraficasAnioState extends State<GraficasAnio> {
  List<DatoEnergiaAnio> _datosEnergia = [];
  bool _cargando = true;
  bool _hayError = false;

  @override
  void initState() {
    super.initState();
    print('Inicializando gráfica anual');
    _cargarDatos();
    
    Timer.periodic(const Duration(minutes: 10), (Timer t) {
      if (mounted) {
        _cargarDatos();
        print("Actualizando datos de la gráfica anual: ${horaActualColombia().toString()}");
      }
    });
  }

  Future<void> _cargarDatos() async {
    try {
      final datos = await ApiService.obtenerDatosPorAnio();
      final mesActual = horaActualColombia().month;
      
      if (mounted) {
        setState(() {
          _datosEnergia = datos
            .where((dato) => dato['mes'] <= mesActual)
            .map((dato) => DatoEnergiaAnio(
              mes: dato['mes'],
              energia: dato['energia'],
            ))
            .toList();
            
          _cargando = false;
          _hayError = false; // ← SIN ERROR si carga bien
        });
        
        print('Datos anuales filtrados: ${_datosEnergia.length} registros hasta el mes $mesActual');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cargando = false;
          _hayError = true; // ← CON ERROR cuando no hay conexión
        });
      }
      print('Error cargando datos anuales: $e');
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
              'Energía Generada por Mes del Año',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Datos del año ${horaActualColombia().year}',
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
          'No hay datos anuales disponibles',
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
                    'Energía (MWh)', 
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
                            '${_nombreMes(dato.mes)}\n${dato.energia.toStringAsFixed(2)} MWh',
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
                            
                            final mes = _datosEnergia[index].mes;
                            
                            return Padding(
                              padding: const EdgeInsets.only(top: 10.0),
                              child: Text(
                                _nombreMesCorto(mes),
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
            const Text('Mes del año', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  List<BarChartGroupData> _crearBarras() {
    return _datosEnergia.asMap().entries.map((entry) {
      final index = entry.key;
      final dato = entry.value;
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: dato.energia,
            color: _colorPorEnergia(dato.energia),
            width: 16,
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
    if (energia < 50) return Colors.lightBlue;
    if (energia < 150) return Colors.blue;
    if (energia < 250) return Colors.green;
    if (energia < 350) return Colors.amber;
    return Colors.orange;
  }

  String _nombreMes(int mes) {
    final meses = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return meses[mes - 1];
  }

  String _nombreMesCorto(int mes) {
    final meses = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    return meses[mes - 1];
  }
}

class DatoEnergiaAnio {
  final int mes;
  final double energia;

  DatoEnergiaAnio({required this.mes, required this.energia});
}