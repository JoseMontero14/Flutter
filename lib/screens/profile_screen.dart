import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'perfil_completo_screen.dart';
import '../theme/app_colors.dart' as theme;

class ProfileScreen extends StatefulWidget {
  final String dni;

  const ProfileScreen({Key? key, required this.dni}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _direccionController = TextEditingController();
  final ImagePicker picker = ImagePicker();

  bool _cargando = false;
  bool _esPrimeraVez = false;
  String? fotoUrl;

  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario();
  }

  Future<void> _cargarDatosUsuario() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(widget.dni)
          .get();

      if (snapshot.exists) {
        final data = snapshot.data()!;
        setState(() {
          _telefonoController.text = data['telefono'] ?? '';
          _direccionController.text = data['direccion'] ?? '';
          fotoUrl = data['fotoUrl'];
          _esPrimeraVez =
              (data['telefono'] == null || data['telefono'].isEmpty) ||
              (data['direccion'] == null || data['direccion'].isEmpty);
        });
      }
    } catch (e) {
      debugPrint('Error al cargar datos: $e');
    }
  }

  Future<void> _actualizarDatos() async {
    final telefono = _telefonoController.text.trim();
    final direccion = _direccionController.text.trim();

    if (telefono.isEmpty || direccion.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa ambos campos')),
      );
      return;
    }

    setState(() => _cargando = true);

    try {
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(widget.dni)
          .update({
        'telefono': telefono,
        'direccion': direccion,
        'fotoUrl': fotoUrl,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Datos actualizados correctamente ✅')),
      );

      if (_esPrimeraVez && mounted) {
        final snapshot = await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(widget.dni)
            .get();

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                PerfilCompletoScreen(userData: snapshot.data()!),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error al actualizar: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al actualizar datos')),
      );
    } finally {
      setState(() => _cargando = false);
    }
  }

  Future<void> _seleccionarFoto() async {
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    try {
      String storagePath = 'usuarios/${widget.dni}/perfil.jpg';
      Reference ref = FirebaseStorage.instance.ref().child(storagePath);

      UploadTask uploadTask;
      if (kIsWeb) {
        Uint8List fileBytes = await pickedFile.readAsBytes();
        uploadTask = ref.putData(fileBytes);
      } else {
        File file = File(pickedFile.path);
        uploadTask = ref.putFile(file);
      }

      TaskSnapshot snapshot = await uploadTask;
      String downloadURL = await snapshot.ref.getDownloadURL();

      setState(() => fotoUrl = downloadURL);

      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(widget.dni)
          .update({'fotoUrl': downloadURL});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto subida correctamente ✅')),
      );
    } catch (e) {
      debugPrint('Error al subir la foto: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al subir la foto: $e')));
    }
  }

  @override
  void dispose() {
    _telefonoController.dispose();
    _direccionController.dispose();
    super.dispose();
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
        title: const Text(
          "Editar Perfil",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Stack(
        children: [
          // 🎨 Fondo degradado coherente con login/perfil
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFACC15), Color(0xFF1E3A8A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // 🫧 Burbujas decorativas
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

          // 🧩 Contenido principal
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
              child: Column(
                children: [
                  const SizedBox(height: 10),

                  // 🧑 Imagen de perfil
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 65,
                          backgroundColor: Colors.white.withOpacity(0.4),
                          backgroundImage:
                              fotoUrl != null ? NetworkImage(fotoUrl!) : null,
                          child: fotoUrl == null
                              ? const Icon(Icons.person,
                                  size: 60, color: Colors.white)
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: InkWell(
                            onTap: _seleccionarFoto,
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFFACC15), Color(0xFF1E3A8A)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              padding: const EdgeInsets.all(8),
                              child: const Icon(Icons.camera_alt,
                                  color: Colors.white, size: 20),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // 📱 Campos de texto
                  _buildTextField(
                    controller: _telefonoController,
                    icon: Icons.phone,
                    label: 'Teléfono',
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _direccionController,
                    icon: Icons.location_on,
                    label: 'Dirección',
                  ),
                  const SizedBox(height: 30),

                  // 💾 Botón guardar
                  _cargando
                      ? const Center(child: CircularProgressIndicator())
                      : _buildGradientButton(
                          text: _esPrimeraVez
                              ? 'Guardar y continuar'
                              : 'Guardar cambios',
                          icon: Icons.save,
                          onPressed: _actualizarDatos,
                        ),
                  const SizedBox(height: 40),
                ],
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
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required IconData icon,
    required String label,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: theme.AppColors.primaryBlue),
        labelText: label,
        filled: true,
        fillColor: Colors.white.withOpacity(0.9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
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
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
