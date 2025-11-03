import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_colors.dart' as theme;
import 'crear_alerta_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String dni;
  const ProfileScreen({Key? key, required this.dni}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _userData;
  final _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final snap = await _firestore.collection('usuarios').doc(widget.dni).get();
    setState(() {
      _userData = snap.data();
    });
  }

  Future<void> _editarPerfil() async {
    final _telefonoController = TextEditingController(text: _userData?['telefono'] ?? '');
    final _direccionController = TextEditingController(text: _userData?['direccion'] ?? '');
    String fotoBase64 = _userData?['fotoBase64'] ?? '';

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.AppColors.surfaceDark,
        title: const Text("Editar perfil", style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () async {
                  if (fotoBase64.isNotEmpty) {
                    _verFotoCircularCompleta(fotoBase64);
                  }
                },
                onLongPress: () async {
                  final picker = ImagePicker();
                  final pickedFile = await picker.pickImage(
                    source: ImageSource.gallery,
                    imageQuality: 70,
                  );
                  if (pickedFile != null) {
                    final bytes = await pickedFile.readAsBytes();
                    setState(() {
                      fotoBase64 = base64Encode(bytes);
                    });
                  }
                },
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: theme.AppColors.textMuted,
                  backgroundImage: fotoBase64.isNotEmpty
                      ? MemoryImage(base64Decode(fotoBase64))
                      : null,
                  child: fotoBase64.isEmpty
                      ? const Icon(Icons.person, size: 40, color: Colors.white)
                      : null,
                ),
              ),
              const SizedBox(height: 8),
              const Text("(Toca para ver, mantén para cambiar)",
                  style: TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 12),
              TextField(
                controller: _telefonoController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "Teléfono",
                  labelStyle: TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Colors.black26,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _direccionController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "Dirección",
                  labelStyle: TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Colors.black26,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: theme.AppColors.textMuted),
            onPressed: () async {
              await _firestore.collection('usuarios').doc(widget.dni).update({
                'telefono': _telefonoController.text.trim(),
                'direccion': _direccionController.text.trim(),
                'fotoBase64': fotoBase64,
              });
              await _loadUserData();
              Navigator.pop(context);
            },
            child: const Text("Guardar"),
          ),
        ],
      ),
    );
  }

  void _verFotoCircularCompleta(String base64Img) {
    showDialog(
      context: context,
      builder: (_) => GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          color: Colors.black87.withOpacity(0.9),
          alignment: Alignment.center,
          child: Hero(
            tag: "foto_perfil",
            child: ClipOval(
              child: Image.memory(
                base64Decode(base64Img),
                width: 200,
                height: 200,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _eliminarAlerta(String idAlerta) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.AppColors.surfaceDark,
        title: const Text("Eliminar alerta", style: TextStyle(color: Colors.white)),
        content: const Text("¿Estás seguro de eliminar esta alerta?", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancelar", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Eliminar"),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _firestore.collection('alertas').doc(idAlerta).delete();
    }
  }

  void _verImagenCompleta(String base64Img) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: InteractiveViewer(
          panEnabled: true,
          minScale: 1,
          maxScale: 4,
          child: Image.memory(
            base64Decode(base64Img),
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_userData == null) {
      return const Scaffold(
        backgroundColor: theme.AppColors.backgroundDark,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    final fotoBase64 = _userData?['fotoBase64'] ?? '';

    return Scaffold(
      backgroundColor: theme.AppColors.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () {
                      if (fotoBase64.isNotEmpty) {
                        _verFotoCircularCompleta(fotoBase64);
                      }
                    },
                    child: Hero(
                      tag: "foto_perfil",
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: theme.AppColors.textMuted,
                        backgroundImage: fotoBase64.isNotEmpty ? MemoryImage(base64Decode(fotoBase64)) : null,
                        child: fotoBase64.isEmpty
                            ? Text(
                                (_userData?['nombreCompleto'] ?? 'U')[0],
                                style: const TextStyle(color: Colors.white, fontSize: 40),
                              )
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () async {
                          final picker = ImagePicker();
                          final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
                          if (pickedFile != null) {
                            final bytes = await pickedFile.readAsBytes();
                            await _firestore.collection('usuarios').doc(widget.dni).update({
                              'fotoBase64': base64Encode(bytes),
                            });
                            await _loadUserData();
                          }
                        },
                        child: Text(
                          fotoBase64.isEmpty ? 'Añadir foto' : 'Editar foto',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      if (fotoBase64.isNotEmpty)
                        TextButton(
                          onPressed: () async {
                            await _firestore.collection('usuarios').doc(widget.dni).update({
                              'fotoBase64': '',
                            });
                            await _loadUserData();
                          },
                          child: const Text('Eliminar foto', style: TextStyle(color: Colors.white)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "${_userData?['nombreCompleto'] ?? ''} ${_userData?['apellidos'] ?? ''}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '@${_userData?['handle'] ?? 'handle'}',
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.AppColors.textMuted,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _editarPerfil,
                    child: const Text(
                      "Editar perfil",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),

            // ===== Tabs =====
            TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey,
              tabs: const [
                Tab(text: "Alertas"),
                Tab(text: "Dashboard"),
                Tab(text: "Galería"),
              ],
            ),

            // ===== TabBarView =====
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // ALERTAS
                  StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('alertas')
                        .where('dniUsuario', isEqualTo: widget.dni)
                        .orderBy('fecha', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator(color: Colors.white));
                      }
                      final docs = snapshot.data!.docs;
                      if (docs.isEmpty) {
                        return const Center(child: Text("No hay alertas", style: TextStyle(color: Colors.white)));
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.all(10),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final doc = docs[index];
                          final alerta = doc.data() as Map<String, dynamic>;
                          final idAlerta = doc.id;

                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.AppColors.surfaceDark,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(alerta['texto'] ?? '', style: const TextStyle(color: Colors.white)),
                                      const SizedBox(height: 4),
                                      Text(alerta['tipo'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                    ],
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert, color: Colors.grey),
                                  color: theme.AppColors.surfaceDark,
                                  onSelected: (value) async {
                                    if (value == 'editar') {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => CrearAlertaScreen(dni: widget.dni, idAlerta: idAlerta),
                                        ),
                                      );
                                      setState(() {});
                                    } else if (value == 'eliminar') {
                                      _eliminarAlerta(idAlerta);
                                    }
                                  },
                                  itemBuilder: (context) => const [
                                    PopupMenuItem(value: 'editar', child: Text("Editar", style: TextStyle(color: Colors.white))),
                                    PopupMenuItem(value: 'eliminar', child: Text("Eliminar", style: TextStyle(color: Colors.white))),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),

                  // ==== DASHBOARD ====
                  DashboardTab(dni: widget.dni),

                  // GALERÍA
                  StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('alertas')
                        .where('dniUsuario', isEqualTo: widget.dni)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator(color: Colors.white));
                      }

                      final docs = snapshot.data!.docs;
                      final List<String> imagenes = [];
                      for (var doc in docs) {
                        final data = doc.data() as Map<String, dynamic>;
                        if (data['imagenesBase64'] != null && data['imagenesBase64'] is List) {
                          imagenes.addAll(List<String>.from(data['imagenesBase64']));
                        }
                        if (data['imagenBase64'] != null && (data['imagenBase64'] as String).isNotEmpty) {
                          imagenes.add(data['imagenBase64']);
                        }
                      }

                      if (imagenes.isEmpty) {
                        return const Center(child: Text("No hay imágenes", style: TextStyle(color: Colors.white)));
                      }

                      return GridView.builder(
                        padding: const EdgeInsets.all(10),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 6,
                          mainAxisSpacing: 6,
                        ),
                        itemCount: imagenes.length,
                        itemBuilder: (context, index) {
                          final base64Img = imagenes[index];
                          return GestureDetector(
                            onTap: () => _verImagenCompleta(base64Img),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.memory(
                                base64Decode(base64Img),
                                fit: BoxFit.cover,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===== DASHBOARD TAB =====
class DashboardTab extends StatefulWidget {
  final String dni;
  const DashboardTab({super.key, required this.dni});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  final _firestore = FirebaseFirestore.instance;
  bool _loading = true;
  Map<int, int> alertasPorMes = {};
  Map<String, int> alertasPorTipo = {};
  int totalAlertas = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final snapshot = await _firestore
        .collection('alertas')
        .where('dniUsuario', isEqualTo: widget.dni)
        .get();

    final now = DateTime.now();
    Map<int, int> mensual = {for (var i = 1; i <= 12; i++) i: 0};
    Map<String, int> tipo = {};
    for (var doc in snapshot.docs) {
      final data = doc.data();
      if (data['fecha'] != null) {
        final fecha = (data['fecha'] as Timestamp).toDate();
        mensual[fecha.month] = (mensual[fecha.month] ?? 0) + 1;
      }
      final t = (data['tipo'] ?? 'Sin tipo') as String;
      tipo[t] = (tipo[t] ?? 0) + 1;
    }

    setState(() {
      alertasPorMes = mensual;
      alertasPorTipo = tipo;
      totalAlertas = snapshot.size;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Resumen de actividad",
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatCard("Total", totalAlertas.toString()),
              _buildStatCard("Mes actual", "${alertasPorMes[DateTime.now().month] ?? 0}"),
              _buildStatCard("Tipos", "${alertasPorTipo.length}"),
            ],
          ),
          const SizedBox(height: 30),
          const Text("Alertas por mes",
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          AspectRatio(
            aspectRatio: 1.5,
            child: BarChart(
              BarChartData(
                gridData: FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
  show: true,
  topTitles: AxisTitles(
    sideTitles: SideTitles(showTitles: false), // 🔸 Oculta los números de arriba
  ),
  rightTitles: AxisTitles(
    sideTitles: SideTitles(showTitles: false), // 🔸 Oculta los números de la derecha
  ),
  leftTitles: AxisTitles(
    sideTitles: SideTitles(
      showTitles: true,
      reservedSize: 30,
      getTitlesWidget: (value, meta) => Text(
        value.toInt().toString(),
        style: const TextStyle(color: Colors.white70, fontSize: 12),
      ),
    ),
  ),
  bottomTitles: AxisTitles(
    sideTitles: SideTitles(
      showTitles: true,
      getTitlesWidget: (value, meta) {
        const meses = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
        final index = value.toInt() - 1;
        return Text(
          meses[index >= 0 && index < meses.length ? index : 0],
          style: const TextStyle(color: Colors.white70, fontSize: 10),
        );
      },
    ),
  ),
),

                barGroups: alertasPorMes.entries
                    .map((e) => BarChartGroupData(
                          x: e.key,
                          barRods: [
                            BarChartRodData(
                              toY: e.value.toDouble(),
                              color: theme.AppColors.textMuted,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ],
                        ))
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: 30),
          const Text("Alertas por tipo",
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          AspectRatio(
            aspectRatio: 1.2,
            child: PieChart(
              PieChartData(
                sections: alertasPorTipo.entries.map((e) {
                  final porcentaje =
                      (e.value / totalAlertas * 100).toStringAsFixed(1);
                  return PieChartSectionData(
                    color: Colors.primaries[
                        e.key.hashCode % Colors.primaries.length].withOpacity(0.8),
                    value: e.value.toDouble(),
                    title: "${e.key}\n$porcentaje%",
                    radius: 60,
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}
