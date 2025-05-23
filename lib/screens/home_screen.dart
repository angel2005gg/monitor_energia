import 'package:flutter/material.dart';
import 'dart:async';
import '../services/api_service.dart';
import '../widgets/dato_card.dart';
import '../widgets/header_app.dart';
import '../widgets/graficas_panel.dart';
import '../widgets/medidor_analogico.dart'; // Añadir esta línea

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
  
  bool isLoading = true;
  DateTime? ultimaActualizacion;
  
  // Variables para almacenar los últimos datos válidos
  String? ultimaEnergia;
  String? ultimaPotencia;
  String? ultimaEnergiaEsteMes;
  String? ultimaEnergiaTotal;
  
  bool hayConexion = true;

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  Future<void> cargarDatos() async {
    setState(() {
      isLoading = true;
      if (hayConexion) {
        // Solo limpiamos los datos si no estamos en estado de reconexión
        energia = '--';
        potencia = '--';
      }
    });
    
    try {
      // Pequeña pausa para asegurar que se vea la actualización
      await Future.delayed(const Duration(milliseconds: 300));
      
      final datos = await ApiService.obtenerDatos();
      
      // Verificar que el widget siga montado antes de actualizar el estado
      if (!mounted) return;
      
      // Zona horaria explícita para Colombia
      final ahora = DateTime.now().subtract(const Duration(hours: 5));
      
      // Guardamos los últimos valores válidos
      ultimaEnergia = '${datos['energiaGeneradaHoy']} kWh';
      ultimaPotencia = '${datos['potenciaInstantanea']} kW';
      
      // Guardamos los nuevos campos
      ultimaEnergiaEsteMes = datos['energiaEsteMes'] ?? 'No disponible';
      ultimaEnergiaTotal = datos['energiaTotal'] ?? 'No disponible';
      
      // Imprimir los nuevos datos en consola para verificar
      print('Energia este mes: ${datos['energiaEsteMes']}');
      print('Energia total: ${datos['energiaTotal']}');
      
      setState(() {
        energia = ultimaEnergia!;
        potencia = ultimaPotencia!;
        
        // Actualizamos las variables de estado con los nuevos datos
        energiaEsteMes = ultimaEnergiaEsteMes!;
        energiaTotal = ultimaEnergiaTotal!;
        
        ultimaActualizacion = ahora;
        isLoading = false;
        hayConexion = true;
        
        // Debug para verificar la hora
        print('Hora actualizada: ${_formatFecha(ahora)}');
      });
      
      // Mostrar confirmación de actualización
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Datos actualizados: ${_formatFecha(ahora)}'),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );
      
    } catch (e) {
      // Verificar que el widget siga montado antes de actualizar el estado
      if (!mounted) return;
      
      setState(() {
        if (ultimaEnergia != null && ultimaPotencia != null) {
          // Mostrar últimos datos válidos
          energia = ultimaEnergia!;
          potencia = ultimaPotencia!;
          
          // También mantenemos los últimos valores de los nuevos campos
          if (ultimaEnergiaEsteMes != null) energiaEsteMes = ultimaEnergiaEsteMes!;
          if (ultimaEnergiaTotal != null) energiaTotal = ultimaEnergiaTotal!;
        } else {
          // Si es primera carga y falla
          energia = 'No disponible';
          potencia = 'No disponible';
          energiaEsteMes = 'No disponible';
          energiaTotal = 'No disponible';
        }
        isLoading = false;
        hayConexion = false;
      });
      
      // Mensaje de error más amigable para el usuario
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
              // Panel de resumen principal
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  gradient: hayConexion 
                    ? const LinearGradient(
                      colors: [Color(0xFF0A2E73), Color(0xFF083A5C)], // CAMBIADO: usando el color especificado
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
                      color: hayConexion ? Color(0xFF0A2E73).withOpacity(0.3) : Colors.grey.withOpacity(0.3), // CAMBIADO: sombra con el nuevo color
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween, // MANTENER spaceBetween
                        children: [
                          const Text(
                            'Potencia Actual', // SOLO CAMBIAR EL TEXTO
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          // MANTENER TODO EL INDICADOR DE ESTADO
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
                      
                      // Reemplazado por el medidor analógico
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
              ),
              
              // Tarjetas de datos detallados
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
                        _buildDetailRow('Energía Total', energiaTotal, Icons.public, Colors.teal),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Panel para gráficas
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

  String _formatFecha(DateTime fecha) {
    // Determinar si es AM o PM
    final bool isAM = fecha.hour < 12;
    
    // Convertir la hora de 24h a 12h
    final int hour12 = fecha.hour > 12 ? fecha.hour - 12 : (fecha.hour == 0 ? 12 : fecha.hour);
    
    // Formatear la hora con AM/PM
    return '${hour12}:${fecha.minute.toString().padLeft(2, '0')}:${fecha.second.toString().padLeft(2, '0')} ${isAM ? 'AM' : 'PM'}';
  }
}