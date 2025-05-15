import 'package:flutter/material.dart';

class GraficasPanel extends StatelessWidget {
  const GraficasPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        height: 200,
        padding: const EdgeInsets.all(16),
        width: double.infinity,
        child: const Center(
          child: Text(
            'Aquí irá la gráfica de potencia o energía',
            style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
          ),
        ),
      ),
    );
  }
}
