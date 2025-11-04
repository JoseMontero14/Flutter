import 'package:flutter/material.dart';
import 'package:alerta_com/screens/publicar_alerta_screen.dart';
import 'package:alerta_com/screens/profile_screen.dart';
import 'package:alerta_com/screens/dashboard_general_screen.dart'; 

import '../theme/app_colors.dart' as theme;

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
      const DashboardGeneralScreen(), 
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
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.grey[500],
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
              icon: Icon(Icons.analytics_outlined),
              activeIcon: Icon(Icons.analytics),
              label: 'Dashboard',
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
