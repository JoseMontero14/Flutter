import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'profile_screen.dart';
import 'login_screen.dart';
import '../theme/app_colors.dart' as theme;

class PerfilCompletoScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const PerfilCompletoScreen({Key? key, required this.userData})
      : super(key: key);

  @override
  State<PerfilCompletoScreen> createState() => _PerfilCompletoScreenState();
}

class _PerfilCompletoScreenState extends State<PerfilCompletoScreen> {
  late Map<String, dynamic> userData;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    userData = Map<String, dynamic>.from(widget.userData);
  }

  Future<void> _refreshUserData() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(userData['dni'])
          .get();
      if (snapshot.exists) {
        setState(() {
          userData = snapshot.data()!;
        });
      }
    } catch (e) {
      debugPrint('Error al refrescar datos: $e');
    }
  }

  Future<void> _cerrarSesion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Cerrar Sesión",
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("¿Estás seguro de que quieres cerrar sesión?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancelar")),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Sí, salir")),
        ],
      ),
    );

    if (confirmar == true) {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text("Mi Perfil",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Stack(
        children: [
          // 🌈 Fondo degradado amarillo-azul (estilo login)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFACC15), Color(0xFF1E3A8A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // 🔵 Burbujas decorativas suaves
          Positioned(
              top: -60,
              left: -30,
              child: _buildBubble(180, Colors.white.withOpacity(0.08))),
          Positioned(
              bottom: -70,
              right: -40,
              child: _buildBubble(220, Colors.white.withOpacity(0.06))),
          Positioned(
              top: size.height * 0.45,
              left: -60,
              child: _buildBubble(140, Colors.white.withOpacity(0.04))),

          // 📱 Contenido principal
          SafeArea(
            child: RefreshIndicator(
              onRefresh: _refreshUserData,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // 🧑 Imagen de perfil + nombre
                    Column(
                      children: [
                        CircleAvatar(
                          radius: 55,
                          backgroundColor: Colors.white.withOpacity(0.4),
                          backgroundImage: userData['fotoUrl'] != null
                              ? NetworkImage(userData['fotoUrl'])
                              : null,
                          child: userData['fotoUrl'] == null
                              ? const Icon(Icons.person,
                                  color: Colors.white, size: 60)
                              : null,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          userData['nombreCompleto'] ?? 'Usuario sin nombre',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "DNI: ${userData['dni'] ?? ''}",
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    // 🗂 Información personal (solo 2 cards suaves)
                    _buildInfoTile(
                        Icons.phone, "Teléfono", userData['telefono'] ?? "No registrado"),
                    _buildInfoTile(
                        Icons.home, "Dirección", userData['direccion'] ?? "No registrada"),

                    const SizedBox(height: 30),

                    // ✏️ Botón editar perfil
                    _buildGradientButton(
                      text: "Editar Perfil",
                      icon: Icons.edit,
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ProfileScreen(dni: userData['dni']),
                          ),
                        );
                        await _refreshUserData();
                      },
                    ),
                    const SizedBox(height: 20),

                    // 🚪 Botón cerrar sesión (minimalista)
                    GestureDetector(
                      onTap: _cerrarSesion,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: const Text(
                          "Cerrar Sesión",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBubble(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String value) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: theme.AppColors.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(10),
            child: Icon(icon, color: theme.AppColors.primaryBlue),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              "$title: $value",
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientButton({
    required String text,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.zero,
        backgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        elevation: 8,
      ),
      child: Ink(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFACC15), Color(0xFF1E3A8A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Container(
          alignment: Alignment.center,
          height: 52,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Text(
                text,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
