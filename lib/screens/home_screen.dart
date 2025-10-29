import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_colors.dart' as theme;
import 'package:alerta_com/screens/publicar_alerta_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  final String dni;
  const HomeScreen({Key? key, required this.dni}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      PublicarAlertaScreen(dni: widget.dni),
      // Placeholder de estadísticas
      Center(
        child: Text(
          'Estadísticas próximamente',
          style: TextStyle(color: theme.AppColors.textLight, fontSize: 18),
        ),
      ),
      // Perfil unificado
      ProfileScreen(dni: widget.dni),
    ];

    return Scaffold(
      backgroundColor: theme.AppColors.backgroundDark,
      body: _pages[_currentIndex],
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          type: BottomNavigationBarType.fixed,
          backgroundColor: theme.AppColors.backgroundDark,
          selectedItemColor: Colors.white, // Color claro para el ítem activo
          unselectedItemColor: Colors.grey[500], // Ítems inactivos más suaves
          selectedIconTheme: const IconThemeData(size: 26),
          unselectedIconTheme: const IconThemeData(size: 24),
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.add_alert_outlined),
              activeIcon: Icon(Icons.add_alert),
              label: 'Publicar',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined),
              activeIcon: Icon(Icons.bar_chart),
              label: 'Estadísticas',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }
}
