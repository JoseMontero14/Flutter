import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_colors.dart';
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
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email, password: password);

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
    return Scaffold(
      backgroundColor: const Color(0xFF121212), 
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person_add_alt_1_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    "Crear cuenta",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 32),

                  
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
                            if (value == null || value.isEmpty) {
                              return "Ingresa tu DNI";
                            }
                            if (value.length != 8) {
                              return "El DNI debe tener 8 dígitos";
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      FilledButton(
                        onPressed: _isLoading ? null : _buscarDni,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text("Buscar"),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),
                  _buildInputField(
                    controller: _nombreController,
                    label: "Nombre",
                    icon: Icons.person_outline,
                    readOnly: true,
                  ),
                  const SizedBox(height: 14),
                  _buildInputField(
                    controller: _apellidoController,
                    label: "Apellidos",
                    icon: Icons.person_outline_rounded,
                    readOnly: true,
                  ),
                  const SizedBox(height: 14),
                  _buildInputField(
                    controller: _passwordController,
                    label: "Contraseña",
                    icon: Icons.lock_outline,
                    obscureText: true,
                    maxLength: 20,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Ingresa tu contraseña";
                      }
                      if (value.length < 6) {
                        return "Debe tener al menos 6 caracteres";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 30),

                  
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _isLoading ? null : _registerUser,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                          : const Icon(Icons.app_registration_rounded),
                      label: const Text(
                        "Registrarse",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
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
                                builder: (context) => const LoginScreen()),
                          );
                        },
                        child: const Text(
                          "Inicia sesión",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
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
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        counterText: "",
        prefixIcon: Icon(icon, color: Colors.grey[400], size: 22),
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[400]),
        filled: true,
        fillColor: const Color(0xFF1E1E1E), 
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[700]!, width: 1),
        ),
      ),
      validator: validator,
    );
  }
}
