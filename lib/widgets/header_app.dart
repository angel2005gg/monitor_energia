import 'package:flutter/material.dart';

class HeaderApp extends StatelessWidget implements PreferredSizeWidget {
  const HeaderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 4,
      centerTitle: true,
      backgroundColor: const Color(0xFF1E88E5),
      title: Image.asset(
        'assets/images/kamati_logo.png', // Quitar la barra inicial '/'
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
