import 'package:flutter/material.dart';

class HeaderApp extends StatelessWidget implements PreferredSizeWidget {
  const HeaderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 4,
      centerTitle: true,
      backgroundColor: const Color(0xFF0A2E73), // Azul corporativo más sobrio
      title: Image.asset(
        'assets/images/kamati_logo.png',
        height: 40,
        fit: BoxFit.contain,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(10),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
