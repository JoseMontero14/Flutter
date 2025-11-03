import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map_heatmap/flutter_map_heatmap.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
import '../theme/app_colors.dart' as theme;

class DashboardGeneralScreen extends StatefulWidget {
  const DashboardGeneralScreen({Key? key}) : super(key: key);

  @override
  State<DashboardGeneralScreen> createState() => _DashboardGeneralScreenState();
}

class _DashboardGeneralScreenState extends State<DashboardGeneralScreen> {
  String tipoSeleccionado = 'Todos';
  int anioSeleccionado = DateTime.now().year;
  bool cargando = true;

  Map<String, int> alertasPorTipo = {};
  Map<int, int> alertasPorMes = {};
  int totalAlertas = 0;
  List<Map<String, dynamic>> alertas = [];

  final List<String> tipos = [
    'Todos',
    'Incendio',
    'Robo',
    'Accidente',
    'Violencia',
    'Sospechoso',
    'Otro'
  ];

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => cargando = true);

    try {
      Query query = FirebaseFirestore.instance.collection('alertas');

      if (tipoSeleccionado != 'Todos') {
        query = query.where('tipo', isEqualTo: tipoSeleccionado);
      }

      final snapshot = await query.get();

      Map<String, int> tipoTemp = {};
      Map<int, int> mesTemp = {};
      int total = 0;
      List<Map<String, dynamic>> listaAlertas = [];

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final timestamp = data['fecha'] as Timestamp?;
        final tipo = (data['tipo'] ?? 'Otro').toString();

        if (timestamp == null) continue;
        final fecha = timestamp.toDate();

        if (fecha.year == anioSeleccionado) {
          total++;
          tipoTemp[tipo] = (tipoTemp[tipo] ?? 0) + 1;
          mesTemp[fecha.month] = (mesTemp[fecha.month] ?? 0) + 1;
          listaAlertas.add(data);
        }
      }

      setState(() {
        alertasPorTipo = tipoTemp;
        alertasPorMes = mesTemp;
        totalAlertas = total;
        alertas = listaAlertas;
        cargando = false;
      });
    } catch (e) {
      setState(() => cargando = false);
      debugPrint("Error cargando datos: $e");
    }
  }

  void _limpiarFiltros() {
    setState(() {
      tipoSeleccionado = 'Todos';
      anioSeleccionado = DateTime.now().year;
    });
    _cargarDatos();
  }

  List<BarChartGroupData> _crearBarrasPorTipo() {
    int index = 0;
    return alertasPorTipo.entries.map((e) {
      index++;
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: e.value.toDouble(),
            color: Colors.blueAccent,
            width: 18,
            borderRadius: BorderRadius.circular(6),
          ),
        ],
      );
    }).toList();
  }

  List<FlSpot> _crearLineasPorMes() {
    return List.generate(12, (i) {
      final mes = i + 1;
      final valor = (alertasPorMes[mes] ?? 0).toDouble();
      return FlSpot(mes.toDouble(), valor);
    });
  }

  List<PieChartSectionData> _crearPieData() {
    if (alertasPorTipo.isEmpty) {
      return [
        PieChartSectionData(
          value: 1,
          title: "Sin datos",
          color: Colors.grey[700],
          titleStyle: const TextStyle(color: Colors.white, fontSize: 12),
        )
      ];
    }

    return alertasPorTipo.entries.map((e) {
      final porcentaje = totalAlertas == 0
          ? 0
          : (e.value / totalAlertas * 100).toStringAsFixed(1);
      return PieChartSectionData(
        value: e.value.toDouble(),
        title: "${e.key}\n$porcentaje%",
        color: Colors.primaries[(e.key.hashCode % Colors.primaries.length)],
        radius: 70,
        titleStyle: const TextStyle(color: Colors.white, fontSize: 11),
      );
    }).toList();
  }

  Color _colorPorTipo(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'incendio':
        return Colors.redAccent;
      case 'robo':
        return Colors.orangeAccent;
      case 'accidente':
        return Colors.yellowAccent;
      case 'violencia':
        return Colors.purpleAccent;
      case 'sospechoso':
        return Colors.blueAccent;
      default:
        return Colors.greenAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final heatPoints = alertas
        .where((a) => a['latitud'] != null && a['longitud'] != null)
        .map((a) => WeightedLatLng(
              LatLng(a['latitud'], a['longitud']),
              1,
            ))
        .toList();

    final alertasFiltradas = alertas
        .where((a) =>
            a['latitud'] != null &&
            a['longitud'] != null &&
            (tipoSeleccionado == 'Todos' || a['tipo'] == tipoSeleccionado))
        .toList();

    return Scaffold(
      backgroundColor: theme.AppColors.backgroundColor,
      appBar: AppBar(
  backgroundColor: theme.AppColors.backgroundColor,
  centerTitle: true, // ✅ centra el texto
  title: const Text(
    'Dashboard General',
    style: TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
    ),
  ),
  iconTheme: const IconThemeData(color: Colors.white),
  actions: [
    IconButton(
      onPressed: _limpiarFiltros,
      icon: const Icon(Icons.refresh, color: Colors.white),
      tooltip: 'Limpiar filtros',
    ),
  ],
),

      body: cargando
          ? const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // FILTROS
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      DropdownButton<String>(
                        dropdownColor: Colors.black,
                        value: tipoSeleccionado,
                        items: tipos
                            .map((e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(e,
                                      style:
                                          const TextStyle(color: Colors.white)),
                                ))
                            .toList(),
                        onChanged: (v) {
                          setState(() => tipoSeleccionado = v!);
                          _cargarDatos();
                        },
                      ),
                      DropdownButton<int>(
                        dropdownColor: Colors.black,
                        value: anioSeleccionado,
                        items: List.generate(3, (i) {
                          int year = DateTime.now().year - i;
                          return DropdownMenuItem(
                            value: year,
                            child: Text(year.toString(),
                                style:
                                    const TextStyle(color: Colors.white)),
                          );
                        }),
                        onChanged: (v) {
                          setState(() => anioSeleccionado = v!);
                          _cargarDatos();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // BARRAS POR TIPO
                  const Text("Alertas por tipo",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 220,
                    child: BarChart(
                      BarChartData(
  barGroups: _crearBarrasPorTipo(),
  borderData: FlBorderData(show: false),
  gridData: FlGridData(show: false),
  titlesData: FlTitlesData(
    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
    leftTitles: AxisTitles(
      sideTitles: SideTitles(showTitles: true, reservedSize: 28),
    ),
    bottomTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        getTitlesWidget: (v, _) {
          if (v <= 0 || v > alertasPorTipo.keys.length) {
            return const SizedBox.shrink();
          }
          final tipo = alertasPorTipo.keys.elementAt(v.toInt() - 1);
          return Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              tipo,
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
          );
        },
      ),
    ),
  ),
),

                    ),
                  ),

                  const SizedBox(height: 32),

                  // LÍNEAS POR MES
                  const Text("Tendencia mensual",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 220,
                    child: LineChart(
                      LineChartData(
  backgroundColor: Colors.transparent,
  gridData: FlGridData(show: false),
  borderData: FlBorderData(show: false),
  titlesData: FlTitlesData(
    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
    leftTitles: AxisTitles(
      sideTitles: SideTitles(showTitles: true, reservedSize: 28),
    ),
    bottomTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        getTitlesWidget: (v, _) {
          const meses = [
            'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
            'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
          ];
          if (v < 1 || v > 12) return const SizedBox.shrink();
          return Text(
            meses[v.toInt() - 1],
            style: const TextStyle(color: Colors.white, fontSize: 10),
          );
        },
      ),
    ),
  ),
  lineBarsData: [
    LineChartBarData(
      isCurved: true,
      spots: _crearLineasPorMes(),
      color: Colors.blueAccent,
      dotData: FlDotData(show: false),
      belowBarData: BarAreaData(show: false),
      barWidth: 3,
    ),
  ],
),

                    ),
                  ),

                  const SizedBox(height: 32),

                  // PIE CHART
                  const Text("Distribución total",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Center(
                    child: SizedBox(
                      height: 260,
                      child: PieChart(
                        PieChartData(
                          sections: _crearPieData(),
                          centerSpaceRadius: 50,
                          sectionsSpace: 2,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // 🗺️ MAPA CON HEATMAP Y POPUPS
                  const Text(
                    "Mapa de alertas en San Juan de Lurigancho",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 350,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter:
                              const LatLng(-11.9537431, -76.9820464),
                          initialZoom: 12,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                            subdomains: const ['a', 'b', 'c'],
                          ),
                          HeatMapLayer(
                            heatMapDataSource:
                                InMemoryHeatMapDataSource(data: heatPoints),
                            heatMapOptions: HeatMapOptions(radius: 20),
                          ),
                          PopupMarkerLayerWidget(
                            options: PopupMarkerLayerOptions(
                              markers: alertasFiltradas.map((a) {
                                return Marker(
                                  point:
                                      LatLng(a['latitud'], a['longitud']),
                                  width: 35,
                                  height: 35,
                                  child: Icon(
                                    Icons.location_on,
                                    color: _colorPorTipo(a['tipo'] ?? ''),
                                    size: 30,
                                  ),
                                );
                              }).toList(),
                              popupDisplayOptions: PopupDisplayOptions(
                                builder:
                                    (BuildContext context, Marker marker) {
                                  final alerta =
                                      alertasFiltradas.firstWhere(
                                    (a) =>
                                        a['latitud'] ==
                                            marker.point.latitude &&
                                        a['longitud'] ==
                                            marker.point.longitude,
                                    orElse: () => {},
                                  );

                                  if (alerta.isEmpty)
                                    return const SizedBox();

                                  final fecha = (alerta['fecha'] != null)
                                      ? (alerta['fecha'] as Timestamp)
                                          .toDate()
                                      : null;

                                  return Card(
                                    color: Colors.black.withOpacity(0.85),
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(10),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(10),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            alerta['tipo'] ?? 'Alerta',
                                            style: const TextStyle(
                                              color: Colors.orangeAccent,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            alerta['texto'] ?? '',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          if (alerta['ubicacion'] != null)
                                            Text(
                                              alerta['ubicacion'],
                                              style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 11,
                                              ),
                                            ),
                                          const SizedBox(height: 4),
                                          if (fecha != null)
                                            Text(
                                              "📅 ${fecha.day}/${fecha.month}/${fecha.year} ${fecha.hour}:${fecha.minute.toString().padLeft(2, '0')}",
                                              style: const TextStyle(
                                                color: Colors.white60,
                                                fontSize: 11,
                                              ),
                                            ),
                                          if (alerta['nombreUsuario'] != null)
                                            Text(
                                              "👤 ${alerta['nombreUsuario']}",
                                              style: const TextStyle(
                                                color: Colors.white60,
                                                fontSize: 11,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
