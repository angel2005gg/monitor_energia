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
  Timer? _timer; // ← AGREGAR

  @override
  void initState() {
    super.initState();
    print('Inicializando gráfica anual');
    _cargarDatos();
    _iniciarTimer();
  }

  void _iniciarTimer() {
    _timer?.cancel();
    final duracion = _hayError ? Duration(seconds: 20) : Duration(minutes: 10);
    
    _timer = Timer.periodic(duracion, (Timer t) {
      if (mounted) {
        _cargarDatos();
        print("Actualizando datos de la gráfica anual: ${horaActualColombia().toString()}");
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
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
          bool errorAnterior = _hayError;
          _hayError = false;
          
          if (errorAnterior && !_hayError) {
            print('🟢 Gráfica anual - conexión restablecida');
            _iniciarTimer();
          }
        });
        
        print('Datos anuales filtrados: ${_datosEnergia.length} registros hasta el mes $mesActual');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cargando = false;
          bool errorAnterior = _hayError;
          _hayError = true;
          
          if (!errorAnterior && _hayError) {
            print('🔴 Gráfica anual - conexión perdida');
            _iniciarTimer();
          }
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
                    'Energía (KWh)', 
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
                            '${_nombreMes(dato.mes)}\n${dato.energia.toStringAsFixed(2)} kWh',
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

class GraficasAnioConFiltro extends StatefulWidget {
  final DateTime fechaSeleccionada;
  
  const GraficasAnioConFiltro({
    Key? key,
    required this.fechaSeleccionada,
  }) : super(key: key);

  @override
  State<GraficasAnioConFiltro> createState() => _GraficasAnioConFiltroState();
}

class _GraficasAnioConFiltroState extends State<GraficasAnioConFiltro> {
  List<DatoEnergiaAnio> _datosEnergia = [];
  bool _cargando = true;
  bool _hayError = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    print('🚀 Inicializando gráfica anual con filtro: ${widget.fechaSeleccionada}');
    _cargarDatosConFecha(widget.fechaSeleccionada);
    _iniciarTimer();
  }

  @override
  void didUpdateWidget(GraficasAnioConFiltro oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fechaSeleccionada != widget.fechaSeleccionada) {
      print('📅 Fecha anual cambió a: ${widget.fechaSeleccionada}');
      _cargarDatosConFecha(widget.fechaSeleccionada);
    }
  }

  void _iniciarTimer() {
    _timer?.cancel();
    final duracion = _hayError ? Duration(seconds: 20) : Duration(minutes: 5);
    
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

  Future<void> _cargarDatosConFecha(DateTime fecha) async {
    setState(() {
      _cargando = true;
    });
    
    try {
      // Para gráfica anual, obtener todo el año
      final String inicio = '${fecha.year}-01';
      final String fin = '${fecha.year}-12';
      
      print('🔍 Consultando API anual: $inicio a $fin');
      
      final datos = await ApiService.obtenerDatosPorAnioConFiltro(inicio, fin);
      
      if (mounted) {
        final datosFiltrados = datos
          .map((dato) => DatoEnergiaAnio(
            mes: dato['mes'],
            energia: dato['energia'],
          ))
          .toList();
          
        // Ordenar por mes
        datosFiltrados.sort((a, b) => a.mes.compareTo(b.mes));
        
        print('📊 Datos anuales procesados: ${datosFiltrados.length} registros');
        
        setState(() {
          _datosEnergia = datosFiltrados;
          _cargando = false;
          _hayError = false;
        });
      }
    } catch (e) {
      print('❌ Error cargando datos anuales con filtro: $e');
      
      if (mounted) {
        setState(() {
          _datosEnergia = [];
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
            const Text(
              'Energía Generada por Mes del Año',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Datos del año ${widget.fechaSeleccionada.year}',
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
                  : _datosEnergia.isEmpty
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
          'No se pudieron obtener los datos para este año',
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
        Icon(Icons.event, size: 48, color: Colors.grey.shade400),
        const SizedBox(height: 16),
        const Text(
          'No hay datos disponibles',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          'No se encontraron registros para el año ${widget.fechaSeleccionada.year}',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // Reutilizar las funciones de la clase original
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
                            '${_nombreMes(dato.mes)}\n${dato.energia.toStringAsFixed(2)} KWh',
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