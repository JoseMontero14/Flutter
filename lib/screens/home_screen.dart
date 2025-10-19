import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_colors.dart' as theme;
import 'perfil_dashboard_screen.dart';
import 'profile_screen.dart';
import 'publicar_alerta_screen.dart';
import 'estadisticas_screen.dart';

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
      const EstadisticasScreen(),
      FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('usuarios')
            .doc(widget.dni)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("No se encontró el usuario"));
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>? ?? {};

          if (userData['telefono'] == null || userData['direccion'] == null) {
            return ProfileScreen(dni: widget.dni);
          } else {
            return PerfilDashboardScreen(userData: userData);
          }
        },
      ),
    ];

    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: theme.AppColors.primaryBlue,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.add_alert),
            label: 'Publicar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Estadísticas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
