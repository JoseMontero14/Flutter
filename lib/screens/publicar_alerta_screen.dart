import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../theme/app_colors.dart' as theme;
import 'crear_alerta_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class PublicarAlertaScreen extends StatefulWidget {
  final String dni;
  const PublicarAlertaScreen({Key? key, required this.dni}) : super(key: key);

  @override
  State<PublicarAlertaScreen> createState() => _PublicarAlertaScreenState();
}

class _PublicarAlertaScreenState extends State<PublicarAlertaScreen> {
  final _firestore = FirebaseFirestore.instance;
  final ScrollController _scrollController = ScrollController();

  String nombreUsuarioActual = "";
  String? fotoBase64UsuarioActual;
  bool cargandoNombre = true;

  @override
  void initState() {
    super.initState();
    _cargarNombreUsuario();
  }

  Future<void> _cargarNombreUsuario() async {
    try {
      if (widget.dni.isEmpty) {
        setState(() {
          nombreUsuarioActual = "Usuario";
          cargandoNombre = false;
        });
        return;
      }

      final doc = await _firestore.collection('usuarios').doc(widget.dni).get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          nombreUsuarioActual = (data['nombreCompleto'] ?? "Usuario").toString();
          fotoBase64UsuarioActual = data['fotoBase64'];
          cargandoNombre = false;
        });
      } else {
        setState(() {
          nombreUsuarioActual = "Usuario";
          cargandoNombre = false;
        });
      }
    } catch (e) {
      setState(() {
        nombreUsuarioActual = "Usuario";
        cargandoNombre = false;
      });
    }
  }

  Widget _buildPostInput() {
    if (cargandoNombre) {
      return Center(
        child: CircularProgressIndicator(color: theme.AppColors.textLight),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: theme.AppColors.textMuted,
                backgroundImage: fotoBase64UsuarioActual != null
                    ? MemoryImage(base64Decode(fotoBase64UsuarioActual!))
                    : null,
                child: fotoBase64UsuarioActual == null
                    ? Text(
                        nombreUsuarioActual.isNotEmpty
                            ? nombreUsuarioActual[0].toUpperCase()
                            : "U",
                        style: TextStyle(color: theme.AppColors.backgroundDark),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CrearAlertaScreen(dni: widget.dni),
                      ),
                    );
                    setState(() {});
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F1F1F),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "¿Qué novedades tienes?",
                      style:
                          TextStyle(color: Colors.grey[400], fontSize: 14),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(color: Color(0xFF2E2E2E), thickness: 1, height: 1),
        ],
      ),
    );
  }

  Widget _buildAlertItem(QueryDocumentSnapshot doc) {
    final alerta = doc.data() as Map<String, dynamic>;
    final textoAlerta = (alerta['texto'] ?? "").toString();
    final tipoAlerta = (alerta['tipo'] ?? "").toString();
    final fecha = (alerta['fecha'] as Timestamp?)?.toDate();
    final fechaTxt =
        fecha != null ? "${fecha.day}/${fecha.month}/${fecha.year}" : "";
    final imagenes = (alerta['imagenesBase64'] ?? []) as List<dynamic>;
    final tieneImgs = imagenes.isNotEmpty;
    final dniUsuario = (alerta['dniUsuario'] ?? "").toString();
    final idAlerta = doc.id;
    final nombreUsuario = (alerta['nombreUsuario'] ?? "Usuario").toString();

    return FutureBuilder<DocumentSnapshot?>(
      future: dniUsuario.isNotEmpty
          ? _firestore.collection('usuarios').doc(dniUsuario).get()
          : Future.value(null),
      builder: (context, snapshotUsuario) {
        String? fotoBase64Usuario;

        if (snapshotUsuario.hasData &&
            snapshotUsuario.data != null &&
            snapshotUsuario.data!.exists) {
          final usuarioData =
              snapshotUsuario.data!.data() as Map<String, dynamic>?;
          if (usuarioData != null && usuarioData.containsKey('fotoBase64')) {
            fotoBase64Usuario = usuarioData['fotoBase64'];
          }
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: theme.AppColors.textMuted,
                    backgroundImage: fotoBase64Usuario != null
                        ? MemoryImage(base64Decode(fotoBase64Usuario))
                        : null,
                    child: fotoBase64Usuario == null
                        ? Text(
                            nombreUsuario.isNotEmpty
                                ? nombreUsuario[0].toUpperCase()
                                : "U",
                            style:
                                TextStyle(color: theme.AppColors.backgroundDark),
                          )
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(nombreUsuario,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14)),
                        Text(tipoAlerta,
                            style:
                                TextStyle(color: Colors.grey[400], fontSize: 11)),
                      ],
                    ),
                  ),
                  if (dniUsuario == widget.dni)
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                      color: const Color(0xFF1F1F1F),
                      onSelected: (value) async {
                        if (value == 'eliminar') {
                          _confirmarEliminacion(idAlerta);
                        } else if (value == 'editar') {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  CrearAlertaScreen(dni: widget.dni, idAlerta: idAlerta),
                            ),
                          );
                          setState(() {});
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'editar',
                          child: Text("Editar", style: TextStyle(color: Colors.white)),
                        ),
                        const PopupMenuItem(
                          value: 'eliminar',
                          child:
                              Text("Eliminar", style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(textoAlerta,
                  style: const TextStyle(color: Colors.white, fontSize: 14)),
              if (tieneImgs)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: SizedBox(
                    height: 200,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: imagenes.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final imgBase64 = imagenes[index]?.toString() ?? "";
                        if (imgBase64.isEmpty) return const SizedBox.shrink();
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => Scaffold(
                                  backgroundColor: Colors.black.withOpacity(0.95),
                                  appBar: AppBar(
                                    backgroundColor: Colors.transparent,
                                    elevation: 0,
                                    iconTheme: const IconThemeData(color: Colors.white),
                                  ),
                                  body: Center(
                                    child: InteractiveViewer(
                                      clipBehavior: Clip.none,
                                      minScale: 0.8,
                                      maxScale: 4.0,
                                      child: Image.memory(
                                        base64Decode(imgBase64),
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.memory(
                              base64Decode(imgBase64),
                              fit: BoxFit.cover,
                              width: 200,
                              height: 200,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              const SizedBox(height: 6),
              if (alerta.containsKey('latitud') && alerta.containsKey('longitud')) ...[
                GestureDetector(
                  onTap: () async {
                    final lat = alerta['latitud'];
                    final lon = alerta['longitud'];
                    final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lon';
                    final uri = Uri.parse(url);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    } else {
                      debugPrint('No se pudo abrir Google Maps');
                    }
                  },
                  child: Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.lightBlueAccent, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        "Ver ubicación en Google Maps",
                        style: const TextStyle(
                          color: Colors.lightBlueAccent,
                          fontSize: 13,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
              ],
              Row(
                children: [
                  _buildLikeButton(idAlerta, dniUsuario), // <-- CORRECCIÓN
                  const SizedBox(width: 16),
                  _buildCommentButton(idAlerta),
                ],
              ),
              const SizedBox(height: 6),
              Text(fechaTxt, style: const TextStyle(color: Colors.white38, fontSize: 11)),
              const SizedBox(height: 6),
              const Divider(color: Color(0xFF2E2E2E), thickness: 1),
              _buildCommentsThread(idAlerta),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLikeButton(String idAlerta, String dniDuenoAlerta) {
    return StreamBuilder<DocumentSnapshot>(
      stream: idAlerta.isNotEmpty
          ? _firestore.collection('alertas').doc(idAlerta).snapshots()
          : const Stream.empty(),
      builder: (context, snapshotLike) {
        if (!snapshotLike.hasData) return const SizedBox.shrink();
        final data = snapshotLike.data!.data() as Map<String, dynamic>? ?? {};
        final likesUsuarios = List<String>.from(data['likesUsuarios'] ?? []);
        final yaLeGusto = likesUsuarios.contains(widget.dni);
        final likesCount = likesUsuarios.length;

        return GestureDetector(
          onTap: () async {
            if (idAlerta.isEmpty) return;
            final alertaRef = _firestore.collection('alertas').doc(idAlerta);
            try {
              if (yaLeGusto) {
                await alertaRef.update({'likesUsuarios': FieldValue.arrayRemove([widget.dni])});
              } else {
                await alertaRef.update({'likesUsuarios': FieldValue.arrayUnion([widget.dni])});

                if (dniDuenoAlerta != widget.dni) {
                  await _firestore.collection('notificaciones').add({
                    'dniUsuarioDestino': dniDuenoAlerta,
                    'dniUsuarioOrigen': widget.dni,
                    'nombreUsuarioOrigen': nombreUsuarioActual,
                    'tipo': 'like',
                    'idAlerta': idAlerta,
                    'fecha': Timestamp.now(),
                  });
                }
              }
            } catch (e) {
              print("Error al dar like: $e");
            }
          },
          child: Row(
            children: [
              Icon(Icons.favorite,
                  size: 16, color: yaLeGusto ? Colors.red : Colors.white54),
              const SizedBox(width: 4),
              Text(likesCount.toString(),
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCommentButton(String idAlerta) {
    return StreamBuilder<QuerySnapshot>(
      stream: idAlerta.isNotEmpty
          ? _firestore
              .collection('alertas')
              .doc(idAlerta)
              .collection('comentarios')
              .snapshots()
          : const Stream.empty(),
      builder: (context, snapshotC) {
        final comentariosCount =
            snapshotC.hasData ? snapshotC.data!.docs.length : 0;
        return GestureDetector(
          onTap: () => _mostrarComentarios(context, idAlerta),
          child: Row(
            children: [
              const Icon(Icons.comment_outlined,
                  color: Colors.white54, size: 16),
              const SizedBox(width: 4),
              Text(comentariosCount.toString(),
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCommentsThread(String idAlerta) {
    return StreamBuilder<QuerySnapshot>(
      stream: idAlerta.isNotEmpty
          ? _firestore
              .collection('alertas')
              .doc(idAlerta)
              .collection('comentarios')
              .orderBy('fecha', descending: true)
              .snapshots()
          : const Stream.empty(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final comentarios = snapshot.data!.docs;

        return Column(
          children: comentarios.map((c) {
            final data = c.data() as Map<String, dynamic>;
            final idComentario = c.id;
            final nombreUsuarioComentario =
                (data['nombreUsuario'] ?? "Usuario").toString();
            final textoComentario = (data['texto'] ?? "").toString();
            final dniUsuarioComentario = (data['dniUsuario'] ?? "").toString();
            final tieneImgComentario =
                (data['imagenBase64'] ?? "").toString().isNotEmpty;
            final fechaComentario = (data['fecha'] as Timestamp?)?.toDate();
            final fechaTxtComentario = fechaComentario != null
                ? "${fechaComentario.day}/${fechaComentario.month}/${fechaComentario.year}"
                : "";

            return Padding(
              padding: const EdgeInsets.only(left: 36, top: 6, bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 2,
                    height: tieneImgComentario ? 140 : 60,
                    color: Colors.white24,
                    margin: const EdgeInsets.only(right: 8),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              nombreUsuarioComentario,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            if (dniUsuarioComentario == widget.dni)
                              GestureDetector(
                                onTap: () async {
                                  await _firestore
                                      .collection('alertas')
                                      .doc(idAlerta)
                                      .collection('comentarios')
                                      .doc(idComentario)
                                      .delete();
                                },
                                child: const Icon(
                                  Icons.delete_outline,
                                  size: 16,
                                  color: Colors.redAccent,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          textoComentario,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                        if (tieneImgComentario)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => Scaffold(
                                      backgroundColor:
                                          Colors.black.withOpacity(0.95),
                                      appBar: AppBar(
                                        backgroundColor: Colors.transparent,
                                        elevation: 0,
                                        iconTheme: const IconThemeData(
                                            color: Colors.white),
                                      ),
                                      body: Center(
                                        child: InteractiveViewer(
                                          clipBehavior: Clip.none,
                                          minScale: 0.8,
                                          maxScale: 4.0,
                                          child: Image.memory(
                                            base64Decode(
                                                data['imagenBase64'] ?? ""),
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.memory(
                                  base64Decode(data['imagenBase64'] ?? ""),
                                  fit: BoxFit.contain,
                                  width: 180,
                                  height: 120,
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 6),
                        Text(
                          fechaTxtComentario,
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  void _mostrarComentarios(BuildContext context, String idAlerta) {
    if (idAlerta.isEmpty) return;
    final TextEditingController _controller = TextEditingController();
    String? imagenBase64;
    final picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.AppColors.backgroundDark,
      builder: (context) {
        return Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: StatefulBuilder(
            builder: (context, setStateModal) => Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.AppColors.backgroundDark,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: theme.AppColors.textMuted,
                        backgroundImage: fotoBase64UsuarioActual != null
                            ? MemoryImage(
                                base64Decode(fotoBase64UsuarioActual!))
                            : null,
                        child: fotoBase64UsuarioActual == null
                            ? Text(
                                nombreUsuarioActual.isNotEmpty
                                    ? nombreUsuarioActual[0].toUpperCase()
                                    : "U",
                                style: TextStyle(
                                    color: theme.AppColors.backgroundDark),
                              )
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: "Escribe tu comentario...",
                            hintStyle:
                                const TextStyle(color: Colors.white54),
                            filled: true,
                            fillColor: const Color(0xFF1F1F1F),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: Colors.white24, width: 1),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: Colors.white54, width: 1),
                            ),
                          ),
                          maxLines: null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (imagenBase64 != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(
                        base64Decode(imagenBase64!),
                        height: 120,
                        fit: BoxFit.cover,
                      ),
                    ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.image_outlined,
                            color: Colors.white70),
                        onPressed: () async {
                          final picked = await picker.pickImage(
                              source: ImageSource.gallery);
                          if (picked != null) {
                            final bytes = await picked.readAsBytes();
                            setStateModal(() {
                              imagenBase64 = base64Encode(bytes);
                            });
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.camera_alt_outlined,
                            color: Colors.white70),
                        onPressed: () async {
                          final picked = await picker.pickImage(
                              source: ImageSource.camera);
                          if (picked != null) {
                            final bytes = await picked.readAsBytes();
                            setStateModal(() {
                              imagenBase64 = base64Encode(bytes);
                            });
                          }
                        },
                      ),
                      const Spacer(),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2A2A2A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () async {
                          if ((_controller.text.isEmpty) &&
                              (imagenBase64 == null)) return;

                          await _firestore
                              .collection('alertas')
                              .doc(idAlerta)
                              .collection('comentarios')
                              .add({
                            'nombreUsuario': nombreUsuarioActual,
                            'dniUsuario': widget.dni,
                            'texto': _controller.text,
                            'imagenBase64': imagenBase64 ?? "",
                            'fecha': Timestamp.now(),
                          });

                          Navigator.pop(context);
                        },
                        child: const Text("Publicar"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _confirmarEliminacion(String idAlerta) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F1F1F),
        title: const Text("Eliminar alerta",
            style: TextStyle(color: Colors.white)),
        content: const Text(
          "¿Estás seguro de eliminar esta alerta?",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar",
                style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent),
            onPressed: () async {
              if (idAlerta.isNotEmpty) {
                await _firestore
                    .collection('alertas')
                    .doc(idAlerta)
                    .delete();
                Navigator.pop(context);
                setState(() {});
              }
            },
            child: const Text("Eliminar"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: theme.AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: theme.AppColors.backgroundDark,
        elevation: 0,
        centerTitle: true,
        title: GestureDetector(
          onTap: () {
            _scrollController.animateTo(
              0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
          child: const Text(
            "Alerta Comunitaria",
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('alertas')
              .orderBy('fecha', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(
                  child: CircularProgressIndicator(color: Colors.white));
            }
            final docs = snapshot.data!.docs;
            return ListView(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 6),
              children: [
                _buildPostInput(),
                ...docs.map(_buildAlertItem).toList(),
                const SizedBox(height: 60),
              ],
            );
          },
        ),
      ),
    );
  }
}
