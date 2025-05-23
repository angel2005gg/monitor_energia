import 'dart:math';
import 'package:flutter/material.dart';

class MedidorAnalogico extends StatelessWidget {
  final double valor;
  final double capacidadMaxima;
  final String unidad;

  const MedidorAnalogico({
    Key? key,
    required this.valor,
    required this.capacidadMaxima,
    required this.unidad,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double porcentaje = (valor / capacidadMaxima) * 100;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 220,
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Fondo principal con anillo exterior sutil
              Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(
                    color: Colors.grey.shade200,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 12.0,
                      spreadRadius: 1.0,
                    )
                  ],
                ),
              ),
              
              // Anillo interior decorativo
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.grey.shade100,
                    width: 1,
                  ),
                ),
              ),
              
              // Marcas de minutos (líneas finas cada grado)
              CustomPaint(
                size: const Size(190, 190),
                painter: MarcasFinasPainter(),
              ),
              
              // Marcas principales más visibles
              CustomPaint(
                size: const Size(190, 190),
                painter: MarcasPrincipalesPainter(),
              ),
              
              // Arco de fondo (track)
              CustomPaint(
                size: const Size(180, 180),
                painter: MedidorPainter(
                  porcentaje: 100,
                  colorArco: Colors.grey.shade200,
                  grosorArco: 4,
                  esBase: true,
                ),
              ),
              
              // Arco de progreso con degradado
              CustomPaint(
                size: const Size(180, 180),
                painter: MedidorPainter(
                  porcentaje: porcentaje,
                  colorArco: _getColorForPorcentaje(porcentaje),
                  grosorArco: 6,
                  esBase: false,
                ),
              ),
              
              // Círculo central pequeño
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(
                    color: Colors.grey.shade300,
                    width: 1,
                  ),
                ),
              ),
              
              // Valor principal
              Positioned(
                bottom: 10,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      valor.toStringAsFixed(2),
                      style: TextStyle(
                        color: _getColorForPorcentaje(porcentaje),
                        fontSize: 28,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      unidad,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    SizedBox(height: 4),
                    Container(
                      height: 1,
                      width: 60,
                      color: Colors.grey.shade300,
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Cap. $capacidadMaxima kWp",
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 10,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Color _getColorForPorcentaje(double porcentaje) {
    if (porcentaje < 30) {
      return Color(0xFF4CAF50); // Verde más profesional
    } else if (porcentaje < 70) {
      return Color(0xFFFF9800); // Naranja más profesional
    } else {
      return Color(0xFFF44336); // Rojo más profesional
    }
  }
}

class MarcasFinasPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final centro = Offset(size.width / 2, size.height / 2);
    final radio = size.width / 2;
    
    // Líneas muy finas cada 2.4 grados (100 líneas en total para el arco de 240°)
    for (int i = 0; i <= 100; i++) {
      double porcentaje = i * 1.0;
      double radianes = (porcentaje / 100 * 240 - 210) * pi / 180;
      
      // Solo líneas muy sutiles cada varios grados
      if (i % 5 == 0) {
        final paintMarca = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8  // Aumentado de 0.5 a 0.8
          ..color = Colors.grey.shade500; // Cambiado de shade300 a shade500 (más oscuro)
        
        final puntoExterior = Offset(
          centro.dx + (radio - 8) * cos(radianes),
          centro.dy + (radio - 8) * sin(radianes),
        );
        
        final puntoInterior = Offset(
          centro.dx + (radio - 12) * cos(radianes),
          centro.dy + (radio - 12) * sin(radianes),
        );
        
        canvas.drawLine(puntoInterior, puntoExterior, paintMarca);
      }
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class MarcasPrincipalesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final centro = Offset(size.width / 2, size.height / 2);
    final radio = size.width / 2;
    
    // Marcas principales cada 25%
    for (int i = 0; i <= 4; i++) {
      double porcentaje = i * 25.0;
      double radianes = (porcentaje / 100 * 240 - 210) * pi / 180;
      
      final paintMarca = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = Colors.grey.shade400;
      
      final puntoExterior = Offset(
        centro.dx + (radio - 5) * cos(radianes),
        centro.dy + (radio - 5) * sin(radianes),
      );
      
      final puntoInterior = Offset(
        centro.dx + (radio - 18) * cos(radianes),
        centro.dy + (radio - 18) * sin(radianes),
      );
      
      canvas.drawLine(puntoInterior, puntoExterior, paintMarca);
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class MedidorPainter extends CustomPainter {
  final double porcentaje;
  final Color colorArco;
  final double grosorArco;
  final bool esBase;
  
  MedidorPainter({
    required this.porcentaje,
    required this.colorArco,
    this.grosorArco = 6.0,
    required this.esBase,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final centro = Offset(size.width / 2, size.height / 2);
    final radio = size.width / 2;
    
    final anguloInicio = -210 * pi / 180;
    final anguloBarrido = (porcentaje * 240 / 100) * pi / 180;
    
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = grosorArco
      ..color = colorArco
      ..strokeCap = StrokeCap.butt;
    
    canvas.drawArc(
      Rect.fromCircle(center: centro, radius: radio - 15), 
      anguloInicio,
      anguloBarrido,
      false,
      paint,
    );
    
    // Aguja refinada
    if (!esBase) {
      final anguloPuntero = anguloInicio + anguloBarrido;
      
      // Aguja principal
      final paintAguja = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = colorArco;
        
      final puntoExterior = Offset(
        centro.dx + (radio - 20) * cos(anguloPuntero),
        centro.dy + (radio - 20) * sin(anguloPuntero),
      );
      
      final puntoInterior = Offset(
        centro.dx + 12 * cos(anguloPuntero),
        centro.dy + 12 * sin(anguloPuntero),
      );
      
      canvas.drawLine(puntoInterior, puntoExterior, paintAguja);
      
      // Punta de la aguja (círculo pequeño)
      final paintPunta = Paint()
        ..style = PaintingStyle.fill
        ..color = colorArco;
        
      canvas.drawCircle(puntoExterior, 3, paintPunta);
    }
  }
  
  @override
  bool shouldRepaint(MedidorPainter oldDelegate) {
    return oldDelegate.porcentaje != porcentaje || 
           oldDelegate.colorArco != colorArco ||
           oldDelegate.grosorArco != grosorArco;
  }
}