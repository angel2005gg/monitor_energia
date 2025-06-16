import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/utilidades.dart';
import 'dart:async';

class DatosDC extends StatefulWidget {
  const DatosDC({Key? key}) : super(key: key);

  @override
  State<DatosDC> createState() => _DatosDCState();
}

class _DatosDCState extends State<DatosDC> {
  // Variables para datos DC
  String voltajeString1 = '';
  String corrienteString1 = '';
  String voltajeString2 = '';
  String corrienteString2 = '';
  
  bool isLoading = true;
  bool hayConexion = true;
  DateTime? ultimaActualizacion;
  Timer? _timer;
  
  // Variables para últimos datos válidos
  String? ultimoVoltajeString1;
  String? ultimoCorrienteString1;
  String? ultimoVoltajeString2;
  String? ultimoCorrienteString2;

  @override
  void initState() {
    super.initState();
    cargarDatosDC();
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
        cargarDatosDC();
      }
    });
  }

  Future<void> cargarDatosDC() async {
    try {
      final datos = await ApiService.obtenerDatos();
      final ahora = horaActualColombia();
      
      if (!mounted) return;
      
      // Procesar datos DC
      final stringsDC = datos['stringsDC'] ?? {};
      
      // String 1
      final string1 = stringsDC['string1'] ?? {};
      ultimoVoltajeString1 = _procesarValorDC(string1['voltaje'], 'V');
      ultimoCorrienteString1 = _procesarValorDC(string1['corriente'], 'A');
      
      // String 2
      final string2 = stringsDC['string2'] ?? {};
      ultimoVoltajeString2 = _procesarValorDC(string2['voltaje'], 'V');
      ultimoCorrienteString2 = _procesarValorDC(string2['corriente'], 'A');
      
      setState(() {
        voltajeString1 = ultimoVoltajeString1!;
        corrienteString1 = ultimoCorrienteString1!;
        voltajeString2 = ultimoVoltajeString2!;
        corrienteString2 = ultimoCorrienteString2!;
        
        ultimaActualizacion = ahora;
        isLoading = false;
        hayConexion = true;
      });
      
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        // Usar últimos datos válidos si existen
        if (ultimoVoltajeString1 != null) {
          voltajeString1 = ultimoVoltajeString1!;
          corrienteString1 = ultimoCorrienteString1!;
          voltajeString2 = ultimoVoltajeString2!;
          corrienteString2 = ultimoCorrienteString2!;
        } else {
          // Valores por defecto
          voltajeString1 = '0.0 V';
          corrienteString1 = '0.0 A';
          voltajeString2 = '0.0 V';
          corrienteString2 = '0.0 A';
        }
        
        isLoading = false;
        hayConexion = false;
      });
    }
  }

  String _procesarValorDC(dynamic valor, String unidad) {
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
                  'Voltajes y Corrientes DC',
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
              // Contenido principal - MÁS COMPACTO
              Expanded(
                child: Column(
                  children: [
                    // Primera fila: String 1 Voltaje y String 1 Corriente
                    Row(
                      children: [
                        Expanded(
                          child: _buildDataItemDC(
                            'Entrada 1 Voltaje', // ← CAMBIO: String 1 → Entrada 1
                            voltajeString1,
                            Icons.electrical_services,
                            Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDataItemDC(
                            'Entrada 1 Corriente', // ← CAMBIO: String 1 → Entrada 1
                            corrienteString1,
                            Icons.flash_on,
                            Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Segunda fila: String 2 Voltaje y String 2 Corriente
                    Row(
                      children: [
                        Expanded(
                          child: _buildDataItemDC(
                            'Entrada 2 Voltaje', // ← CAMBIO: String 2 → Entrada 2
                            voltajeString2,
                            Icons.electrical_services,
                            Colors.cyan,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDataItemDC(
                            'Entrada 2 Corriente', // ← CAMBIO: String 2 → Entrada 2
                            corrienteString2,
                            Icons.flash_on,
                            Colors.amber,
                          ),
                        ),
                      ],
                    ),
                    
                    const Spacer(),
                    
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
          ],
        ),
      ),
    );
  }

  Widget _buildDataItemDC(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: color.withOpacity(0.13),
            shape: BoxShape.circle,
          ),
          padding: const EdgeInsets.all(10), // ← REDUCIDO: era 12
          child: Icon(icon, color: color, size: 28), // ← REDUCIDO: era 32
        ),
        const SizedBox(height: 4), // ← REDUCIDO: era 6
        Text(
          title,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12, // ← REDUCIDO: era 13
            fontWeight: FontWeight.w400,
            letterSpacing: 0.2,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 3), // ← REDUCIDO: era 4
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16, // ← REDUCIDO: era 18
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 3), // ← REDUCIDO: era 4
        Container(
          height: 2,
          width: 28, // ← REDUCIDO: era 32
          decoration: BoxDecoration(
            color: color.withOpacity(0.18),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  String _formatFecha(DateTime fecha) {
    return formatearHoraColombia(fecha);
  }
}