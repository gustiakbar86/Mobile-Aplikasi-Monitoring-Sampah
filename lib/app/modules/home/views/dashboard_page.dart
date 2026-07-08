import 'dart:convert';
import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/delegasi_notif_service.dart';

import '../../../utils/api_endpoints.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String nama = "Petugas";

  bool isLoading = false;

  // Filter: 3 pilihan saja
  String filterJenis = "semua";
  String filterWaktu = "minggu"; // hari | minggu | bulan

  List<dynamic> dataTerkelola = [];
  List<dynamic> dataDiserahkan = [];

  Map<String, double> pieChartData = {};
  List<double> barChartData = List.filled(7, 0.0); // selalu 7 (Senin-Minggu)
  double totalKeseluruhan = 0.0;

  @override
  void initState() {
    super.initState();
    loadNama();
    fetchDataDariAPI();
  }

  Future<void> loadNama() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      nama = prefs.getString('name') ?? "Petugas";
    });
  }

  Future<void> logout() async {
    DelegasiNotifService.instance.stop();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Get.snackbar("Berhasil", "Anda telah logout");
    Get.offAllNamed('/landing');
  }

  Future<void> fetchDataDariAPI() async {
    setState(() => isLoading = true);
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

      final responses = await Future.wait([
        http.get(Uri.parse(ApiEndpoints.sampahTerkelola), headers: headers),
        http.get(Uri.parse(ApiEndpoints.sampahDiserahkan), headers: headers),
      ]);

      if (responses[0].statusCode == 200) {
        final res = jsonDecode(responses[0].body);
        if (res['success'] == true) dataTerkelola = res['data'];
      }
      if (responses[1].statusCode == 200) {
        final res = jsonDecode(responses[1].body);
        if (res['success'] == true) dataDiserahkan = res['data'];
      }

      _prosesDataSesuaiFilter();
    } catch (e) {
      debugPrint("Error memuat grafik: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // Bar chart dinamis:
  // - hari/minggu → 7 bucket (Senin-Minggu)
  // - bulan       → 4 bucket (Minggu 1-4)
  int get _jumlahBucket => filterWaktu == 'bulan' ? 4 : 7;

  List<String> get _labelBucket => filterWaktu == 'bulan'
      ? ['Minggu \n1', 'Minggu \n2', 'Minggu \n3', 'Minggu \n4']
      : ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];

  int _bucketIndex(DateTime d) {
    if (filterWaktu == 'bulan') {
      return ((d.day - 1) ~/ 7).clamp(0, 3); // 0=Minggu1 … 3=Minggu4
    }
    return d.weekday - 1; // 0=Senin … 6=Minggu
  }

  DateTime? _parseDateSafe(String raw) {
    if (raw.isEmpty || raw == '-') return null;
    final cleanDate = raw.split('T')[0].split(' ')[0];
    try {
      if (cleanDate.contains('-')) {
        final p = cleanDate.split('-');
        if (p[0].length == 4) return DateTime.parse(cleanDate);       // YYYY-MM-DD
        if (p[2].length == 4) return DateTime(                        // DD-MM-YYYY
          int.parse(p[2]), int.parse(p[1]), int.parse(p[0]));
      }
    } catch (_) {}
    return null;
  }

  void _prosesDataSesuaiFilter() {
    Map<String, double> tempPie = {};
    List<double> tempBar = List.filled(7, 0.0); // Senin(0)..Minggu(6)
    double tempTotal = 0.0;
    final now = DateTime.now();

    // Batas minggu berjalan (Senin s.d. Minggu)
    final startOfWeek = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek
        .add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));

    // Batas bulan berjalan (hari pertama s.d. terakhir)
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth   = DateTime(now.year, now.month + 1, 1)
        .subtract(const Duration(seconds: 1));

    void olahItem(Map<String, dynamic> item, bool isTerkelola) {
      // Skip data delegasi yang belum dilengkapi petugas
      if (item['id_lokasi'] == null || item['id_jenis'] == null) return;

      final rawDate =
          item[isTerkelola ? 'tgl' : 'tgl_diserahkan']?.toString() ?? '';
      final DateTime? d = _parseDateSafe(rawDate);
      if (d == null) return;

      // ── Filter waktu ─────────────────────────────────────────────────
      switch (filterWaktu) {
        case 'hari':
          if (d.year != now.year || d.month != now.month || d.day != now.day)
            return;
          break;
        case 'minggu':
          if (d.isBefore(startOfWeek) || d.isAfter(endOfWeek)) return;
          break;
        case 'bulan':
          if (d.isBefore(startOfMonth) || d.isAfter(endOfMonth)) return;
          break;
      }

      final berat = double.tryParse(item['jumlah_berat'].toString()) ?? 0;
      tempTotal += berat;

      // ── Pie chart ────────────────────────────────────────────────────
      final kategori = item['jenis']?['kategori_jenis'] ?? 'Lainnya';
      final suffix   = isTerkelola ? 'Terkelola' : 'Diserahkan';
      final pieKey   = '$kategori $suffix';
      tempPie[pieKey] = (tempPie[pieKey] ?? 0) + berat;

      // ── Bar chart (bucket dinamis: hari/minggu=per hari, bulan=per minggu)
      final idx = _bucketIndex(d);
      if (idx >= 0 && idx < tempBar.length) tempBar[idx] += berat;
    }

    if (filterJenis == 'semua' || filterJenis == 'terkelola') {
      for (final item in dataTerkelola) olahItem(item, true);
    }
    if (filterJenis == 'semua' || filterJenis == 'diserahkan') {
      for (final item in dataDiserahkan) olahItem(item, false);
    }

    setState(() {
      pieChartData     = tempPie;
      barChartData     = tempBar;
      totalKeseluruhan = tempTotal;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ───────────────────────────────────────────────────────
        Container(
          width: double.infinity,
          color: const Color(0xFF1A3A6B),
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 12,
            bottom: 12, left: 16, right: 16,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8)),
                  child: Image.asset('assets/images/pwaste.png',
                      height: 38, width: 38, fit: BoxFit.contain),
                ),
                const SizedBox(width: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Dashboard Petugas",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold)),
                    Text("Aplikasi Pengelolaan Sampah",
                        style: TextStyle(color: Colors.white70, fontSize: 10)),
                  ],
                ),
              ]),
              OutlinedButton.icon(
                onPressed: () {
                  Get.defaultDialog(
                    title: "Logout",
                    middleText: "Apakah Anda yakin ingin logout?",
                    textConfirm: "Ya", textCancel: "Batal",
                    confirmTextColor: Colors.white, buttonColor: Colors.red,
                    onConfirm: () { Get.back(); logout(); },
                  );
                },
                icon: const Icon(Icons.logout, size: 14, color: Colors.white),
                label: const Text("Logout",
                    style: TextStyle(color: Colors.white, fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white54),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
              ),
            ],
          ),
        ),

        // ── Body ─────────────────────────────────────────────────────────
        Expanded(
          child: RefreshIndicator(
            onRefresh: fetchDataDariAPI,
            color: const Color(0xFF1A3A6B),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: const Color(0xFF1A3A6B),
                        borderRadius: BorderRadius.circular(8)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Selamat Datang, $nama",
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(
                            "Total Sampah Sesuai Filter: "
                            "${totalKeseluruhan.toStringAsFixed(2)} Kg",
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Filter row ───────────────────────────────────────
                  Row(children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: filterJenis,
                        items: const [
                          DropdownMenuItem(value: "semua",      child: Text("Semua Sampah",      style: TextStyle(fontSize: 13))),
                          DropdownMenuItem(value: "terkelola",  child: Text("Sampah Terkelola",  style: TextStyle(fontSize: 13))),
                          DropdownMenuItem(value: "diserahkan", child: Text("Sampah Diserahkan", style: TextStyle(fontSize: 13))),
                        ],
                        onChanged: (v) {
                          if (v != null) {
                            setState(() => filterJenis = v);
                            _prosesDataSesuaiFilter();
                          }
                        },
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: filterWaktu,
                        // 3 pilihan saja: Hari Ini, Minggu Ini, Bulan Ini
                        items: const [
                          DropdownMenuItem(value: "hari",  child: Text("Hari Ini",   style: TextStyle(fontSize: 13))),
                          DropdownMenuItem(value: "minggu",child: Text("Minggu Ini", style: TextStyle(fontSize: 13))),
                          DropdownMenuItem(value: "bulan", child: Text("Bulan Ini",  style: TextStyle(fontSize: 13))),
                        ],
                        onChanged: (v) {
                          if (v != null) {
                            setState(() => filterWaktu = v);
                            _prosesDataSesuaiFilter();
                          }
                        },
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ),
                  ]),

                  const SizedBox(height: 20),

                  buildCard("Distribusi Jenis Sampah", _buildPieChart()),
                  const SizedBox(height: 16),
                  buildCard("Trend Berat Sampah", _buildBarChart()),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildCard(String title, Widget chartContent) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A3A6B))),
            const SizedBox(height: 24),
            chartContent,
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart() {
    final validData =
        pieChartData.entries.where((e) => e.value > 0).toList();

    if (isLoading)
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF1A3A6B)));
    if (validData.isEmpty)
      return const Center(
          child: Text("Belum ada data", style: TextStyle(color: Colors.grey)));

    Color getColor(String key) {
      final k = key.toLowerCase();
      if (k.contains("organik") && !k.contains("anorganik"))
        return Colors.green;
      if (k.contains("anorganik")) return Colors.red;
      if (k.contains("residu") || k.contains("diserahkan"))
        return Colors.amber;
      return Colors.blue;
    }

    final total = validData.fold(0.0, (s, e) => s + e.value);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sectionsSpace: 0,
              centerSpaceRadius: 0,
              sections: validData.map((e) {
                final pct = total > 0 ? e.value / total * 100 : 0;
                return PieChartSectionData(
                  color: getColor(e.key),
                  value: e.value,
                  title: '${pct.toStringAsFixed(1)}%',
                  radius: 80,
                  titleStyle: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: validData.map((e) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                        color: getColor(e.key), shape: BoxShape.circle)),
                const SizedBox(width: 4),
                Text('${e.key} (${e.value.toStringAsFixed(2)} kg)',
                    style:
                        const TextStyle(fontSize: 10, color: Colors.black87)),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBarChart() {
    final isEmpty = barChartData.every((v) => v == 0);

    if (isLoading)
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF1A3A6B)));
    if (isEmpty)
      return const Center(
          child: Text("Belum ada data di periode ini",
              style: TextStyle(color: Colors.grey)));

    double maxY = barChartData.reduce(max) * 1.2;
    if (maxY < 10) maxY = 10;

    final labels = _labelBucket;

    return SizedBox(
      height: 250,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                '${labels[group.x]}\n${rod.toY.toStringAsFixed(2)} kg',
                const TextStyle(color: Colors.white, fontSize: 11),
              ),
            ),
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, _) {
                  final i = value.toInt();
                  if (i < 0 || i >= labels.length) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      labels[i],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 9, color: Colors.black54),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, _) {
                  if (value % 5 != 0) return const SizedBox();
                  return Text(value.toInt().toString(),
                      style: const TextStyle(
                          fontSize: 10, color: Colors.black54));
                },
              ),
            ),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (v) =>
                FlLine(color: Colors.grey.shade200, strokeWidth: 1),
          ),
          borderData: FlBorderData(
            show: true,
            border: const Border(
              bottom: BorderSide(color: Colors.grey, width: 1),
              left: BorderSide(color: Colors.grey, width: 1),
            ),
          ),
          barGroups: barChartData.asMap().entries.map((e) {
            return BarChartGroupData(x: e.key, barRods: [
              BarChartRodData(
                toY: e.value,
                color: const Color(0xFF1A3A6B),
                width: filterWaktu == 'bulan' ? 32 : 22,
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(2),
                    topRight: Radius.circular(2)),
              ),
            ]);
          }).toList(),
        ),
      ),
    );
  }
}