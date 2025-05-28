import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';  // AGREGAR ESTE IMPORT
import 'package:monitor_energia/services/api_service.dart';

class ConfiguracionesScreen extends StatefulWidget {
  const ConfiguracionesScreen({Key? key}) : super(key: key);

  @override
  State<ConfiguracionesScreen> createState() => _ConfiguracionesScreenState();
}

class _ConfiguracionesScreenState extends State<ConfiguracionesScreen> {
  // ELIMINAR este controlador:
  // final TextEditingController _produccionMensualController = TextEditingController();
  
  // Controladores para los campos de entrada (SOLO 2 AHORA)
  final TextEditingController _costoProyectoController = TextEditingController();
  final TextEditingController _precioKwhController = TextEditingController();

  // Variables para almacenar los valores
  double _costoProyecto = 0.0;
  double _precioKwh = 0.0;
  double _produccionMensual = 0.0; // Este se obtendrá de la API

  // NUEVA VARIABLE para mostrar los datos de la API
  String _energiaEsteMesAPI = '';
  bool _datosAPICargados = false;

  // Variables calculadas
  double _ahorroMensual = 0.0;
  List<double> _ahorroAcumulado = [];
  int _mesesParaPago = 0;
  bool _proyectoPagado = false;

  @override
  void initState() {
    super.initState();
    _cargarDatosAPI(); // Cargar datos de la API al inicializar
  }

  // NUEVO MÉTODO: Cargar datos de la API
  Future<void> _cargarDatosAPI() async {
    try {
      final datos = await ApiService.obtenerDatos();
      
      if (mounted) {
        setState(() {
          _energiaEsteMesAPI = datos['energiaEsteMes'] ?? '0 kWh';
          
          // Extraer solo el número de la cadena "897 kWh" -> 897.0
          String numeroStr = _energiaEsteMesAPI.split(' ')[0];
          _produccionMensual = double.tryParse(numeroStr) ?? 0.0;
          
          _datosAPICargados = true;
        });
        
        print('Datos de API cargados - Energía este mes: $_energiaEsteMesAPI ($_produccionMensual kWh)');
      }
    } catch (e) {
      print('Error cargando datos de la API: $e');
      setState(() {
        _energiaEsteMesAPI = 'No disponible';
        _datosAPICargados = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text(
              'Configuraciones',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0A2E73),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Calcula la rentabilidad de tu sistema solar',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 30),
            
            // TARJETA DE CONFIGURACIÓN DEL PROYECTO SOLAR
            _buildTarjetaConfiguracion(),
            
            const SizedBox(height: 20),
            
            // TARJETA DE RESULTADOS (solo si hay datos)
            if (_costoProyecto > 0 && _precioKwh > 0 && _produccionMensual > 0)
              _buildTarjetaResultados(),
            
            const SizedBox(height: 20),
            
            // ESPACIO PARA FUTURA GRÁFICA
            if (_ahorroAcumulado.isNotEmpty)
              _buildEspacioGrafica(),
          ],
        ),
      ),
    );
  }

  // AGREGAR ESTE MÉTODO que falta:
  Widget _buildChip(String texto, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        texto,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  // AGREGAR ESTE MÉTODO que falta:
  Widget _buildCampoEntrada(
    String titulo,
    String hint,
    TextEditingController controller,
    IconData icono,
    Color color,
    String sufijo,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0A2E73),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icono, color: color),
            suffixText: sufijo,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF0A2E73), width: 2),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
        ),
      ],
    );
  }

  Widget _buildTarjetaConfiguracion() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A2E73).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.solar_power,
                    color: Color(0xFF0A2E73),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cálculo de Rentabilidad Solar',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Solo completa 2 campos, el resto lo tomamos de tu sistema',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // CAMPO: Costo del proyecto
            _buildCampoEntrada(
              'Costo del Proyecto Solar',
              'Ingresa el costo total en COP',
              _costoProyectoController,
              Icons.attach_money,
              Colors.green,
              'COP',
            ),
            
            const SizedBox(height: 16),
            
            // CAMPO: Precio por kWh
            _buildCampoEntrada(
              'Precio por kWh',
              'Precio que cobra tu comercializador',
              _precioKwhController,
              Icons.flash_on,
              Colors.orange,
              'COP/kWh',
            ),
            
            const SizedBox(height: 16),
            
            // NUEVO: MOSTRAR DATO DE LA API (NO EDITABLE)
            _buildCampoAPI(
              'Producción Mensual (Datos del Sistema)',
              _datosAPICargados ? _energiaEsteMesAPI : 'Cargando...',
              Icons.wb_sunny,
              Colors.blue,
            ),
            
            const SizedBox(height: 24),
            
            // BOTÓN CALCULAR (con validación mejorada)
            Center(
              child: ElevatedButton.icon(
                onPressed: _datosAPICargados ? _calcularRentabilidad : null,
                icon: const Icon(Icons.calculate, color: Colors.white),
                label: Text(
                  _datosAPICargados ? 'Calcular Rentabilidad' : 'Cargando datos...',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _datosAPICargados 
                    ? const Color(0xFF0A2E73) 
                    : Colors.grey,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCampoAPI(
    String titulo,
    String valor,
    IconData icono,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0A2E73),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3), width: 1.5),
          ),
          child: Row(
            children: [
              Icon(icono, color: color),
              const SizedBox(width: 12),
              Text(
                valor,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Automático',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTarjetaResultados() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.trending_up,
                    color: Colors.green,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  'Resultados del Análisis',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // RESULTADO: Ahorro mensual
            _buildResultadoItem(
              'Ahorro Mensual',
              '\$${_formatearNumero(_ahorroMensual)} COP',
              Icons.calendar_month,
              Colors.blue,
            ),
            
            const Divider(height: 24),
            
            // RESULTADO: Tiempo para pagar el proyecto
            _buildResultadoItem(
              _proyectoPagado ? 'Proyecto Pagado en' : 'Se pagará en',
              '$_mesesParaPago meses (${(_mesesParaPago / 12).toStringAsFixed(1)} años)',
              _proyectoPagado ? Icons.check_circle : Icons.access_time,
              _proyectoPagado ? Colors.green : Colors.orange,
            ),
            
            const Divider(height: 24),
            
            // RESULTADO: Ahorro total estimado
            if (_ahorroAcumulado.isNotEmpty)
              _buildResultadoItem(
                'Ahorro Acumulado (${_mesesParaPago} meses)',
                '\$${_formatearNumero(_ahorroAcumulado.last)} COP',
                Icons.savings,
                Colors.teal,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultadoItem(String titulo, String valor, IconData icono, Color color) {
    return Row(
      children: [
        Icon(icono, color: color, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                valor,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEspacioGrafica() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.show_chart,
                    color: Colors.purple,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  'Gráfica de Rentabilidad',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // INFORMACIÓN RESUMIDA
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Wrap(
                spacing: 16,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _buildChip('Inversión: \$${_formatearNumero(_costoProyecto)}', Colors.red),
                  _buildChip('Punto de equilibrio: Mes $_mesesParaPago', Colors.green),
                  _buildChip('Ahorro mensual: \$${_formatearNumero(_ahorroMensual)}', Colors.blue),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // LA GRÁFICA REAL
            SizedBox(
              height: 300,
              width: double.infinity,
              child: _construirGraficaRentabilidad(),
            ),
            
            const SizedBox(height: 16),
            
            // LEYENDA
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLeyendaItem('Ahorro Acumulado', Colors.green),
                const SizedBox(width: 20),
                _buildLeyendaItem('Costo del Proyecto', Colors.red),
                const SizedBox(width: 20),
                _buildLeyendaItem('Punto de Equilibrio', Colors.orange),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // NUEVO: Construir la gráfica de rentabilidad
  Widget _construirGraficaRentabilidad() {
    if (_ahorroAcumulado.isEmpty) {
      return const Center(
        child: Text('Realiza el cálculo para ver la gráfica'),
      );
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawHorizontalLine: true,
          drawVerticalLine: false,
          horizontalInterval: _costoProyecto / 5, // 5 líneas horizontales
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
            axisNameWidget: const Text(
              'Meses',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: _mesesParaPago > 24 ? 12 : 6, // Mostrar cada 6 o 12 meses
              getTitlesWidget: (double value, TitleMeta meta) {
                return Text(
                  '${value.toInt()}',
                  style: const TextStyle(fontSize: 12),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            axisNameWidget: const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: RotatedBox(
                quarterTurns: 3,
                child: Text(
                  'Dinero Acumulado (COP)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 60,
              interval: _costoProyecto / 4, // 4 intervalos en Y
              getTitlesWidget: (double value, TitleMeta meta) {
                return Text(
                  '\$${_formatearNumeroCorto(value)}',
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.shade400, width: 1),
        ),
        minX: 0,
        maxX: _mesesParaPago.toDouble() + 6, // Un poco más para ver mejor
        minY: 0,
        maxY: _costoProyecto * 1.2, // 20% más para que se vea bien
        lineBarsData: [
          // LÍNEA 1: Ahorro acumulado (verde ascendente)
          LineChartBarData(
            spots: _ahorroAcumulado.asMap().entries.map((entry) {
              return FlSpot(entry.key.toDouble() + 1, entry.value);
            }).toList(),
            isCurved: false,
            color: Colors.green,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: false, // No mostrar puntos en la línea
            ),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.green.withOpacity(0.1),
            ),
          ),
          
          // LÍNEA 2: Costo del proyecto (línea horizontal roja)
          LineChartBarData(
            spots: [
              FlSpot(0, _costoProyecto),
              FlSpot(_mesesParaPago.toDouble() + 6, _costoProyecto),
            ],
            isCurved: false,
            color: Colors.red,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            dashArray: [5, 5], // Línea punteada
          ),
        ],
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            tooltipPadding: const EdgeInsets.all(8),
            tooltipMargin: 8,
            getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
              return touchedBarSpots.map((barSpot) {
                if (barSpot.barIndex == 0) { // Línea de ahorro
                  final mes = barSpot.x.toInt();
                  final ahorro = barSpot.y;
                  return LineTooltipItem(
                    'Mes $mes\nAhorro: \$${_formatearNumero(ahorro)}',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  );
                } else { // Línea de costo
                  return LineTooltipItem(
                    'Costo del Proyecto\n\$${_formatearNumero(_costoProyecto)}',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  );
                }
              }).toList();
            },
          ),
          handleBuiltInTouches: true,
        ),
        // MARCADOR ESPECIAL: Punto de equilibrio
        extraLinesData: ExtraLinesData(
          verticalLines: [
            VerticalLine(
              x: _mesesParaPago.toDouble(),
              color: Colors.orange,
              strokeWidth: 3,
              dashArray: [8, 4],
              label: VerticalLineLabel(
                show: true,
                alignment: Alignment.topRight,
                padding: const EdgeInsets.only(right: 8),
                style: const TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
                labelResolver: (line) => '¡Aquí se paga!',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // NUEVO: Leyenda de la gráfica
  Widget _buildLeyendaItem(String texto, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          texto,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // NUEVO: Formatear números para los ejes
  String _formatearNumeroCorto(double numero) {
    if (numero >= 1000000) {
      return '${(numero / 1000000).toStringAsFixed(0)}M';
    } else if (numero >= 1000) {
      return '${(numero / 1000).toStringAsFixed(0)}K';
    } else {
      return numero.toStringAsFixed(0);
    }
  }

  void _calcularRentabilidad() {
    // Obtener valores de los campos (SOLO 2 CAMPOS AHORA)
    _costoProyecto = double.tryParse(_costoProyectoController.text) ?? 0.0;
    _precioKwh = double.tryParse(_precioKwhController.text) ?? 0.0;
    // _produccionMensual ya se obtuvo de la API

    if (_costoProyecto <= 0 || _precioKwh <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor completa los campos de costo y precio por kWh'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_produccionMensual <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pueden obtener datos de producción del sistema. Intenta más tarde.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // CÁLCULOS (igual que antes)
    _ahorroMensual = _produccionMensual * _precioKwh;
    
    // Calcular ahorro acumulado mes a mes hasta que se pague el proyecto
    _ahorroAcumulado.clear();
    double acumulado = 0.0;
    int mes = 0;
    
    while (acumulado < _costoProyecto && mes < 600) { // Máximo 50 años
      mes++;
      acumulado += _ahorroMensual;
      _ahorroAcumulado.add(acumulado);
    }
    
    _mesesParaPago = mes;
    _proyectoPagado = acumulado >= _costoProyecto;

    setState(() {});

    // Mostrar mensaje de éxito
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _proyectoPagado 
            ? '¡Proyecto se paga en $_mesesParaPago meses! (${(_mesesParaPago / 12).toStringAsFixed(1)} años)'
            : 'Cálculo completado usando ${_produccionMensual.toStringAsFixed(1)} kWh/mes del sistema'
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  String _formatearNumero(double numero) {
    if (numero >= 1000000) {
      return '${(numero / 1000000).toStringAsFixed(1)}M';
    } else if (numero >= 1000) {
      return '${(numero / 1000).toStringAsFixed(0)}K';
    } else {
      return numero.toStringAsFixed(0);
    }
  }
}