import 'package:flutter/material.dart';
import 'dart:async';
import '../services/api_service.dart';
import '../widgets/dato_card.dart';
import '../widgets/header_app.dart';
import '../widgets/graficas_panel.dart';
import '../widgets/medidor_analogico.dart';
import '../widgets/graficas_mes.dart';
import '../widgets/graficas_anio.dart';
import '../utils/utilidades.dart';
import '../widgets/filtro_fechas.dart'; // ← IMPORTAR el nuevo widget


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

  // PageController para el carrusel
  PageController _pageController = PageController();
  int _currentPage = 0;

  // NUEVO: Variable para controlar qué gráfica mostrar
  String _tipoGraficaSeleccionada = 'Día';
  
  // ← AGREGAR: Variable para la fecha seleccionada
  DateTime _fechaSeleccionada = horaActualColombia();
  
  // ← AGREGAR: Key para forzar rebuild de gráficas
  Key _graficaKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

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
      
      // CAMBIAR ESTA LÍNEA:
      // final ahora = DateTime.now().subtract(const Duration(hours: 5));
      // POR ESTA:
      final ahora = horaActualColombia(); // Usar la función de utilidades
    
      ultimaEnergia = '${datos['energiaGeneradaHoy']} kWh';
      ultimaPotencia = '${datos['potenciaInstantanea']} kW';
      ultimaEnergiaEsteMes = datos['energiaEsteMes'] ?? 'No disponible';
      ultimaEnergiaTotal = datos['energiaTotal'] ?? 'No disponible';
      ultimaEnergiaEsteAnio = datos['energiaEsteAño'] ?? 'No disponible';
      
      setState(() {
        energia = ultimaEnergia!;
        potencia = ultimaPotencia!;
        energiaEsteMes = ultimaEnergiaEsteMes!;
        energiaTotal = ultimaEnergiaTotal!;
        energiaEsteAnio = ultimaEnergiaEsteAnio!;
        ultimaActualizacion = ahora;
        isLoading = false;
        hayConexion = true;
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
    return Scaffold(
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
                height: 350,
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
                    
                    // PÁGINA 2: Panel de resumen energético
                    _buildPanelSecundario(),
                    
                    // ← NUEVA PÁGINA 3: Panel terciario (vacío por ahora)
                    _buildPanelTerciario(),
                  ],
                ),
              ),
              
              // INDICADORES DEL CARRUSEL - ← ACTUALIZAR PARA 3 PÁGINAS
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildIndicator(0),
                  const SizedBox(width: 8),
                  _buildIndicator(1),
                  const SizedBox(width: 8),
                  _buildIndicator(2), // ← AGREGAR TERCER INDICADOR
                ],
              ),
              
              // SECCIÓN DE GRÁFICAS
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
              const SizedBox(height: 16),
              
              // BOTONES DE SELECCIÓN DE GRÁFICA
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildGraficaButton('Día'),
                    const SizedBox(width: 12),
                    _buildGraficaButton('Mes'),
                    const SizedBox(width: 12),
                    _buildGraficaButton('Año'),
                  ],
                ),
              ),
              
              // ← AGREGAR FILTRO AQUÍ (debajo de los botones)
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: FiltroFechas(
                  tipoGrafica: _tipoGraficaSeleccionada,
                  onFechaSeleccionada: (nuevaFecha) {
                    print('🔄 Fecha seleccionada: $nuevaFecha');
                    setState(() {
                      _fechaSeleccionada = nuevaFecha;
                      _graficaKey = UniqueKey(); // ← Forzar rebuild de la gráfica
                    });
                  },
                ),
              ),

              const SizedBox(height: 16),
              
              // CONTENEDOR DE GRÁFICAS (sin filtro interno)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: KeyedSubtree(
                  key: _graficaKey, // ← Usar la key para forzar rebuild
                  child: _buildGraficaActual(),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // NUEVO: Botón para seleccionar tipo de gráfica
  Widget _buildGraficaButton(String tipo) {
    final bool isSelected = _tipoGraficaSeleccionada == tipo;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _tipoGraficaSeleccionada = tipo;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected 
            ? const Color(0xFF0A2E73) // Color del header/carrusel cuando está seleccionado
            : Colors.white, // Fondo blanco cuando no está seleccionado
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: const Color(0xFF0A2E73),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          tipo,
          style: TextStyle(
            color: isSelected 
              ? Colors.white // Letras blancas cuando está seleccionado
              : Colors.black, // Letras negras cuando no está seleccionado
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // NUEVO: Mostrar la gráfica actual según la selección
  Widget _buildGraficaActual() {
    switch (_tipoGraficaSeleccionada) {
      case 'Día':
        return GraficasPanelConFiltro(fechaSeleccionada: _fechaSeleccionada); // ← Pasar fecha
      case 'Mes':
        return GraficasMesConFiltro(fechaSeleccionada: _fechaSeleccionada); // ← Pasar fecha
      case 'Año':
        return GraficasAnioConFiltro(fechaSeleccionada: _fechaSeleccionada); // ← Pasar fecha
      default:
        return GraficasPanelConFiltro(fechaSeleccionada: _fechaSeleccionada);
    }
  }

  // Panel principal (página 1 del carrusel)
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

  // Panel secundario (página 2 del carrusel)
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
                  const SizedBox(width: 10),
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
              const SizedBox(height: 16),
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
                  const SizedBox(width: 10),
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
        const SizedBox(height: 6),
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
        const SizedBox(height: 4),
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

  // REEMPLAZAR el método _formatFecha por este:
  String _formatFecha(DateTime fecha) {
    // Usar el formateador de utilidades que ya funciona correctamente
    return formatearHoraColombia(fecha);
  }

  // Panel terciario (página 3 del carrusel) - POR AHORA VACÍO
  Widget _buildPanelTerciario() {
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
            // Título y estado de conexión
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Panel Adicional',
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
            
            const SizedBox(height: 30),
            
            // ← CONTENIDO VACÍO POR AHORA - CENTRADO
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icono placeholder
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.construction,
                        size: 48,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Texto placeholder
                    Text(
                      'Próximamente',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    Text(
                      'Esta sección estará disponible pronto',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Botones placeholder (decorativos por ahora)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildPlaceholderButton('Opción 1', Icons.analytics),
                        const SizedBox(width: 16),
                        _buildPlaceholderButton('Opción 2', Icons.settings),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            // Pie del panel
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

  // Botón placeholder para el panel terciario
  Widget _buildPlaceholderButton(String texto, IconData icono) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icono,
            size: 16,
            color: Colors.white.withOpacity(0.7),
          ),
          const SizedBox(width: 8),
          Text(
            texto,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}