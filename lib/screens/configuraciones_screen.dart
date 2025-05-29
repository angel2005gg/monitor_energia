import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:monitor_energia/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConfiguracionesScreen extends StatefulWidget {
  const ConfiguracionesScreen({Key? key}) : super(key: key);

  @override
  State<ConfiguracionesScreen> createState() => _ConfiguracionesScreenState();
}

class _ConfiguracionesScreenState extends State<ConfiguracionesScreen> {
  // Controladores para los campos de entrada
  final TextEditingController _costoProyectoController = TextEditingController();
  final TextEditingController _precioKwhController = TextEditingController();

  // Variables para almacenar los valores
  double _costoProyecto = 0.0;
  double _precioKwh = 0.0;
  double _produccionMensual = 0.0;

  // Variables para mostrar los datos de la API
  String _energiaEsteMesAPI = '';
  bool _datosAPICargados = false;

  // Variables calculadas
  double _ahorroMensual = 0.0;
  List<double> _ahorroAcumulado = [];
  int _mesesParaPago = 0;
  bool _proyectoPagado = false;

  // NUEVA VARIABLE: Indicar si hay datos guardados
  bool _hayDatosGuardados = false;

  @override
  void initState() {
    super.initState();
    _cargarDatosAPI();
    _cargarDatosGuardados();
  }

  // MÉTODO: Cargar datos de la API
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

  // MÉTODO: Cargar datos guardados
  Future<void> _cargarDatosGuardados() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Cargar datos de los campos
      final costoGuardado = prefs.getDouble('costo_proyecto') ?? 0.0;
      final precioGuardado = prefs.getDouble('precio_kwh') ?? 0.0;
      
      // Cargar resultados calculados
      final ahorroMensualGuardado = prefs.getDouble('ahorro_mensual') ?? 0.0;
      final mesesParaPagoGuardado = prefs.getInt('meses_para_pago') ?? 0;
      final proyectoPagadoGuardado = prefs.getBool('proyecto_pagado') ?? false;
      
      // Cargar lista de ahorro acumulado
      final ahorroAcumuladoString = prefs.getStringList('ahorro_acumulado') ?? [];
      final ahorroAcumuladoGuardado = ahorroAcumuladoString
          .map((e) => double.tryParse(e) ?? 0.0)
          .toList();

      // Si hay datos guardados, aplicarlos
      if (costoGuardado > 0 && precioGuardado > 0) {
        setState(() {
          _costoProyecto = costoGuardado;
          _precioKwh = precioGuardado;
          _ahorroMensual = ahorroMensualGuardado;
          _mesesParaPago = mesesParaPagoGuardado;
          _proyectoPagado = proyectoPagadoGuardado;
          _ahorroAcumulado = ahorroAcumuladoGuardado;
          _hayDatosGuardados = true;
          
          // Llenar los campos de texto
          _costoProyectoController.text = costoGuardado.toStringAsFixed(0);
          _precioKwhController.text = precioGuardado.toStringAsFixed(0);
        });

        print('Datos de rentabilidad cargados desde almacenamiento local');
        
        // Mostrar mensaje informativo
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Datos de rentabilidad cargados automáticamente'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('Error cargando datos guardados: $e');
    }
  }

  // MÉTODO: Guardar datos
  Future<void> _guardarDatos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Guardar datos de los campos
      await prefs.setDouble('costo_proyecto', _costoProyecto);
      await prefs.setDouble('precio_kwh', _precioKwh);
      
      // Guardar resultados calculados
      await prefs.setDouble('ahorro_mensual', _ahorroMensual);
      await prefs.setInt('meses_para_pago', _mesesParaPago);
      await prefs.setBool('proyecto_pagado', _proyectoPagado);
      
      // Guardar lista de ahorro acumulado como strings
      final ahorroAcumuladoString = _ahorroAcumulado
          .map((e) => e.toString())
          .toList();
      await prefs.setStringList('ahorro_acumulado', ahorroAcumuladoString);
      
      // Guardar timestamp de cuando se guardaron los datos
      await prefs.setString('fecha_guardado', DateTime.now().toIso8601String());
      
      print('Datos de rentabilidad guardados exitosamente');
    } catch (e) {
      print('Error guardando datos: $e');
    }
  }

  // MÉTODO: Limpiar datos guardados
  Future<void> _limpiarDatosGuardados() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Eliminar todas las claves relacionadas con rentabilidad
      await prefs.remove('costo_proyecto');
      await prefs.remove('precio_kwh');
      await prefs.remove('ahorro_mensual');
      await prefs.remove('meses_para_pago');
      await prefs.remove('proyecto_pagado');
      await prefs.remove('ahorro_acumulado');
      await prefs.remove('fecha_guardado');
      
      // Limpiar la interfaz
      setState(() {
        _costoProyecto = 0.0;
        _precioKwh = 0.0;
        _ahorroMensual = 0.0;
        _mesesParaPago = 0;
        _proyectoPagado = false;
        _ahorroAcumulado.clear();
        _hayDatosGuardados = false;
        
        // Limpiar los campos de texto
        _costoProyectoController.clear();
        _precioKwhController.clear();
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🗑️ Datos de rentabilidad eliminados'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      
      print('Datos de rentabilidad eliminados');
    } catch (e) {
      print('Error eliminando datos: $e');
    }
  }

  // MÉTODO: Calcular en hilo separado
  Future<Map<String, dynamic>> _calcularEnHiloSeparado() async {
    return await Future(() async {
      // CÁLCULOS (movidos aquí para no bloquear la UI)
      double ahorroMensual = _produccionMensual * _precioKwh;
      
      // Calcular ahorro acumulado mes a mes hasta que se pague el proyecto
      List<double> ahorroAcumulado = [];
      double acumulado = 0.0;
      int mes = 0;
      
      // LIMITAR EL CÁLCULO para evitar loops infinitos
      int maxMeses = 1200; // Máximo 100 años (más que suficiente)
      
      while (acumulado < _costoProyecto && mes < maxMeses) {
        mes++;
        acumulado += ahorroMensual;
        ahorroAcumulado.add(acumulado);
        
        // Agregar un pequeño delay cada 100 iteraciones para no bloquear
        if (mes % 100 == 0) {
          // Pequeña pausa para permitir que otros procesos corran
          await Future.delayed(const Duration(microseconds: 1));
        }
      }
      
      bool proyectoPagado = acumulado >= _costoProyecto;
      
      return {
        'ahorroMensual': ahorroMensual,
        'ahorroAcumulado': ahorroAcumulado,
        'mesesParaPago': mes,
        'proyectoPagado': proyectoPagado,
      };
    });
  }

  // MÉTODO: Calcular rentabilidad
  Future<void> _calcularRentabilidad() async {
    // Obtener valores de los campos
    _costoProyecto = double.tryParse(_costoProyectoController.text) ?? 0.0;
    _precioKwh = double.tryParse(_precioKwhController.text) ?? 0.0;

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

    // Mostrar indicador de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    try {
      // Realizar cálculos
      final resultados = await _calcularEnHiloSeparado();
      
      // Cerrar indicador de carga
      if (mounted) Navigator.of(context).pop();
      
      if (mounted) {
        setState(() {
          _ahorroMensual = resultados['ahorroMensual'];
          _ahorroAcumulado = resultados['ahorroAcumulado'];
          _mesesParaPago = resultados['mesesParaPago'];
          _proyectoPagado = resultados['proyectoPagado'];
          _hayDatosGuardados = true;
        });

        // GUARDAR DATOS AUTOMÁTICAMENTE DESPUÉS DEL CÁLCULO
        await _guardarDatos();

        // Mostrar mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _proyectoPagado 
                ? '🎉 ¡Proyecto se paga en $_mesesParaPago meses! Datos guardados automáticamente.'
                : '💾 Cálculo completado y guardado. Datos disponibles para próximas sesiones.'
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      // Cerrar indicador de carga en caso de error
      if (mounted) Navigator.of(context).pop();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al calcular la rentabilidad. Intenta de nuevo.'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
            // TÍTULO CON INDICADOR DE DATOS GUARDADOS
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Rentabilidad Solar',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0A2E73),
                    ),
                  ),
                ),
                // MOSTRAR INDICADOR SI HAY DATOS GUARDADOS
                if (_hayDatosGuardados)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.save, size: 16, color: Colors.green),
                        SizedBox(width: 4),
                        Text(
                          'Guardado',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _hayDatosGuardados 
                ? 'Datos cargados automáticamente. Puedes modificarlos si deseas.'
                : 'Calcula cuándo tu sistema solar se paga solo',
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
            
            // ESPACIO PARA GRÁFICA
            if (_ahorroAcumulado.isNotEmpty)
              _buildEspacioGrafica(),
          ],
        ),
      ),
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Cálculo de Rentabilidad Solar',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _hayDatosGuardados 
                          ? 'Datos guardados automáticamente'
                          : 'Solo completa 2 campos, el resto lo tomamos de tu sistema',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                // BOTÓN PARA LIMPIAR DATOS
                if (_hayDatosGuardados)
                  IconButton(
                    onPressed: _limpiarDatosGuardados,
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    tooltip: 'Limpiar datos guardados',
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
            
            // BOTÓN CALCULAR
            Center(
              child: ElevatedButton.icon(
                onPressed: _datosAPICargados ? _calcularRentabilidad : null,
                icon: const Icon(Icons.calculate, color: Colors.white),
                label: Text(
                  _datosAPICargados 
                    ? (_hayDatosGuardados ? 'Recalcular' : 'Calcular Rentabilidad')
                    : 'Cargando datos...',
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

  Widget _buildCampoAPI(String titulo, String valor, IconData icono, Color color) {
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
                    Icons.analytics,
                    color: Colors.purple,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Gráfica de Rentabilidad',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // INFORMACIÓN RESUMIDA - MEJORADA PARA PANTALLAS PEQUEÑAS
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  // PRIMERA FILA
                  Row(
                    children: [
                      Expanded(
                        child: _buildChip('Inversión: \$${_formatearNumero(_costoProyecto)}', Colors.red),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildChip('Equilibrio: Mes $_mesesParaPago', Colors.green),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // SEGUNDA FILA - CHIP COMPLETO
                  Row(
                    children: [
                      Expanded(
                        child: _buildChip('Ahorro mensual: \$${_formatearNumero(_ahorroMensual)}', Colors.blue),
                      ),
                    ],
                  ),
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
            
            // LEYENDA MEJORADA - RESPONSIVE PARA PANTALLAS PEQUEÑAS
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Leyenda',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // PRIMERA FILA DE LEYENDA
                  Row(
                    children: [
                      Expanded(
                        child: _buildLeyendaItem('Ahorro Acumulado', Colors.green),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildLeyendaItem('Costo del Proyecto', Colors.red),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // SEGUNDA FILA DE LEYENDA - CENTRADA
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLeyendaItem('Punto de Equilibrio', Colors.orange),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirGraficaRentabilidad() {
    if (_ahorroAcumulado.isEmpty) {
      return const Center(
        child: Text('Realiza el cálculo para ver la gráfica'),
      );
    }

    // CALCULAR MEJOR LA ESCALA MÁXIMA
    double maxY = _costoProyecto * 1.3;
    double maxAhorro = _ahorroAcumulado.isNotEmpty ? _ahorroAcumulado.last : 0;
    
    if (maxAhorro > maxY) {
      maxY = maxAhorro * 1.2;
    }

    // CALCULAR MEJOR LA ESCALA HORIZONTAL
    int maxX = _mesesParaPago + 3;
    if (_mesesParaPago <= 3) {
      maxX = 6;
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawHorizontalLine: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 6,
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
              interval: _calcularIntervaloX(maxX),
              getTitlesWidget: (double value, TitleMeta meta) {
                return Text(
                  '${value.toInt()}',
                  style: const TextStyle(fontSize: 12),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 70,
              interval: maxY / 5,
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
        maxX: maxX.toDouble(),
        minY: 0,
        maxY: maxY,
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
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.green.withOpacity(0.1),
            ),
          ),
          
          // LÍNEA 2: Costo del proyecto (línea horizontal roja)
          LineChartBarData(
            spots: [
              FlSpot(0, _costoProyecto),
              FlSpot(maxX.toDouble(), _costoProyecto),
            ],
            isCurved: false,
            color: Colors.red,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            dashArray: [5, 5],
          ),
        ],
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (touchedSpot) => const Color(0xFF1F2937),
            tooltipRoundedRadius: 12,
            tooltipPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            tooltipMargin: 16,
            getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
              return touchedBarSpots.map((barSpot) {
                if (barSpot.barIndex == 0) {
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
                } else {
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
        extraLinesData: ExtraLinesData(
          verticalLines: [
            VerticalLine(
              x: _mesesParaPago.toDouble(),
              color: Colors.orange,
              strokeWidth: 3,
              dashArray: [8, 4],
              label: VerticalLineLabel(
                show: true,
                alignment: Alignment.topCenter,
                padding: const EdgeInsets.only(top: 8),
                style: const TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
                labelResolver: (line) => '¡Se paga!',
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _calcularIntervaloX(int maxX) {
    if (maxX <= 6) return 1;
    if (maxX <= 12) return 2;
    if (maxX <= 24) return 3;
    if (maxX <= 60) return 6;
    return 12;
  }

  Widget _buildChip(String texto, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8), // REDUCIR padding horizontal
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16), // REDUCIR borderRadius
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Center( // CENTRAR el texto
        child: Text(
          texto,
          style: TextStyle(
            fontSize: 11, // REDUCIR tamaño de fuente
            fontWeight: FontWeight.w600,
            color: color,
          ),
          textAlign: TextAlign.center, // CENTRAR texto
          maxLines: 2, // PERMITIR 2 líneas si es necesario
          overflow: TextOverflow.ellipsis, // EVITAR overflow
        ),
      ),
    );
  }

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
        Flexible( // CAMBIAR Text por Flexible
          child: Text(
            texto,
            style: const TextStyle(
              fontSize: 11, // REDUCIR tamaño de fuente
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2, // PERMITIR 2 líneas
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
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

  String _formatearNumeroCorto(double numero) {
    if (numero >= 1000000000) {
      return '${(numero / 1000000000).toStringAsFixed(1)}B';
    } else if (numero >= 1000000) {
      return '${(numero / 1000000).toStringAsFixed(1)}M';
    } else if (numero >= 1000) {
      return '${(numero / 1000).toStringAsFixed(0)}K';
    } else {
      return numero.toStringAsFixed(0);
    }
  }
}