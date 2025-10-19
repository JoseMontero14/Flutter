import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_colors.dart' as theme;
import 'login_screen.dart';
import '../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _dniController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _apellidoController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _dniController.dispose();
    _passwordController.dispose();
    _nombreController.dispose();
    _apellidoController.dispose();
    super.dispose();
  }

  Future<void> _buscarDni() async {
    final dni = _dniController.text.trim();
    if (dni.length != 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("El DNI debe tener 8 dígitos")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final data = await ApiService.getDniInfo(dni);

      if (data.isEmpty || data['nombres'] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No se encontró información para este DNI.")),
        );
        return;
      }

      setState(() {
        _nombreController.text = data['nombres'] ?? '';
        _apellidoController.text =
            "${data['apellidoPaterno'] ?? ''} ${data['apellidoMaterno'] ?? ''}".trim();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al buscar DNI: ${e.toString()}")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) return;

    final dni = _dniController.text.trim();
    final password = _passwordController.text.trim();
    final email = "$dni@dni.com";

    setState(() => _isLoading = true);

    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      await FirebaseFirestore.instance.collection('usuarios').doc(dni).set({
        'dni': dni,
        'nombreCompleto': _nombreController.text,
        'apellidos': _apellidoController.text,
        'telefono': '',
        'direccion': '',
        'tipoUsuario': 'Civil',
        'fechaRegistro': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Usuario registrado exitosamente")),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } on FirebaseAuthException catch (e) {
      String errorMsg = "Ocurrió un error al registrar";

      if (e.code == 'email-already-in-use') {
        errorMsg = 'Este DNI ya está registrado';
      } else if (e.code == 'weak-password') {
        errorMsg = 'La contraseña es demasiado débil';
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(errorMsg)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error inesperado: ${e.toString()}")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final gradient = const LinearGradient(
      colors: [
        theme.AppColors.primaryBlue,
        theme.AppColors.orange,
        theme.AppColors.warningYellow,
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(gradient: gradient),
        child: Stack(
          children: [
            // Burbujas decorativas
            Positioned(
              top: -60,
              left: -40,
              child: _buildBubble(180, Colors.white.withOpacity(0.15)),
            ),
            Positioned(
              bottom: 80,
              right: -60,
              child: _buildBubble(220, Colors.white.withOpacity(0.1)),
            ),

            // Contenido principal
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/security_illustration.png',
                          width: 90,
                          height: 90,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.person_add_alt_1_rounded,
                                size: 80, color: Colors.white);
                          },
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "Crear Cuenta",
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 40),

                        // Campo DNI + botón Buscar
                        Row(
                          children: [
                            Expanded(
                              child: _buildInputField(
                                controller: _dniController,
                                label: "DNI",
                                icon: Icons.badge_outlined,
                                keyboardType: TextInputType.number,
                                maxLength: 8,
                                validator: (value) {
                                  if (value == null || value.isEmpty)
                                    return "Ingresa tu DNI";
                                  if (value.length != 8)
                                    return "El DNI debe tener 8 dígitos";
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: _isLoading ? null : _buscarDni,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.AppColors.orange,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text("Buscar",
                                  style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        _buildInputField(
                          controller: _nombreController,
                          label: "Nombre",
                          icon: Icons.person_outline,
                          readOnly: true,
                        ),
                        const SizedBox(height: 16),
                        _buildInputField(
                          controller: _apellidoController,
                          label: "Apellidos",
                          icon: Icons.person,
                          readOnly: true,
                        ),
                        const SizedBox(height: 16),
                        _buildInputField(
                          controller: _passwordController,
                          label: "Contraseña",
                          icon: Icons.lock_outline,
                          obscureText: true,
                          maxLength: 20,
                          validator: (value) {
                            if (value == null || value.isEmpty)
                              return "Ingresa tu contraseña";
                            if (value.length < 6)
                              return "Debe tener al menos 6 caracteres";
                            return null;
                          },
                        ),
                        const SizedBox(height: 28),

                        // Botón principal
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.AppColors.primaryBlue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              elevation: 5,
                            ),
                            onPressed: _isLoading ? null : _registerUser,
                            icon: const Icon(Icons.app_registration_rounded),
                            label: _isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white),
                                  )
                                : const Text("Registrarse",
                                    style: TextStyle(fontSize: 17)),
                          ),
                        ),

                        const SizedBox(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "¿Ya tienes cuenta?",
                              style: TextStyle(color: Colors.white),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const LoginScreen()),
                                );
                              },
                              child: const Text(
                                "Inicia sesión",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    int? maxLength,
    bool readOnly = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      readOnly: readOnly,
      keyboardType: keyboardType,
      maxLength: maxLength,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        counterText: "",
        prefixIcon: Icon(icon, color: Colors.white),
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.15),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: Colors.white.withOpacity(0.5), width: 1.0),
        ),
      ),
      validator: validator,
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
