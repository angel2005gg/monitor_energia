import 'package:flutter/material.dart';

// Función para obtener la hora actual en Colombia (UTC-5)
DateTime horaActualColombia() {
  return DateTime.now().toUtc().subtract(const Duration(hours: 5));
}

// Formatear la fecha para mostrarla
String formatearHoraColombia(DateTime fecha) {
  final bool isAM = fecha.hour < 12;
  final int hour12 = fecha.hour > 12 ? fecha.hour - 12 : (fecha.hour == 0 ? 12 : fecha.hour);
  return '${hour12}:${fecha.minute.toString().padLeft(2, '0')}:${fecha.second.toString().padLeft(2, '0')} ${isAM ? 'AM' : 'PM'}';
}