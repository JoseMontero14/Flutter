import 'dart:convert';
import 'dart:io' show File;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_colors.dart' as theme;

class PublicarAlertaScreen extends StatefulWidget {
  final String dni;
  const PublicarAlertaScreen({Key? key, required this.dni}) : super(key: key);

  @override
  State<PublicarAlertaScreen> createState() => _PublicarAlertaScreenState();
}

class _PublicarAlertaScreenState extends State<PublicarAlertaScreen> {
  final _firestore = FirebaseFirestore.instance;
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = false;
  bool _showScrollToTop = false;
  String? _tipoSeleccionado;
  String? _filtroTipo;
  DateTime? _filtroFecha;
  File? _selectedImageFile;
  Uint8List? _selectedImageBytes;
  late ScrollController _scrollController;

  final List<String> tiposDeIncidente = [
    "Incendio",
    "Robo",
    "Accidente",
    "Violencia",
    "Sospechoso",
    "Otro",
  ];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()
      ..addListener(() {
        if (_scrollController.offset > 300 && !_showScrollToTop) {
          setState(() => _showScrollToTop = true);
        } else if (_scrollController.offset <= 300 && _showScrollToTop) {
          setState(() => _showScrollToTop = false);
        }
      });
  }

  @override
  void dispose() {
    _textController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _pickImageForPost() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    if (kIsWeb) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _selectedImageBytes = bytes;
        _selectedImageFile = null;
      });
    } else {
      setState(() {
        _selectedImageFile = File(picked.path);
        _selectedImageBytes = null;
      });
    }
  }

  Future<Uint8List?> _pickImageBytes() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return null;

    if (kIsWeb) {
      return await picked.readAsBytes();
    } else {
      final file = File(picked.path);
      return await file.readAsBytes();
    }
  }

  Future<void> _seleccionarFecha() async {
    final DateTime? seleccionada = await showDatePicker(
      context: context,
      initialDate: _filtroFecha ?? DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: theme.AppColors.primaryBlue,
            onPrimary: Colors.white,
            onSurface: theme.AppColors.primaryBlue,
          ),
        ),
        child: child!,
      ),
    );
    if (seleccionada != null) {
      setState(() => _filtroFecha = seleccionada);
    }
  }

  void _limpiarFiltros() {
    setState(() {
      _filtroTipo = null;
      _filtroFecha = null;
      _searchController.clear();
    });
  }

  Future<void> _publicarAlerta() async {
    final texto = _textController.text.trim();
    if (texto.isEmpty || _tipoSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor, completa tipo y descripción.")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String imagenBase64 = '';
      if (_selectedImageFile != null) {
        final bytes = await _selectedImageFile!.readAsBytes();
        imagenBase64 = base64Encode(bytes);
      } else if (_selectedImageBytes != null) {
        imagenBase64 = base64Encode(_selectedImageBytes!);
      }

      final userSnap =
          await _firestore.collection('usuarios').doc(widget.dni).get();
      final nombre = userSnap.data()?['nombreCompleto'] ?? 'Usuario';
      final idAlerta = DateTime.now().millisecondsSinceEpoch.toString();

      await _firestore.collection('alertas').add({
        'idAlerta': idAlerta,
        'texto': texto,
        'imagenBase64': imagenBase64,
        'fecha': Timestamp.now(),
        'dniUsuario': widget.dni,
        'nombreUsuario': nombre,
        'estado': 'pendiente',
        'tipo': _tipoSeleccionado,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Alerta publicada correctamente")),
      );

      setState(() {
        _textController.clear();
        _selectedImageFile = null;
        _selectedImageBytes = null;
        _tipoSeleccionado = null;
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error al guardar: $e")));
      setState(() => _isLoading = false);
    }
  }

  Future<void> _editarAlerta(String idDoc, Map<String, dynamic> alerta) async {
    final TextEditingController editController =
        TextEditingController(text: alerta['texto'] ?? '');
    String tipoEdit = alerta['tipo']?.toString() ?? tiposDeIncidente.first;
    Uint8List? nuevaImgBytes;
    bool removeImage = false;

   await showDialog(
  context: context,
  barrierDismissible: false,
  builder: (_) => StatefulBuilder(builder: (context, setStateDialog) {
    final tieneImgActual =
        (alerta['imagenBase64'] ?? '').toString().isNotEmpty;

    Widget _currentImagePreview() {
      final shownBytes = nuevaImgBytes ??
          ((tieneImgActual && !removeImage)
              ? base64Decode(alerta['imagenBase64'])
              : null);
      if (shownBytes == null) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(shownBytes, fit: BoxFit.cover),
        ),
      );
    }

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.edit_note_rounded,
                      color: theme.AppColors.primaryBlue, size: 30),
                  const SizedBox(width: 8),
                  Text("Editar Alerta",
                      style: TextStyle(
                          color: theme.AppColors.primaryBlue,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                value: tipoEdit,
                items: tiposDeIncidente
                    .map((t) =>
                        DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setStateDialog(() => tipoEdit = v!),
                decoration: InputDecoration(
                  labelText: "Tipo de incidente",
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: editController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: "Descripción",
                  hintText: "Describe brevemente lo ocurrido...",
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Imagen previa o botón para agregar
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: (tieneImgActual && !removeImage) || nuevaImgBytes != null
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Imagen:",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87)),
                          _currentImagePreview(),
                          Row(
                            children: [
                              TextButton.icon(
                                icon: const Icon(Icons.delete_forever,
                                    color: Colors.redAccent),
                                label: const Text("Eliminar",
                                    style:
                                        TextStyle(color: Colors.redAccent)),
                                onPressed: () {
                                  nuevaImgBytes = null;
                                  removeImage = true;
                                  setStateDialog(() {});
                                },
                              ),
                              const SizedBox(width: 10),
                              TextButton.icon(
                                icon: const Icon(Icons.image,
                                    color: Colors.blueAccent),
                                label: const Text("Reemplazar",
                                    style:
                                        TextStyle(color: Colors.blueAccent)),
                                onPressed: () async {
                                  final bytes = await _pickImageBytes();
                                  if (bytes != null) {
                                    nuevaImgBytes = bytes;
                                    removeImage = false;
                                    setStateDialog(() {});
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      )
                    : Center(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                                color: theme.AppColors.primaryBlue, width: 1.2),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          icon: Icon(Icons.add_photo_alternate,
                              color: theme.AppColors.primaryBlue),
                          label: Text("Agregar imagen",
                              style: TextStyle(
                                  color: theme.AppColors.primaryBlue)),
                          onPressed: () async {
                            final bytes = await _pickImageBytes();
                            if (bytes != null) {
                              nuevaImgBytes = bytes;
                              removeImage = false;
                              setStateDialog(() {});
                            }
                          },
                        ),
                      ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    child: const Text("Cancelar",
                        style: TextStyle(color: Colors.grey)),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.save_rounded),
                    label: const Text("Guardar"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 3,
                    ),
                    onPressed: () async {
                      final updates = <String, dynamic>{
                        'texto': editController.text.trim(),
                        'tipo': tipoEdit,
                      };
                      if (nuevaImgBytes != null) {
                        updates['imagenBase64'] = base64Encode(nuevaImgBytes!);
                      } else if (removeImage) {
                        updates['imagenBase64'] = '';
                      }
                      try {
                        await _firestore
                            .collection('alertas')
                            .doc(idDoc)
                            .update(updates);
                        if (!mounted) return;
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text("✅ Alerta actualizada")),
                        );
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text("Error al actualizar: $e")));
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }),
);

  }

  Future<void> _eliminarAlerta(String idDoc) async {
    final confirm = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Eliminar alerta"),
        content:
            const Text("¿Estás seguro de que deseas eliminar esta alerta?"),
        actions: [
          TextButton(
            child: const Text("Cancelar"),
            onPressed: () => Navigator.pop(context, false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text("Eliminar"),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _firestore.collection('alertas').doc(idDoc).delete();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(" Alerta eliminada")),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al eliminar: $e")),
        );
      }
    }
  }

  Widget _buildAlertCard(QueryDocumentSnapshot doc) {
    final alerta = doc.data() as Map<String, dynamic>;
    final fecha = (alerta['fecha'] as Timestamp?)?.toDate();
    final fechaTxt =
        fecha != null ? "${fecha.day}/${fecha.month}/${fecha.year}" : "";
    final tieneImg = (alerta['imagenBase64'] ?? '').toString().isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withOpacity(0.95),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              CircleAvatar(
                backgroundColor: theme.AppColors.primaryBlue,
                child: Text(
                  (alerta['nombreUsuario'] ?? "U")[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(alerta['nombreUsuario'] ?? "Usuario",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(alerta['tipo'] ?? "",
                          style:
                              const TextStyle(color: Colors.grey, fontSize: 12))
                    ]),
              ),
              if (alerta['dniUsuario'] == widget.dni)
                Row(
                  children: [
                    IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blueAccent),
                        onPressed: () => _editarAlerta(doc.id, alerta)),
                    IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        onPressed: () => _eliminarAlerta(doc.id)),
                  ],
                ),
            ]),
            const SizedBox(height: 8),
            Text(alerta['texto'] ?? '',
                style: const TextStyle(fontSize: 14, color: Colors.black87)),
            if (tieneImg)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    // limitamos la altura para que no bloquee el scroll
                    maxHeight: MediaQuery.of(context).size.height * 0.35,
                    minHeight: 80,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.memory(
                      base64Decode(alerta['imagenBase64']),
                      fit: BoxFit.contain,
                      // No especificamos height — el ConstrainedBox lo limita
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Text(" $fechaTxt",
                style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildPostCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withOpacity(0.9),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(" Publicar Alerta",
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: theme.AppColors.primaryBlue)),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _tipoSeleccionado,
            items: tiposDeIncidente
                .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                .toList(),
            decoration: InputDecoration(
              labelText: "Tipo de incidente",
              filled: true,
              fillColor: Colors.grey.withOpacity(0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (v) => setState(() => _tipoSeleccionado = v),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _textController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: "Descripción",
              hintText: "Describe brevemente lo ocurrido...",
              filled: true,
              fillColor: Colors.grey.withOpacity(0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          if (_selectedImageFile != null || _selectedImageBytes != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: _selectedImageFile != null
                  ? Image.file(_selectedImageFile!, height: 130, fit: BoxFit.cover)
                  : Image.memory(_selectedImageBytes!, height: 130, fit: BoxFit.cover),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.AppColors.orange,
                  foregroundColor: Colors.white,
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _pickImageForPost,
                icon: const Icon(Icons.image_outlined),
                label: const Text("Agregar imagen"),
              ),
              const Spacer(),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _isLoading ? null : _publicarAlerta,
                icon: const Icon(Icons.send_rounded),
                label: Text(_isLoading ? "Publicando..." : "Publicar"),
              ),
            ],
          ),
        ],
      ),
    );
  }

    @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 🎨 Fondo degradado con burbujas
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.AppColors.primaryBlue,
                  theme.AppColors.orange.withOpacity(0.9)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Positioned(
            top: -60,
            left: -40,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            right: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // 🧱 Contenido principal con header fijo
          SafeArea(
            child: Column(
              children: [
                // 🔹 HEADER FIJO (icono + línea divisoria)
                Container(
  color: Colors.white.withOpacity(0.12),
  child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      GestureDetector(
        onTap: () {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shield_rounded, color: Colors.white, size: 30),
              const SizedBox(width: 8),
              Text(
                "AlertaCom",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
      // 🔻 Línea divisoria más integrada visualmente
      Container(
        height: 1,
        color: Colors.white.withOpacity(0.3),
        margin: EdgeInsets.zero,
      ),
      // 🔻 Sin separación extra debajo
    ],
  ),
),

                // 🔸 CONTENIDO DESPLAZABLE
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('alertas')
                        .orderBy('fecha', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        );
                      }

                      final docs = snapshot.data!.docs;
                      final filteredDocs = docs.where((d) {
                        final a = d.data() as Map<String, dynamic>;
                        final search = _searchController.text.toLowerCase();
                        final pasaBusqueda = a['nombreUsuario']
                                ?.toString()
                                .toLowerCase()
                                .contains(search) ??
                            false;
                        final pasaTipo = _filtroTipo == null ||
                            a['tipo']?.toString() == _filtroTipo;
                        final fecha = (a['fecha'] as Timestamp?)?.toDate();
                        final pasaFecha = _filtroFecha == null ||
                            (fecha != null &&
                                fecha.day == _filtroFecha!.day &&
                                fecha.month == _filtroFecha!.month &&
                                fecha.year == _filtroFecha!.year);
                        return pasaBusqueda && pasaTipo && pasaFecha;
                      }).toList();

                      return CustomScrollView(
                        controller: _scrollController,
                        slivers: [
                          SliverToBoxAdapter(child: _buildPostCard()),

                          // 🔍 FILTROS
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 10),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _searchController,
                                      onChanged: (_) => setState(() {}),
                                      decoration: InputDecoration(
                                        hintText: "Buscar por nombre...",
                                        prefixIcon: const Icon(Icons.search),
                                        filled: true,
                                        fillColor: Colors.white.withOpacity(0.9),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(14),
                                          borderSide: BorderSide.none,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  DropdownButtonHideUnderline(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.9),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: DropdownButton<String>(
                                        hint: const Text("Tipo"),
                                        value: _filtroTipo,
                                        items: [
                                          const DropdownMenuItem<String>(
                                            value: null,
                                            child: Text("Todos"),
                                          ),
                                          ...tiposDeIncidente.map(
                                            (t) => DropdownMenuItem<String>(
                                              value: t,
                                              child: Text(t),
                                            ),
                                          ),
                                        ],
                                        onChanged: (v) => setState(() => _filtroTipo = v),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.date_range, color: Colors.white),
                                    onPressed: _seleccionarFecha,
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.cleaning_services, color: Colors.white),
                                    onPressed: _limpiarFiltros,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // 📋 LISTA DE ALERTAS
                          if (filteredDocs.isEmpty)
                            const SliverToBoxAdapter(
                              child: Center(
                                child: Padding(
                                  padding: EdgeInsets.all(40),
                                  child: Text(
                                    "No hay alertas con esos filtros.",
                                    style: TextStyle(
                                        color: Colors.white70, fontSize: 16),
                                  ),
                                ),
                              ),
                            )
                          else
                            SliverList(
                              delegate: SliverChildListDelegate(
                                filteredDocs.map((d) => _buildAlertCard(d)).toList(),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

}
