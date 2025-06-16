import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/utilidades.dart';
import 'dart:async';

class DatosAC extends StatefulWidget {
  const DatosAC({Key? key}) : super(key: key);

  @override
  State<DatosAC> createState() => _DatosACState();
}

class _DatosACState extends State<DatosAC> {
  // Variables para datos AC
  String voltajeFaseA = '';
  String voltajeFaseB = '';
  String voltajeFaseC = '';
  String corrienteFaseA = '';
  String corrienteFaseB = '';
  String corrienteFaseC = '';
  
  bool isLoading = true;
  bool hayConexion = true;
  DateTime? ultimaActualizacion;
  Timer? _timer;
  
  // Variables para últimos datos válidos
  String? ultimoVoltajeFaseA;
  String? ultimoVoltajeFaseB;
  String? ultimoVoltajeFaseC;
  String? ultimoCorrienteFaseA;
  String? ultimoCorrienteFaseB;
  String? ultimoCorrienteFaseC;

  @override
  void initState() {
    super.initState();
    cargarDatosAC();
    _iniciarTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _iniciarTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(Duration(minutes: 2), (Timer t) {
      if (mounted) {
        cargarDatosAC();
      }
    });
  }

  Future<void> cargarDatosAC() async {
    try {
      final datos = await ApiService.obtenerDatos();
      final ahora = horaActualColombia();
      
      if (!mounted) return;
      
      // Procesar datos AC
      final datosAC = datos['datosAC'] ?? {};
      
      // Voltajes
      final voltajes = datosAC['voltajes'] ?? {};
      ultimoVoltajeFaseA = _procesarValorAC(voltajes['faseA'], 'V');
      ultimoVoltajeFaseB = _procesarValorAC(voltajes['faseB'], 'V');
      ultimoVoltajeFaseC = _procesarValorAC(voltajes['faseC'], 'V');
      
      // Corrientes
      final corrientes = datosAC['corrientes'] ?? {};
      ultimoCorrienteFaseA = _procesarValorAC(corrientes['faseA'], 'A');
      ultimoCorrienteFaseB = _procesarValorAC(corrientes['faseB'], 'A');
      ultimoCorrienteFaseC = _procesarValorAC(corrientes['faseC'], 'A');
      
      setState(() {
        voltajeFaseA = ultimoVoltajeFaseA!;
        voltajeFaseB = ultimoVoltajeFaseB!;
        voltajeFaseC = ultimoVoltajeFaseC!;
        corrienteFaseA = ultimoCorrienteFaseA!;
        corrienteFaseB = ultimoCorrienteFaseB!;
        corrienteFaseC = ultimoCorrienteFaseC!;
        
        ultimaActualizacion = ahora;
        isLoading = false;
        hayConexion = true;
      });
      
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        // Usar últimos datos válidos si existen
        if (ultimoVoltajeFaseA != null) {
          voltajeFaseA = ultimoVoltajeFaseA!;
          voltajeFaseB = ultimoVoltajeFaseB!;
          voltajeFaseC = ultimoVoltajeFaseC!;
          corrienteFaseA = ultimoCorrienteFaseA!;
          corrienteFaseB = ultimoCorrienteFaseB!;
          corrienteFaseC = ultimoCorrienteFaseC!;
        } else {
          // Valores por defecto
          voltajeFaseA = '0.0 V';
          voltajeFaseB = '0.0 V';
          voltajeFaseC = '0.0 V';
          corrienteFaseA = '0.0 A';
          corrienteFaseB = '0.0 A';
          corrienteFaseC = '0.0 A';
        }
        
        isLoading = false;
        hayConexion = false;
      });
    }
  }

  String _procesarValorAC(dynamic valor, String unidad) {
    if (valor == null || 
        valor.toString().toLowerCase().contains('no disponible') ||
        valor.toString().toLowerCase().contains('no available') ||
        valor.toString().trim().isEmpty) {
      return '0.0 $unidad';
    }
    
    String valorStr = valor.toString();
    // Si ya tiene la unidad, devolverlo tal como está
    if (valorStr.contains(unidad)) {
      return valorStr;
    }
    
    // Si no tiene unidad, agregarla
    return '$valorStr $unidad';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título y estado de conexión
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Corrientes y Voltajes AC',
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
            
            if (isLoading)
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            else
              // Contenido principal - 2 columnas: Voltajes y Corrientes
              Expanded(
                child: Row(
                  children: [
                    // ← COLUMNA 1: VOLTAJES
                    Expanded(
                      child: Column(
                        children: [
                          // Título de columna
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.electrical_services, color: Colors.blue, size: 20),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Voltajes AC',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Fase A - Voltaje
                          _buildItemAC(
                            'Fase A',
                            voltajeFaseA,
                            Icons.electric_bolt,
                            Colors.blue,
                          ),
                          
                          const SizedBox(height: 12),
                          
                          // Fase B - Voltaje
                          _buildItemAC(
                            'Fase B',
                            voltajeFaseB,
                            Icons.electric_bolt,
                            Colors.lightBlue,
                          ),
                          
                          const SizedBox(height: 12),
                          
                          // Fase C - Voltaje
                          _buildItemAC(
                            'Fase C',
                            voltajeFaseC,
                            Icons.electric_bolt,
                            Colors.cyan,
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // ← COLUMNA 2: CORRIENTES
                    Expanded(
                      child: Column(
                        children: [
                          // Título de columna
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.flash_on, color: Colors.orange, size: 20),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Corrientes AC',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Fase A - Corriente
                          _buildItemAC(
                            'Fase A',
                            corrienteFaseA,
                            Icons.flash_on,
                            Colors.orange,
                          ),
                          
                          const SizedBox(height: 12),
                          
                          // Fase B - Corriente
                          _buildItemAC(
                            'Fase B',
                            corrienteFaseB,
                            Icons.flash_on,
                            Colors.amber,
                          ),
                          
                          const SizedBox(height: 12),
                          
                          // Fase C - Corriente
                          _buildItemAC(
                            'Fase C',
                            corrienteFaseC,
                            Icons.flash_on,
                            Colors.deepOrange,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: 16),
            
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

  Widget _buildItemAC(String fase, String valor, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 6),
          Text(
            fase,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            valor,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 2,
            width: 30,
            decoration: BoxDecoration(
              color: color.withOpacity(0.5),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ],
      ),
    );
  }

  String _formatFecha(DateTime fecha) {
    return formatearHoraColombia(fecha);
  }
}