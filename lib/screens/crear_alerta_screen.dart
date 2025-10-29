import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_colors.dart' as theme;

class CrearAlertaScreen extends StatefulWidget {
  final String dni;
  final String? idAlerta;

  const CrearAlertaScreen({Key? key, required this.dni, this.idAlerta}) : super(key: key);

  @override
  State<CrearAlertaScreen> createState() => _CrearAlertaScreenState();
}

class _CrearAlertaScreenState extends State<CrearAlertaScreen> {
  final TextEditingController _textController = TextEditingController();
  String? _tipoSeleccionado;
  List<String> _imagenesBase64 = [];
  bool _isLoading = false;

  final List<String> tiposDeIncidente = [
    "Incendio",
    "Robo",
    "Accidente",
    "Violencia",
    "Sospechoso",
    "Otro"
  ];

  @override
  void initState() {
    super.initState();
    if (widget.idAlerta != null) _cargarAlerta(widget.idAlerta!);
  }

  Future<void> _cargarAlerta(String idAlerta) async {
    final doc = await FirebaseFirestore.instance.collection('alertas').doc(idAlerta).get();
    final data = doc.data();
    if (data != null) {
      _textController.text = data['texto'] ?? '';
      _tipoSeleccionado = data['tipo'];
      final imgs = data['imagenesBase64'];
      if (imgs != null && imgs is List) {
        _imagenesBase64 = List<String>.from(imgs);
      }
      setState(() {});
    }
  }

  Future<void> _seleccionarImagenes() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage(imageQuality: 70);
    if (pickedFiles.isNotEmpty) {
      final nuevasImagenes = await Future.wait(
        pickedFiles.map((file) async {
          final bytes = await file.readAsBytes();
          return base64Encode(bytes);
        }),
      );

      setState(() {
        _imagenesBase64.addAll(nuevasImagenes);
        if (_imagenesBase64.length > 3) {
          _imagenesBase64 = _imagenesBase64.take(3).toList(); // Máximo 3 imágenes
        }
      });
    }
  }

  Future<void> _guardarAlerta() async {
    if (_textController.text.trim().isEmpty || _tipoSeleccionado == null) return;
    setState(() => _isLoading = true);

    try {
      final userSnap = await FirebaseFirestore.instance.collection('usuarios').doc(widget.dni).get();
      final nombre = userSnap.data()?['nombreCompleto'] ?? 'Usuario';

      final alertaData = {
        'texto': _textController.text.trim(),
        'tipo': _tipoSeleccionado,
        'fecha': Timestamp.now(),
        'dniUsuario': widget.dni,
        'nombreUsuario': nombre,
        'imagenesBase64': _imagenesBase64,
      };

      if (widget.idAlerta == null) {
        final docRef = await FirebaseFirestore.instance.collection('alertas').add({
          ...alertaData,
          'likesUsuarios': [],
          'reposts': 0,
        });
        await docRef.update({'idAlerta': docRef.id});
      } else {
        await FirebaseFirestore.instance
            .collection('alertas')
            .doc(widget.idAlerta)
            .set(alertaData, SetOptions(merge: true));
      }

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al guardar: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: theme.AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: theme.AppColors.backgroundDark,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.idAlerta == null ? "Nueva Alerta" : "Editar Alerta",
          style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w500),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _textController,
              maxLines: 4,
              style: const TextStyle(color: Colors.white70),
              decoration: InputDecoration(
                hintText: "Describe tu alerta...",
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _tipoSeleccionado,
              dropdownColor: const Color(0xFF1E1E1E),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.AppColors.borderDark),
                ),
              ),
              style: const TextStyle(color: Colors.white70),
              hint: const Text("Selecciona tipo de incidente", style: TextStyle(color: Colors.white54)),
              items: tiposDeIncidente
                  .map((tipo) => DropdownMenuItem(
                        value: tipo,
                        child: Text(tipo, style: const TextStyle(color: Colors.white70)),
                      ))
                  .toList(),
              onChanged: (val) => setState(() => _tipoSeleccionado = val),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _seleccionarImagenes,
                  icon: const Icon(Icons.image, color: Colors.white),
                  label: const Text("Agregar imágenes", style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E2E2E),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_imagenesBase64.isNotEmpty)
              SizedBox(
                height: 70,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _imagenesBase64.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) => Stack(
                    alignment: Alignment.topRight,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          base64Decode(_imagenesBase64[i]),
                          width: 70,
                          height: 70,
                          fit: BoxFit.cover,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _imagenesBase64.removeAt(i)),
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, color: Colors.white, size: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _guardarAlerta,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey[700],
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _isLoading
                    ? (widget.idAlerta == null ? "Publicando..." : "Guardando...")
                    : (widget.idAlerta == null ? "Publicar" : "Guardar"),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
