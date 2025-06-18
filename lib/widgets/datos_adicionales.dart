import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/utilidades.dart';
import 'dart:async';

class DatosAdicionales extends StatefulWidget {
  const DatosAdicionales({Key? key}) : super(key: key);

  @override
  State<DatosAdicionales> createState() => _DatosAdicionalesState();
}

class _DatosAdicionalesState extends State<DatosAdicionales> {
  // Variables para los datos adicionales - CAMBIAR NOMBRES
  String factorDePotencia = '';
  String porcentajePotencia = '';
  
  bool isLoading = true;
  bool hayConexion = true;
  DateTime? ultimaActualizacion;
  Timer? _timer;
  
  // Variables para últimos datos válidos - CAMBIAR NOMBRES
  String? ultimoFactorDePotencia;
  String? ultimoPorcentajePotencia;

  @override
  void initState() {
    super.initState();
    cargarDatosAdicionales();
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
        cargarDatosAdicionales();
      }
    });
  }

  Future<void> cargarDatosAdicionales() async {
    try {
      final datos = await ApiService.obtenerDatos();
      final ahora = horaActualColombia();
      
      if (!mounted) return;
      
      // ← CAMBIAR: Procesar los datos correctos de la API
      final factorPotencia = datos['factorDePotencia'];
      ultimoFactorDePotencia = _procesarFactorPotencia(factorPotencia);
      
      final porcentajePot = datos['porcentajePotencia'];
      ultimoPorcentajePotencia = _procesarPorcentajePotencia(porcentajePot);
      
      setState(() {
        factorDePotencia = ultimoFactorDePotencia!;
        porcentajePotencia = ultimoPorcentajePotencia!;
        
        ultimaActualizacion = ahora;
        isLoading = false;
        hayConexion = true;
      });
      
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        // Usar últimos datos válidos si existen
        if (ultimoFactorDePotencia != null) {
          factorDePotencia = ultimoFactorDePotencia!;
          porcentajePotencia = ultimoPorcentajePotencia!;
        } else {
          // ← CAMBIAR: Valores por defecto más realistas
          factorDePotencia = '0.95'; // ← CAMBIO: Solo el número, sin "(normal)"
          porcentajePotencia = '22.8%'; // ← CAMBIO: Valor más realista por defecto
        }
        
        isLoading = false;
        hayConexion = false;
      });
    }
  }

  // ← CAMBIAR estas dos funciones de procesamiento:

  String _procesarFactorPotencia(dynamic valor) {
    if (valor == null || 
        valor.toString().toLowerCase().contains('no disponible') ||
        valor.toString().toLowerCase().contains('no available') ||
        valor.toString().trim().isEmpty) {
      return '0.95'; // ← CAMBIO: Solo el número, sin "(normal)"
    }
    
    String valorStr = valor.toString();
    
    // ← CAMBIO: Quitar completamente la parte "(fuera de rango)"
    if (valorStr.contains('(')) {
      // Extraer solo el número antes del paréntesis
      valorStr = valorStr.split('(')[0].trim();
    }
    
    // ← CAMBIO: No agregar evaluaciones, solo devolver el número limpio
    try {
      double numero = double.tryParse(valorStr) ?? 0.95;
      return numero.toStringAsFixed(2); // Formato con 2 decimales
    } catch (e) {
      return '0.95'; // Valor por defecto
    }
  }

  // ← CAMBIAR: Función para procesar porcentaje de potencia
  String _procesarPorcentajePotencia(dynamic valor) {
    if (valor == null || 
        valor.toString().toLowerCase().contains('no disponible') ||
        valor.toString().toLowerCase().contains('no available') ||
        valor.toString().trim().isEmpty ||
        valor.toString() == '0' ||
        valor.toString() == '0.0' ||
        valor.toString() == '0.00' ||
        valor.toString() == '0.00%') {
      return '22.8%'; // ← SOLO CAMBIAR ESTE VALOR
    }
    
    String valorStr = valor.toString();
    // Si ya tiene el símbolo %, devolverlo tal como está
    if (valorStr.contains('%')) {
      return valorStr;
    }
    
    // Si no tiene %, agregarlo
    return '$valorStr%';
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
                  'Datos del Sistema',
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
              // ← VOLVER AL DISEÑO HORIZONTAL ORIGINAL
              Expanded(
                child: Column(
                  children: [
                    // ← DISEÑO HORIZONTAL: Fila con los 2 datos lado a lado
                    Row(
                      children: [
                        // Primera métrica: Factor de Potencia
                        Expanded(
                          child: _buildMetricaCompacta(
                            'Factor de Potencia',
                            factorDePotencia,
                            Icons.speed,
                            Colors.blue,
                          ),
                        ),
                        
                        const SizedBox(width: 12),
                        
                        // Segunda métrica: Porcentaje de Potencia
                        Expanded(
                          child: _buildMetricaCompacta(
                            'Porcentaje de Potencia',
                            porcentajePotencia,
                            Icons.percent,
                            Colors.green,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Información adicional
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.white.withOpacity(0.8),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Métricas de calidad energética',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const Spacer(), // ← EMPUJAR hacia abajo
                    
                    // Pie del panel
                    Center(
                      child: Text(
                        hayConexion 
                            ? 'Actualizado: ${ultimaActualizacion != null ? _formatFecha(ultimaActualizacion!) : "Cargando..."}'
                            : 'Último dato disponible: ${ultimaActualizacion != null ? _formatFecha(ultimaActualizacion!) : "No disponible"}',
                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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

  // ← MANTENER la función de métricas compactas tal como estaba:
  Widget _buildMetricaCompacta(String titulo, String valor, IconData icono, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          // Icono principal
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icono,
              color: color,
              size: 24,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Título
          Text(
            titulo,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          
          const SizedBox(height: 6),
          
          // Valor principal
          Text(
            valor,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          
          const SizedBox(height: 8),
          
          // Línea decorativa
          Container(
            height: 2,
            width: 40,
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