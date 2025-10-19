import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'perfil_completo_screen.dart';
import 'login_screen.dart';
import '../theme/app_colors.dart' as theme;

class PerfilDashboardScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const PerfilDashboardScreen({Key? key, required this.userData})
      : super(key: key);

  @override
  State<PerfilDashboardScreen> createState() => _PerfilDashboardScreenState();
}

class _PerfilDashboardScreenState extends State<PerfilDashboardScreen> {
  late Map<String, dynamic> userData;

  @override
  void initState() {
    super.initState();
    userData = Map<String, dynamic>.from(widget.userData);
    _actualizarContadorAlertas();
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

      await _actualizarContadorAlertas();
    } catch (e) {
      debugPrint('Error al refrescar datos: $e');
    }
  }

  Future<void> _actualizarContadorAlertas() async {
    try {
      final dniUsuario = userData['dni']?.toString();
      final snapshot = await FirebaseFirestore.instance
          .collection('alertas')
          .where('dniUsuario', isEqualTo: dniUsuario)
          .get();

      final cantidadAlertas = snapshot.docs.length;

      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(dniUsuario)
          .update({'alertas': cantidadAlertas});

      setState(() {
        userData['alertas'] = cantidadAlertas;
      });

      debugPrint("✅ Alertas actualizadas: $cantidadAlertas");
    } catch (e) {
      debugPrint('❌ Error al actualizar contador de alertas: $e');
    }
  }

  Future<void> _mostrarPopupCambiarPassword() async {
    final TextEditingController oldPassCtrl = TextEditingController();
    final TextEditingController newPassCtrl = TextEditingController();
    final TextEditingController confirmCtrl = TextEditingController();
    final auth = FirebaseAuth.instance;
    final user = auth.currentUser;

    await showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock, size: 60, color: Colors.blueAccent),
                  const SizedBox(height: 10),
                  const Text(
                    "Cambiar Contraseña",
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: oldPassCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: "Contraseña actual",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: newPassCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: "Nueva contraseña",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.vpn_key),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: confirmCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: "Confirmar nueva contraseña",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.check_circle_outline),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      if (newPassCtrl.text != confirmCtrl.text) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text("Las contraseñas no coinciden.")),
                        );
                        return;
                      }

                      try {
                        final cred = EmailAuthProvider.credential(
                            email: user!.email!, password: oldPassCtrl.text);
                        await user.reauthenticateWithCredential(cred);
                        await user.updatePassword(newPassCtrl.text);

                        await FirebaseFirestore.instance
                            .collection('usuarios')
                            .doc(userData['dni'])
                            .update({'password': newPassCtrl.text});

                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    "Contraseña actualizada correctamente.")),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Error: $e")),
                        );
                      }
                    },
                    child: const Text(
                      "Actualizar",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _cerrarSesion() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.logout_rounded, size: 55, color: Colors.redAccent),
              const SizedBox(height: 10),
              const Text(
                "¿Cerrar sesión?",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Tu sesión actual se cerrará y volverás a la pantalla de inicio de sesión.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.black54),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 25, vertical: 10),
                      backgroundColor: Colors.grey[200],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text("Cancelar",
                        style: TextStyle(color: Colors.black87)),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    onPressed: () => Navigator.pop(context, true),
                    icon: const Icon(Icons.logout, color: Colors.white),
                    label: const Text(
                      "Cerrar sesión",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );

    if (confirm == true) {
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
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1E3A8A), Color(0xFFFFA726)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Positioned(
              top: -50,
              left: -40,
              child: _buildBubble(140, Colors.white.withOpacity(0.1))),
          Positioned(
              bottom: 80,
              right: -60,
              child: _buildBubble(180, Colors.white.withOpacity(0.12))),
          Positioned(
              bottom: -70,
              left: -20,
              child: _buildBubble(220, Colors.white.withOpacity(0.08))),

          SafeArea(
            child: RefreshIndicator(
              onRefresh: _refreshUserData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    const Text(
                      "Mi Perfil",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 25),

                    _buildCard(
                      title: "Información Personal",
                      icon: Icons.person,
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 45,
                            backgroundColor: Colors.white.withOpacity(0.3),
                            backgroundImage: userData['fotoUrl'] != null
                                ? NetworkImage(userData['fotoUrl'])
                                : null,
                            child: userData['fotoUrl'] == null
                                ? const Icon(Icons.person,
                                    size: 50, color: Colors.white)
                                : null,
                          ),
                          const SizedBox(height: 15),
                          _buildInfoRow("Nombre", userData['nombreCompleto']),
                          _buildInfoRow("DNI", userData['dni']),
                          _buildInfoRow("Teléfono", userData['telefono']),
                          _buildInfoRow("Dirección", userData['direccion']),
                          const SizedBox(height: 15),
                          InkWell(
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      PerfilCompletoScreen(userData: userData),
                                ),
                              );
                              await _refreshUserData();
                            },
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF6A11CB),
                                    Color(0xFF2575FC)
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Text(
                                  "Ver Información Completa",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    _buildCard(
                      title: "Mis Insights",
                      icon: Icons.insights,
                      child: Column(
                        children: [
                          _buildInfoRow("Alertas Publicadas",
                              userData['alertas']?.toString() ?? "0"),
                          _buildInfoRow("Participaciones",
                              userData['participaciones']?.toString() ?? "0"),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    _buildCard(
                      title: "Configuración",
                      icon: Icons.settings,
                      child: Column(
                        children: [
                          ListTile(
                            leading:
                                const Icon(Icons.edit, color: Colors.black87),
                            title: const Text("Editar Perfil"),
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      PerfilCompletoScreen(userData: userData),
                                ),
                              );
                              await _refreshUserData();
                            },
                          ),
                          const Divider(),
                          ListTile(
                            leading:
                                const Icon(Icons.lock, color: Colors.black87),
                            title: const Text("Cambiar Contraseña"),
                            onTap: _mostrarPopupCambiarPassword,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 35),

                    // 🔹 Botón de cerrar sesión mejorado (abajo, no fijo)
                    ElevatedButton.icon(
                      onPressed: _cerrarSesion,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(
                            vertical: 15, horizontal: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 3,
                      ),
                      icon: const Icon(Icons.logout, color: Colors.white),
                      label: const Text(
                        "Cerrar Sesión",
                        style: TextStyle(
                          fontSize: 17,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(
      {required String title,
      required IconData icon,
      required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: theme.AppColors.orange),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Text(
            "$label: ",
            style: const TextStyle(
                fontWeight: FontWeight.w600, color: Colors.black87),
          ),
          Expanded(
            child: Text(
              value ?? "No registrado",
              style: const TextStyle(color: Colors.black87),
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
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
