import 'package:flutter/material.dart';
import '../utils/utilidades.dart';

class FiltroFechas extends StatefulWidget {
  final String tipoGrafica; // 'Día', 'Mes', 'Año'
  final Function(DateTime) onFechaSeleccionada;
  
  const FiltroFechas({
    Key? key,
    required this.tipoGrafica,
    required this.onFechaSeleccionada,
  }) : super(key: key);

  @override
  State<FiltroFechas> createState() => _FiltroFechasState();
}

class _FiltroFechasState extends State<FiltroFechas> {
  late DateTime _fechaSeleccionada;
  
  @override
  void initState() {
    super.initState();
    // Inicializar con la fecha actual de Colombia
    _fechaSeleccionada = horaActualColombia();
  }

  @override
  void didUpdateWidget(FiltroFechas oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si cambió el tipo de gráfica, resetear a fecha actual
    if (oldWidget.tipoGrafica != widget.tipoGrafica) {
      _fechaSeleccionada = horaActualColombia();
      widget.onFechaSeleccionada(_fechaSeleccionada);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // ← REDUCIR padding
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Flecha izquierda - MINIMALISTA
          _buildFlechaNavegacion(true),
          
          const SizedBox(width: 12), // ← REDUCIR espacio
          
          // Dropdowns contextuales - SIN FONDO
          ..._buildDropdownsContextuales(),
          
          const SizedBox(width: 12), // ← REDUCIR espacio
          
          // Flecha derecha - MINIMALISTA
          _buildFlechaNavegacion(false),
        ],
      ),
    );
  }

  Widget _buildFlechaNavegacion(bool esIzquierda) {
    return GestureDetector(
      onTap: () => _navegarFecha(esIzquierda),
      child: Icon(
        esIzquierda ? Icons.chevron_left : Icons.chevron_right,
        color: Colors.grey, // ← CAMBIAR color a gris claro
        size: 24,
      ),
    );
  }

  List<Widget> _buildDropdownsContextuales() {
    switch (widget.tipoGrafica) {
      case 'Día':
        return [
          _buildDropdownDia(),
          const SizedBox(width: 6), // ← REDUCIR espacio
          _buildDropdownMes(),
          const SizedBox(width: 6), // ← REDUCIR espacio
          _buildDropdownAnio(),
        ];
      case 'Mes':
        return [
          _buildDropdownMes(),
          const SizedBox(width: 8),
          _buildDropdownAnio(),
        ];
      case 'Año':
        return [
          _buildDropdownAnio(),
        ];
      default:
        return [_buildDropdownDia()];
    }
  }

  Widget _buildDropdownDia() {
    final diasDelMes = _getDiasDelMes(_fechaSeleccionada.year, _fechaSeleccionada.month);
    final fechaActual = horaActualColombia();
    
    // NUEVA VALIDACIÓN para evitar listas vacías
    List<DropdownMenuItem<int>> itemsValidos = [];
    
    for (int dia in diasDelMes) {
      // Solo mostrar días hasta el día actual si es el mes actual
      final esMesActual = _fechaSeleccionada.year == fechaActual.year && 
                         _fechaSeleccionada.month == fechaActual.month;
      final esValido = !esMesActual || dia <= fechaActual.day;
      
      if (esValido) {
        itemsValidos.add(
          DropdownMenuItem<int>(
            value: dia,
            child: Text(dia.toString().padLeft(2, '0')),
          ),
        );
      }
    }
    
    // VALIDAR que tengamos items válidos y que el valor seleccionado esté incluido
    if (itemsValidos.isEmpty) {
      return const Text('--', style: TextStyle(color: Colors.grey));
    }
    
    // VALIDAR que el día seleccionado esté en la lista válida
    bool diaValido = itemsValidos.any((item) => item.value == _fechaSeleccionada.day);
    if (!diaValido && itemsValidos.isNotEmpty) {
      // Si el día actual no es válido, usar el primer día válido
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _fechaSeleccionada = DateTime(
            _fechaSeleccionada.year,
            _fechaSeleccionada.month,
            itemsValidos.first.value!,
          );
        });
        widget.onFechaSeleccionada(_fechaSeleccionada);
      });
    }
    
    return DropdownButton<int>(
      value: diaValido ? _fechaSeleccionada.day : itemsValidos.first.value,
      underline: const SizedBox(),
      style: const TextStyle(
        color: Colors.grey, // ← CAMBIAR color a gris claro
        fontSize: 15,
        fontWeight: FontWeight.w500, // ← REDUCIR peso de fuente
      ),
      icon: const Icon(
        Icons.keyboard_arrow_down,
        color: Colors.grey, // ← CAMBIAR color a gris claro
        size: 18,
      ),
      items: itemsValidos,
      onChanged: (nuevoDia) {
        if (nuevoDia != null) {
          setState(() {
            _fechaSeleccionada = DateTime(
              _fechaSeleccionada.year,
              _fechaSeleccionada.month,
              nuevoDia,
            );
          });
          widget.onFechaSeleccionada(_fechaSeleccionada);
        }
      },
    );
  }

  Widget _buildDropdownMes() {
    final meses = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
    ];
    final fechaActual = horaActualColombia();
    
    // NUEVA VALIDACIÓN para evitar listas vacías
    List<DropdownMenuItem<int>> itemsValidos = [];
    
    for (int i = 0; i < meses.length; i++) {
      final index = i + 1; // Los meses van de 1 a 12
      final nombreMes = meses[i];
      
      // Solo mostrar meses hasta el mes actual si es el año actual
      final esAnioActual = _fechaSeleccionada.year == fechaActual.year;
      final esValido = !esAnioActual || index <= fechaActual.month;
      
      if (esValido) {
        itemsValidos.add(
          DropdownMenuItem<int>(
            value: index,
            child: Text(nombreMes),
          ),
        );
      }
    }
    
    // VALIDAR que tengamos items válidos
    if (itemsValidos.isEmpty) {
      return const Text('--', style: TextStyle(color: Colors.grey));
    }
    
    // VALIDAR que el mes seleccionado esté en la lista válida
    bool mesValido = itemsValidos.any((item) => item.value == _fechaSeleccionada.month);
    if (!mesValido && itemsValidos.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _fechaSeleccionada = DateTime(
            _fechaSeleccionada.year,
            itemsValidos.first.value!,
            1,
          );
        });
        widget.onFechaSeleccionada(_fechaSeleccionada);
      });
    }
    
    return DropdownButton<int>(
      value: mesValido ? _fechaSeleccionada.month : itemsValidos.first.value,
      underline: const SizedBox(),
      style: const TextStyle(
        color: Colors.grey, // ← CAMBIAR color a gris claro
        fontSize: 15,
        fontWeight: FontWeight.w500, // ← REDUCIR peso de fuente
      ),
      icon: const Icon(
        Icons.keyboard_arrow_down,
        color: Colors.grey, // ← CAMBIAR color a gris claro
        size: 18,
      ),
      items: itemsValidos,
      onChanged: (nuevoMes) {
        if (nuevoMes != null) {
          // Ajustar el día si es necesario
          final diasDelNuevoMes = _getDiasDelMes(_fechaSeleccionada.year, nuevoMes);
          final nuevoDia = _fechaSeleccionada.day > diasDelNuevoMes.length 
            ? diasDelNuevoMes.length 
            : _fechaSeleccionada.day;
            
          setState(() {
            _fechaSeleccionada = DateTime(
              _fechaSeleccionada.year,
              nuevoMes,
              nuevoDia,
            );
          });
          widget.onFechaSeleccionada(_fechaSeleccionada);
        }
      },
    );
  }

  Widget _buildDropdownAnio() {
    final anioActual = horaActualColombia().year;
    // Mostrar desde 2020 hasta el año actual
    final anios = List.generate(anioActual - 2019, (index) => 2020 + index);
    
    // VALIDAR que el año actual esté en la lista
    if (!anios.contains(_fechaSeleccionada.year)) {
      // Si no está, usar el año actual
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _fechaSeleccionada = DateTime(anioActual, 1, 1);
        });
        widget.onFechaSeleccionada(_fechaSeleccionada);
      });
    }
    
    return DropdownButton<int>(
      value: anios.contains(_fechaSeleccionada.year) ? _fechaSeleccionada.year : anioActual,
      underline: const SizedBox(),
      style: const TextStyle(
        color: Colors.grey, // ← CAMBIAR color a gris claro
        fontSize: 15,
        fontWeight: FontWeight.w500, // ← REDUCIR peso de fuente
      ),
      icon: const Icon(
        Icons.keyboard_arrow_down,
        color: Colors.grey, // ← CAMBIAR color a gris claro
        size: 18,
      ),
      items: anios.map((anio) {
        return DropdownMenuItem<int>(
          value: anio,
          child: Text(anio.toString()),
        );
      }).toList(),
      onChanged: (nuevoAnio) {
        if (nuevoAnio != null) {
          // Ajustar mes y día si es necesario
          final fechaActual = horaActualColombia();
          int nuevoMes = _fechaSeleccionada.month;
          int nuevoDia = _fechaSeleccionada.day;
          
          // Si es el año actual, no puede ser mayor al mes actual
          if (nuevoAnio == fechaActual.year && nuevoMes > fechaActual.month) {
            nuevoMes = fechaActual.month;
          }
          
          // Ajustar día según el mes
          final diasDelMes = _getDiasDelMes(nuevoAnio, nuevoMes);
          if (nuevoDia > diasDelMes.length) {
            nuevoDia = diasDelMes.length;
          }
          
          // Si es el año y mes actual, no puede ser mayor al día actual
          if (nuevoAnio == fechaActual.year && nuevoMes == fechaActual.month && nuevoDia > fechaActual.day) {
            nuevoDia = fechaActual.day;
          }
          
          setState(() {
            _fechaSeleccionada = DateTime(nuevoAnio, nuevoMes, nuevoDia);
          });
          widget.onFechaSeleccionada(_fechaSeleccionada);
        }
      },
    );
  }

  void _navegarFecha(bool retroceder) {
    DateTime nuevaFecha;
    
    switch (widget.tipoGrafica) {
      case 'Día':
        nuevaFecha = retroceder 
          ? _fechaSeleccionada.subtract(const Duration(days: 1))
          : _fechaSeleccionada.add(const Duration(days: 1));
        break;
      case 'Mes':
        nuevaFecha = retroceder
          ? DateTime(_fechaSeleccionada.year, _fechaSeleccionada.month - 1, 1)
          : DateTime(_fechaSeleccionada.year, _fechaSeleccionada.month + 1, 1);
        break;
      case 'Año':
        nuevaFecha = DateTime(_fechaSeleccionada.year + (retroceder ? -1 : 1), 1, 1);
        break;
      default:
        return;
    }
    
    // Validar que la nueva fecha no sea futura
    final fechaActual = horaActualColombia();
    if (nuevaFecha.isAfter(fechaActual)) {
      return; // No permitir fechas futuras
    }
    
    // Validar que no sea anterior a 2020
    if (nuevaFecha.year < 2020) {
      return;
    }
    
    setState(() {
      _fechaSeleccionada = nuevaFecha;
    });
    widget.onFechaSeleccionada(_fechaSeleccionada);
  }

  List<int> _getDiasDelMes(int anio, int mes) {
    final ultimoDia = DateTime(anio, mes + 1, 0).day;
    return List.generate(ultimoDia, (index) => index + 1);
  }
}