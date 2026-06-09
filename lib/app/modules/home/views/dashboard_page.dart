import 'dart:convert';
import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../utils/api_endpoints.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String nama = "Petugas";

  // State Loading
  bool isLoading = false;

  // State Filter
  String filterJenis = "semua";
  String filterWaktu = "minggu";

  // Data Mentah dari API
  List<dynamic> dataTerkelola = [];
  List<dynamic> dataDiserahkan = [];

  // Data Olahan untuk Grafik
  Map<String, double> pieChartData = {};
  List<double> barChartData = List.filled(7, 0.0); // 7 Hari (Senin-Minggu)
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
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Get.snackbar("Berhasil", "Anda telah logout");
    Get.offAllNamed('/login');
  }

  // ==========================================
  // 1. FETCH DATA DARI KEDUA API SEKALIGUS
  // ==========================================
  Future<void> fetchDataDariAPI() async {
    setState(() => isLoading = true);
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      final headers = {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'};

      // Panggil kedua API bersamaan agar cepat
      final responses = await Future.wait([
        http.get(Uri.parse(ApiEndpoints.sampahTerkelola), headers: headers),
        http.get(Uri.parse(ApiEndpoints.sampahDiserahkan), headers: headers),
      ]);

      if (responses[0].statusCode == 200) {
        final resTerkelola = jsonDecode(responses[0].body);
        if (resTerkelola['success'] == true) dataTerkelola = resTerkelola['data'];
      }

      if (responses[1].statusCode == 200) {
        final resDiserahkan = jsonDecode(responses[1].body);
        if (resDiserahkan['success'] == true) dataDiserahkan = resDiserahkan['data'];
      }

      // Olah data setelah di-download
      _prosesDataSesuaiFilter();

    } catch (e) {
      debugPrint("Error memuat grafik: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // ==========================================
  // 2. PARSING TANGGAL AMAN
  // ==========================================
  DateTime? _parseDateSafe(String raw) {
    if (raw.isEmpty || raw == '-') return null;
    String cleanDate = raw.split('T')[0].split(' ')[0]; // Ambil YYYY-MM-DD atau DD-MM-YYYY
    try {
      if (cleanDate.contains('-')) {
        List<String> p = cleanDate.split('-');
        if (p[0].length == 4) return DateTime.parse(cleanDate); // YYYY-MM-DD
        if (p[2].length == 4) return DateTime(int.parse(p[2]), int.parse(p[1]), int.parse(p[0])); // DD-MM-YYYY
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  // ==========================================
  // 3. LOGIKA FILTERING & MENGHITUNG GRAFIK
  // ==========================================
  void _prosesDataSesuaiFilter() {
    Map<String, double> tempPie = {};
    List<double> tempBar = List.filled(7, 0.0);
    double tempTotal = 0.0;
    DateTime now = DateTime.now();

    // Mencari batas awal dan akhir minggu ini (Senin - Minggu)
    DateTime startOfWeek = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    DateTime endOfWeek = startOfWeek.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));

    // Fungsi internal untuk memproses tiap baris data
    void olahItem(Map<String, dynamic> item, bool isTerkelola) {
      String rawDate = item[isTerkelola ? 'tgl' : 'tgl_diserahkan']?.toString() ?? '';
      DateTime? d = _parseDateSafe(rawDate);
      if (d == null) return;

      // 🔴 FILTER WAKTU
      if (filterWaktu == 'hari') {
        if (d.year != now.year || d.month != now.month || d.day != now.day) return;
      } else if (filterWaktu == 'minggu') {
        if (d.isBefore(startOfWeek) || d.isAfter(endOfWeek)) return;
      } else if (filterWaktu == 'bulan') {
        if (d.year != now.year || d.month != now.month) return;
      } else if (filterWaktu == 'tahun') {
        if (d.year != now.year) return;
      }

      double berat = double.tryParse(item['jumlah_berat'].toString()) ?? 0;
      tempTotal += berat;

      // 🟡 DATA PIE CHART (Pengelompokan: Organik Terkelola, dll)
      String kategori = item['jenis']?['kategori_jenis'] ?? 'Lainnya';
      String suffix = isTerkelola ? 'Terkelola' : 'Diserahkan';
      String pieKey = '$kategori $suffix';
      tempPie[pieKey] = (tempPie[pieKey] ?? 0) + berat;

      // 🟢 DATA BAR CHART (Pengelompokan berdasarkan Hari)
      // d.weekday mereturn 1 (Senin) s/d 7 (Minggu)
      int indeksHari = d.weekday - 1; 
      tempBar[indeksHari] += berat;
    }

    // Eksekusi filtering
    if (filterJenis == 'semua' || filterJenis == 'terkelola') {
      for (var item in dataTerkelola) { olahItem(item, true); }
    }
    if (filterJenis == 'semua' || filterJenis == 'diserahkan') {
      for (var item in dataDiserahkan) { olahItem(item, false); }
    }

    setState(() {
      pieChartData = tempPie;
      barChartData = tempBar;
      totalKeseluruhan = tempTotal;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER
          Container(
            width: double.infinity,
            color: const Color(0xFF1A3A6B),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                      child: Image.asset('assets/images/pwaste.png', height: 38, width: 38, fit: BoxFit.contain),
                    ),
                    const SizedBox(width: 10),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Dashboard Petugas", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                        Text("Aplikasi Pengelolaan Sampah", style: TextStyle(color: Colors.white70, fontSize: 10)),
                      ],
                    ),
                  ],
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    Get.defaultDialog(
                      title: "Logout", middleText: "Apakah Anda yakin ingin logout?",
                      textConfirm: "Ya", textCancel: "Batal",
                      confirmTextColor: Colors.white, buttonColor: Colors.red,
                      onConfirm: () { Get.back(); logout(); },
                    );
                  },
                  icon: const Icon(Icons.logout, size: 14, color: Colors.white),
                  label: const Text("Logout", style: TextStyle(color: Colors.white, fontSize: 12)),
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white54), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
                ),
              ],
            ),
          ),

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
                    // BANNER SELAMAT DATANG
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: const Color(0xFF1A3A6B), borderRadius: BorderRadius.circular(8)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Selamat Datang, $nama", style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text("Total Sampah Sesuai Filter: ${totalKeseluruhan.toStringAsFixed(2)} Kg", style: const TextStyle(color: Colors.white70, fontSize: 13)),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // DROPDOWN FILTER
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            isExpanded: true, // ✅ Mencegah teks kepanjangan error overflow
                            value: filterJenis,
                            items: const [
                              DropdownMenuItem(value: "semua", child: Text("Semua Sampah", style: TextStyle(fontSize: 13))),
                              DropdownMenuItem(value: "terkelola", child: Text("Sampah Terkelola", style: TextStyle(fontSize: 13))),
                              DropdownMenuItem(value: "diserahkan", child: Text("Sampah Diserahkan", style: TextStyle(fontSize: 13))),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => filterJenis = value);
                                _prosesDataSesuaiFilter(); 
                              }
                            },
                            decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            isExpanded: true, // ✅ Mencegah teks kepanjangan error overflow
                            value: filterWaktu,
                            items: const [
                              DropdownMenuItem(value: "hari", child: Text("Hari Ini", style: TextStyle(fontSize: 13))),
                              DropdownMenuItem(value: "minggu", child: Text("Minggu Ini", style: TextStyle(fontSize: 13))),
                              DropdownMenuItem(value: "bulan", child: Text("Bulan Ini", style: TextStyle(fontSize: 13))),
                              DropdownMenuItem(value: "tahun", child: Text("Tahun Ini", style: TextStyle(fontSize: 13))),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => filterWaktu = value);
                                _prosesDataSesuaiFilter(); 
                              }
                            },
                            decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // CARD GRAFIK
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
      ),
    );
  }

  // ✅ Build Card yang Fleksibel mengikuti isi kontennya
  Widget buildCard(String title, Widget chartContent) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // ✅ Card bisa melar ke bawah menyesuaikan tinggi konten
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A3A6B))),
            const SizedBox(height: 24),
            chartContent, // Konten grafik dimasukkan ke sini
          ],
        ),
      ),
    );
  }

  // ============================================
  // GRAFIK PIE CHART
  // ============================================
  Widget _buildPieChart() {
    final validData = pieChartData.entries.where((e) => e.value > 0).toList();

    if (isLoading) return const Center(child: CircularProgressIndicator(color: Color(0xFF1A3A6B)));
    if (validData.isEmpty) return const Center(child: Text("Belum ada data", style: TextStyle(color: Colors.grey)));

    // Menentukan Warna Legend
    Color getColor(String key) {
      if (key.toLowerCase().contains("organik") && !key.toLowerCase().contains("anorganik")) return Colors.green;
      if (key.toLowerCase().contains("anorganik")) return Colors.red;
      if (key.toLowerCase().contains("diserahkan") || key.toLowerCase().contains("residu")) return Colors.amber;
      return Colors.blue; 
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 200, // ✅ Kunci tinggi lingkarannya agar rapi
          child: PieChart(
            PieChartData(
              sectionsSpace: 0,
              centerSpaceRadius: 0,
              sections: validData.map((entry) {
                return PieChartSectionData(
                  color: getColor(entry.key),
                  value: entry.value,
                  title: '', // Tanpa teks di dalam pie
                  radius: 80.0,
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Legend di bawah Pie
        Wrap(
          spacing: 12,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: validData.map((e) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 12, height: 12, decoration: BoxDecoration(color: getColor(e.key), shape: BoxShape.circle)),
                const SizedBox(width: 4),
                Text(e.key, style: const TextStyle(fontSize: 10, color: Colors.black87)),
              ],
            );
          }).toList(),
        )
      ],
    );
  }

  // ============================================
  // GRAFIK BAR CHART (HARI SENIN - MINGGU)
  // ============================================
  Widget _buildBarChart() {
    bool isEmpty = barChartData.every((value) => value == 0);

    if (isLoading) return const Center(child: CircularProgressIndicator(color: Color(0xFF1A3A6B)));
    if (isEmpty) return const Center(child: Text("Belum ada data di periode ini", style: TextStyle(color: Colors.grey)));

    double maxY = barChartData.reduce(max);
    maxY = maxY + (maxY * 0.2); 
    if (maxY < 30) maxY = 30; // Min Y axis height untuk visual

    final List<String> hari = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];

    return SizedBox(
      height: 250, // ✅ Kunci tinggi grafiknya saja
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY,
          barTouchData: BarTouchData(enabled: true),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (double value, TitleMeta meta) {
                  int index = value.toInt();
                  if (index >= 0 && index < hari.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(hari[index], style: const TextStyle(fontSize: 9, color: Colors.black54)),
                    );
                  }
                  return const SizedBox.shrink();
                },
                reservedSize: 28,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  if(value % 5 != 0 && value != maxY) return const SizedBox.shrink();
                  return Text(value.toInt().toString(), style: const TextStyle(fontSize: 10, color: Colors.black54));
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade200, strokeWidth: 1),
          ),
          borderData: FlBorderData(
            show: true, 
            border: const Border(bottom: BorderSide(color: Colors.grey, width: 1), left: BorderSide(color: Colors.grey, width: 1)),
          ),
          barGroups: barChartData.asMap().entries.map((entry) {
            int index = entry.key;
            double value = entry.value;
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: value,
                  color: const Color(0xFF1A3A6B), 
                  width: 22,
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(2), topRight: Radius.circular(2)),
                )
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}