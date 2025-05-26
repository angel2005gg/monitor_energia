import 'package:flutter/material.dart';
import 'dart:async';
import '../services/api_service.dart';
import '../widgets/dato_card.dart';
import '../widgets/header_app.dart';
import '../widgets/graficas_panel.dart';
import '../widgets/medidor_analogico.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String energia = 'Cargando...';
  String potencia = 'Cargando...';
  
  // Nuevas variables para los campos adicionales
  String energiaEsteMes = '';
  String energiaTotal = '';
  String energiaEsteAnio = '';
  
  bool isLoading = true;
  DateTime? ultimaActualizacion;
  
  // Variables para almacenar los últimos datos válidos
  String? ultimaEnergia;
  String? ultimaPotencia;
  String? ultimaEnergiaEsteMes;
  String? ultimaEnergiaTotal;
  String? ultimaEnergiaEsteAnio;
  
  bool hayConexion = true;

  // AÑADIR: PageController para el carrusel
  PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  // AÑADIR: Dispose del PageController
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> cargarDatos() async {
    setState(() {
      isLoading = true;
      if (hayConexion) {
        energia = '--';
        potencia = '--';
      }
    });
    
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      
      final datos = await ApiService.obtenerDatos();
      
      if (!mounted) return;
      
      final ahora = DateTime.now().subtract(const Duration(hours: 5));
      
      ultimaEnergia = '${datos['energiaGeneradaHoy']} kWh';
      ultimaPotencia = '${datos['potenciaInstantanea']} kW';
      ultimaEnergiaEsteMes = datos['energiaEsteMes'] ?? 'No disponible';
      ultimaEnergiaTotal = datos['energiaTotal'] ?? 'No disponible';
      ultimaEnergiaEsteAnio = datos['energiaEsteAño'] ?? 'No disponible';
      
      print('Energia este mes: ${datos['energiaEsteMes']}');
      print('Energia total: ${datos['energiaTotal']}');
      
      setState(() {
        energia = ultimaEnergia!;
        potencia = ultimaPotencia!;
        energiaEsteMes = ultimaEnergiaEsteMes!;
        energiaTotal = ultimaEnergiaTotal!;
        energiaEsteAnio = ultimaEnergiaEsteAnio!;
        ultimaActualizacion = ahora;
        isLoading = false;
        hayConexion = true;
        
        print('Hora actualizada: ${_formatFecha(ahora)}');
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Datos actualizados: ${_formatFecha(ahora)}'),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );
      
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        if (ultimaEnergia != null && ultimaPotencia != null) {
          energia = ultimaEnergia!;
          potencia = ultimaPotencia!;
          if (ultimaEnergiaEsteMes != null) energiaEsteMes = ultimaEnergiaEsteMes!;
          if (ultimaEnergiaTotal != null) energiaTotal = ultimaEnergiaTotal!;
          if (ultimaEnergiaEsteAnio != null) energiaEsteAnio = ultimaEnergiaEsteAnio!;
        } else {
          energia = 'No disponible';
          potencia = 'No disponible';
          energiaEsteMes = 'No disponible';
          energiaTotal = 'No disponible';
          energiaEsteAnio = 'No disponible';
        }
        isLoading = false;
        hayConexion = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No se puede conectar al servidor. Mostrando últimos datos disponibles.'),
          action: SnackBarAction(
            label: 'Reintentar',
            onPressed: cargarDatos,
          ),
          duration: const Duration(seconds: 5),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: const HeaderApp(),
      backgroundColor: const Color(0xFFF4F6F8),
      body: RefreshIndicator(
        onRefresh: cargarDatos,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // CARRUSEL DEL PANEL PRINCIPAL
              SizedBox(
                height: 350, // Altura fija para el carrusel
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (int page) {
                    setState(() {
                      _currentPage = page;
                    });
                  },
                  children: [
                    // PÁGINA 1: Panel original con medidor
                    _buildPanelPrincipal(),
                    
                    // PÁGINA 2: Panel duplicado (por ahora igual)
                    _buildPanelSecundario(),
                  ],
                ),
              ),
              
              // INDICADORES DEL CARRUSEL
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildIndicator(0),
                  const SizedBox(width: 8),
                  _buildIndicator(1),
                ],
              ),
              
              // Tarjetas de datos detallados (MANTENER TODO IGUAL)
              const SizedBox(height: 24),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Información Detallada',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildDetailRow('Energía Generada Hoy', energia, Icons.bolt, Colors.orange),
                        const Divider(height: 24),
                        _buildDetailRow('Potencia Instantánea', potencia, Icons.flash_on, Colors.blue),
                        const Divider(height: 24),
                        _buildDetailRow('Energía Este Mes', energiaEsteMes, Icons.calendar_today, Colors.green),
                        const Divider(height: 24),
                        _buildDetailRow('Energía Este Año', energiaEsteAnio, Icons.event, Colors.purple),
                        const Divider(height: 24),
                        _buildDetailRow('Energía Total', energiaTotal, Icons.public, Colors.teal),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Panel para gráficas (MANTENER TODO IGUAL)
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Gráfica de Rendimiento',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: isLoading ? null : cargarDatos,
                      tooltip: 'Actualizar datos',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: GraficasPanel(),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
  
  // NUEVO: Panel principal (página 1 del carrusel)
  Widget _buildPanelPrincipal() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: hayConexion 
          ? const LinearGradient(
            colors: [Color(0xFF0A2E73), Color(0xFF083A5C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
          : const LinearGradient(
            colors: [Color(0xFF9E9E9E), Color(0xFF616161)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: hayConexion ? Color(0xFF0A2E73).withOpacity(0.3) : Colors.grey.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Potencia Actual',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: hayConexion 
                      ? Colors.green.withOpacity(0.8)
                      : Colors.orange.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      hayConexion 
                        ? Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          )
                        : const Icon(Icons.wifi_off, color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        hayConexion ? 'Online' : 'Sin conexión',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Medidor analógico
            Center(
              child: MedidorAnalogico(
                valor: double.tryParse(potencia.split(' ')[0]) ?? 0.0,
                capacidadMaxima: 12.78,
                unidad: 'kW',
              ),
            ),
            
            const SizedBox(height: 16),
            Center(
              child: Text(
                hayConexion 
                    ? 'Actualizado: ${ultimaActualizacion != null ? _formatFecha(ultimaActualizacion!) : "Cargando..."}'
                    : 'Último dato disponible: ${ultimaActualizacion != null ? _formatFecha(ultimaActualizacion!) : "No disponible"}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // NUEVO: Panel secundario (página 2 del carrusel) - por ahora igual
  Widget _buildPanelSecundario() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: hayConexion 
          ? const LinearGradient(
            colors: [Color(0xFF0A2E73), Color(0xFF083A5C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
          : const LinearGradient(
            colors: [Color(0xFF9E9E9E), Color(0xFF616161)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: hayConexion ? Color(0xFF0A2E73).withOpacity(0.3) : Colors.grey.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título y estado de conexión
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Resumen Energético',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: hayConexion 
                        ? Colors.green.withOpacity(0.8)
                        : Colors.orange.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        hayConexion 
                          ? Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            )
                          : const Icon(Icons.wifi_off, color: Colors.white, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          hayConexion ? 'Online' : 'Sin conexión',
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Primera fila: Energía Hoy y Energía Este Mes
              Row(
                children: [
                  Expanded(
                    child: _buildDataItem(
                      'Energía Hoy',
                      energia,
                      Icons.bolt,
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 10), // Reducido de 20 a 10
                  Expanded(
                    child: _buildDataItem(
                      'Energía Este Mes',
                      energiaEsteMes,
                      Icons.calendar_today,
                      Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16), // Reducido de 30 a 16
              // Segunda fila: Energía Este Año y Energía Total
              Row(
                children: [
                  Expanded(
                    child: _buildDataItem(
                      'Energía Este Año',
                      energiaEsteAnio,
                      Icons.event,
                      Colors.purple,
                    ),
                  ),
                  const SizedBox(width: 10), // Reducido de 20 a 10
                  Expanded(
                    child: _buildDataItem(
                      'Energía Total',
                      energiaTotal,
                      Icons.public,
                      Colors.teal,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // NUEVO: Indicadores del carrusel
  Widget _buildIndicator(int index) {
    return GestureDetector(
      onTap: () {
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _currentPage == index 
            ? const Color(0xFF0A2E73)
            : Colors.grey.shade300,
        ),
      ),
    );
  }
  
  // MANTENER TODOS LOS MÉTODOS EXISTENTES IGUAL
  Widget _buildInfoCircle(String title, String value, Color color) {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.15),
            border: Border.all(color: color, width: 2),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value.split(' ')[0],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  value.contains(' ') ? value.split(' ')[1] : '',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String title, String value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDataItem(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: color.withOpacity(0.13),
            shape: BoxShape.circle,
          ),
          padding: const EdgeInsets.all(12),
          child: Icon(icon, color: color, size: 32),
        ),
        const SizedBox(height: 6), // Reducido de 10 a 6
        Text(
          title,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.2,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4), // Reducido de 6 a 4
        Container(
          height: 2,
          width: 32,
          decoration: BoxDecoration(
            color: color.withOpacity(0.18),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  String _formatFecha(DateTime fecha) {
    final bool isAM = fecha.hour < 12;
    final int hour12 = fecha.hour > 12 ? fecha.hour - 12 : (fecha.hour == 0 ? 12 : fecha.hour);
    return '${hour12}:${fecha.minute.toString().padLeft(2, '0')}:${fecha.second.toString().padLeft(2, '0')} ${isAM ? 'AM' : 'PM'}';
  }
}