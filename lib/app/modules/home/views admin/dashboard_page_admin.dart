import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/delegasi_notif_service.dart';

import '../../../../app/utils/api_endpoints.dart';

class DashboardPageAdmin extends StatefulWidget {
  const DashboardPageAdmin({super.key});

  @override
  State<DashboardPageAdmin> createState() => _DashboardPageAdminState();
}

class _DashboardPageAdminState extends State<DashboardPageAdmin> {
  static const Color brand = Color(0xFF1A3A6B);

  bool isLoading = true;
  String? errorMsg;
  String nama = "Admin";

  List<_Row> terkelolaRows = [];
  List<_Row> diserahkanRows = [];

  final List<String> tipeOpsi = [
    "Fiscal Year",
    "Tahunan",
    "Bulanan",
    "Mingguan",
    "Harian"
  ];

  late String tmpTipe;
  late int tmpFyStart;
  late int tmpTahun;
  late int tmpBulan;
  late int tmpMinggu;
  late DateTime tmpHari;

  late String tipe;
  late int fyStart;
  late int tahun;
  late int bulan;
  late int minggu;
  late DateTime hari;

  List<Map<String, dynamic>> instansiList = [
    {"id_instansi": null, "nama_instansi": "Semua Instansi"}
  ];
  int? tmpInstansi;
  int? selectedInstansi;

  final List<String> jenisOpsi = [
    "Semua Sampah",
    "Sampah Terkelola",
    "Sampah Diserahkan"
  ];
  String jenisPie = "Semua Sampah";
  String jenisBar = "Semua Sampah";

  final NumberFormat fmt = NumberFormat('#,##0.00', 'en_US');
  final List<String> namaBulan = const [
    "Januari", "Februari", "Maret", "April", "Mei", "Juni",
    "Juli", "Agustus", "September", "Oktober", "November", "Desember"
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final defaultFyStart = now.month >= 7 ? now.year : now.year - 1;

    tipe = tmpTipe = "Fiscal Year";
    fyStart = tmpFyStart = defaultFyStart;
    tahun = tmpTahun = now.year;
    bulan = tmpBulan = now.month;
    minggu = tmpMinggu = ((now.day - 1) ~/ 7) + 1;
    hari = tmpHari = now;

    loadProfil();
    _init();
  }

  Future<void> _init() async {
    await fetchInstansi();
    await fetchData();
  }

  Future<void> loadProfil() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => nama = prefs.getString('name') ?? "Admin");
  }

  Future<void> logout() async {
    DelegasiNotifService.instance.stop(); 
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('id_user');
    await prefs.remove('name');
    await prefs.remove('login_as');
    Get.offAllNamed('/landing');
    Get.snackbar("Berhasil", "Anda telah logout");
  }

  double _toDouble(dynamic v) =>
      v == null ? 0 : (double.tryParse(v.toString()) ?? 0);

  DateTime? _parseDate(String? s) {
    if (s == null || s.isEmpty) return null;
    try {
      if (s.contains('T')) return DateTime.parse(s);
      final p = s.split('-');
      if (p.length == 3) {
        return DateTime(int.parse(p[2]), int.parse(p[1]), int.parse(p[0]));
      }
    } catch (_) {}
    return null;
  }

  Future<void> fetchInstansi() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final res = await http.get(
        Uri.parse(ApiEndpoints.masterInstansi),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final List<dynamic> data = body['data'] ?? [];
        final list = <Map<String, dynamic>>[
          {"id_instansi": null, "nama_instansi": "Semua Instansi"}
        ];
        for (final it in data) {
          list.add({
            "id_instansi": it['id_instansi'],
            "nama_instansi": it['nama_instansi'] ?? '-',
          });
        }
        setState(() => instansiList = list);
      }
    } catch (_) {}
  }

  Future<List<_Row>> _fetchAll(String url, String token, bool diserahkan) async {
    final List<_Row> rows = [];
    int page = 1;
    int lastPage = 1;
    final instansiParam =
        selectedInstansi == null ? '' : '&id_instansi=$selectedInstansi';
    do {
      final res = await http.get(
        Uri.parse('$url?per_page=1000&page=$page$instansiParam'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      if (res.statusCode == 401) throw _Unauthorized();
      if (res.statusCode != 200) {
        throw Exception('Gagal memuat data (${res.statusCode})');
      }
      final body = jsonDecode(res.body);
      final List<dynamic> items = body['data'] ?? [];
      for (final it in items) {
        if (it['id_lokasi'] == null || it['id_jenis'] == null) continue; //coba
        rows.add(_Row(
          berat: _toDouble(it['jumlah_berat']),
          kategori:
              (it['jenis']?['kategori_jenis'] ?? '').toString().toLowerCase(),
          lokasi: (it['lokasi_asal']?['nama_lokasi'] ?? 'Tidak diketahui')
              .toString(),
          tanggal: _parseDate(diserahkan ? it['tgl_diserahkan'] : it['tgl']),
        ));
      }
      lastPage = (body['last_page'] ?? 1) as int;
      page++;
    } while (page <= lastPage);
    return rows;
  }

  Future<void> fetchData({bool isRetry = false}) async {
    setState(() {
      isLoading = true;
      errorMsg = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload(); 
      final token = prefs.getString('token') ?? '';

      if (token.isEmpty && !isRetry) {
        await Future.delayed(const Duration(milliseconds: 400));
        return fetchData(isRetry: true);
      }

      terkelolaRows =
          await _fetchAll(ApiEndpoints.sampahTerkelola, token, false);
      diserahkanRows =
          await _fetchAll(ApiEndpoints.sampahDiserahkan, token, true);
      setState(() => isLoading = false);
    } on _Unauthorized {
      if (!isRetry) {
        await Future.delayed(const Duration(milliseconds: 400));
        return fetchData(isRetry: true);
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      await prefs.remove('id_user');
      await prefs.remove('name');
      await prefs.remove('login_as');
      Get.offAllNamed('/login');
      Get.snackbar("Sesi Berakhir", "Silakan login kembali.");
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMsg = e.toString();
      });
    }
  }

  void _applyFilter() {
    final perluFetch = tmpInstansi != selectedInstansi;
    setState(() {
      tipe = tmpTipe;
      fyStart = tmpFyStart;
      tahun = tmpTahun;
      bulan = tmpBulan;
      minggu = tmpMinggu;
      hari = tmpHari;
      selectedInstansi = tmpInstansi;
    });
    if (perluFetch) {
      fetchData();
    }
  }

  bool _inPeriode(DateTime? d) {
    if (d == null) return false;
    switch (tipe) {
      case "Harian":
        return d.year == hari.year &&
            d.month == hari.month &&
            d.day == hari.day;
      case "Mingguan":
        if (d.year != tahun || d.month != bulan) return false;
        final wk = ((d.day - 1) ~/ 7) + 1;
        return wk == minggu;
      case "Bulanan":
        return d.year == tahun && d.month == bulan;
      case "Tahunan":
        return d.year == tahun;
      case "Fiscal Year":
      default:
        final start = DateTime(fyStart, 7, 1);
        final end = DateTime(fyStart + 1, 7, 1);
        return !d.isBefore(start) && d.isBefore(end);
    }
  }

  List<_Row> get _filteredTerkelola =>
      terkelolaRows.where((r) => _inPeriode(r.tanggal)).toList();
  List<_Row> get _filteredDiserahkan =>
      diserahkanRows.where((r) => _inPeriode(r.tanggal)).toList();

  String get judulPeriode {
    switch (tipe) {
      case "Harian":
        return "Tanggal ${DateFormat('d MMMM yyyy').format(hari)}";
      case "Mingguan":
        final startDay = (minggu - 1) * 7 + 1;
        final lastDayOfMonth = DateTime(tahun, bulan + 1, 0).day;
        final endDay = min(startDay + 6, lastDayOfMonth);
        return "Minggu $minggu, ${startDay.toString().padLeft(2, '0')} - ${endDay.toString().padLeft(2, '0')} ${namaBulan[bulan - 1]} $tahun";
      case "Bulanan":
        return "Bulan ${namaBulan[bulan - 1]} $tahun";
      case "Tahunan":
        return "Tahun $tahun";
      case "Fiscal Year":
      default:
        return "Fiscal Year $fyStart/${fyStart + 1} (Jul $fyStart - Jun ${fyStart + 1})";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : errorMsg != null
                      ? _buildError()
                      : RefreshIndicator(
                          onRefresh: fetchData,
                          child: ListView(
                            padding: const EdgeInsets.all(12),
                            children: [
                              _buildWelcomeCard(),
                              const SizedBox(height: 12),
                              _buildJudul(),
                              const SizedBox(height: 8),
                              _buildFilterBar(),
                              const SizedBox(height: 12),
                              _buildPieCard(),
                              const SizedBox(height: 12),
                              _buildBarCard(),
                              const SizedBox(height: 12),
                              _buildRekapCard(),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Container(
      width: double.infinity,
      color: brand,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 16,
        right: 16,
        bottom: 12,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.all(4),
            child:
                Image.asset('assets/images/pwaste.png', fit: BoxFit.contain),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Dashboard Admin",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                Text("Aplikasi Pengelolaan Sampah",
                    style: TextStyle(color: Colors.white70, fontSize: 11)),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: () {
              Get.defaultDialog(
                title: "Logout",
                middleText: "Apakah Anda yakin ingin logout?",
                textConfirm: "Ya",
                textCancel: "Batal",
                confirmTextColor: Colors.white,
                buttonColor: Colors.red,
                onConfirm: () {
                  Get.back();
                  logout();
                },
              );
            },
            icon: const Icon(Icons.logout, size: 14, color: Colors.white),
            label: const Text("Logout",
                style: TextStyle(color: Colors.white, fontSize: 12)),
            style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white54)),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: brand,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        "Selamat Datang, $nama",
        style: const TextStyle(
            color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildJudul() {
    return Text("Statistik Data $judulPeriode",
        style: const TextStyle(
            fontSize: 16, fontWeight: FontWeight.bold, color: brand));
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(errorMsg ?? "Terjadi kesalahan",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey)),
          ),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: fetchData, child: const Text("Coba lagi")),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return _card(
      title: "Filter Data",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _dropdown<int?>(
            label: "Instansi",
            value: tmpInstansi,
            items: instansiList
                .map((e) => DropdownMenuItem<int?>(
                      value: e['id_instansi'] as int?,
                      child: Text(e['nama_instansi']),
                    ))
                .toList(),
            onChanged: (v) => setState(() => tmpInstansi = v),
          ),
          const SizedBox(height: 10),
          _dropdown<String>(
            label: "Tipe Periode",
            value: tmpTipe,
            items: tipeOpsi
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => tmpTipe = v);
            },
          ),
          const SizedBox(height: 10),
          ..._buildTurunan(),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _applyFilter,
              icon: const Icon(Icons.filter_alt, size: 16),
              label: const Text("Filter"),
              style: ElevatedButton.styleFrom(
                backgroundColor: brand,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTurunan() {
    final tahunOpsi = [for (int y = DateTime.now().year; y >= 2019; y--) y];

    switch (tmpTipe) {
      case "Fiscal Year":
        final fyOpsi = [
          for (int y = DateTime.now().year; y >= DateTime.now().year - 6; y--) y
        ];
        return [
          _dropdown<int>(
            label: "Fiscal Year",
            value: tmpFyStart,
            items: fyOpsi
                .map((y) => DropdownMenuItem(
                    value: y, child: Text("FY $y/${y + 1} (Jul-Jun)")))
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => tmpFyStart = v);
            },
          ),
        ];
      case "Tahunan":
        return [
          _dropdown<int>(
            label: "Tahun",
            value: tmpTahun,
            items: tahunOpsi
                .map((y) => DropdownMenuItem(value: y, child: Text("$y")))
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => tmpTahun = v);
            },
          ),
        ];
      case "Bulanan":
        return [
          Row(children: [
            Expanded(
              child: _dropdown<int>(
                label: "Bulan",
                value: tmpBulan,
                items: [
                  for (int m = 1; m <= 12; m++)
                    DropdownMenuItem(value: m, child: Text(namaBulan[m - 1]))
                ],
                onChanged: (v) {
                  if (v != null) setState(() => tmpBulan = v);
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _dropdown<int>(
                label: "Tahun",
                value: tmpTahun,
                items: tahunOpsi
                    .map((y) => DropdownMenuItem(value: y, child: Text("$y")))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => tmpTahun = v);
                },
              ),
            ),
          ]),
        ];
      case "Mingguan":
        return [
          Row(children: [
            Expanded(
              child: _dropdown<int>(
                label: "Minggu",
                value: tmpMinggu,
                items: [
                  for (int w = 1; w <= 5; w++)
                    DropdownMenuItem(value: w, child: Text("Minggu $w"))
                ],
                onChanged: (v) {
                  if (v != null) setState(() => tmpMinggu = v);
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _dropdown<int>(
                label: "Bulan",
                value: tmpBulan,
                items: [
                  for (int m = 1; m <= 12; m++)
                    DropdownMenuItem(value: m, child: Text(namaBulan[m - 1]))
                ],
                onChanged: (v) {
                  if (v != null) setState(() => tmpBulan = v);
                },
              ),
            ),
          ]),
          const SizedBox(height: 10),
          _dropdown<int>(
            label: "Tahun",
            value: tmpTahun,
            items: tahunOpsi
                .map((y) => DropdownMenuItem(value: y, child: Text("$y")))
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => tmpTahun = v);
            },
          ),
        ];
      case "Harian":
      default:
        return [
          OutlinedButton.icon(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: tmpHari,
                firstDate: DateTime(2019),
                lastDate: DateTime(2030),
              );
              if (picked != null) setState(() => tmpHari = picked);
            },
            icon: const Icon(Icons.calendar_today, size: 14),
            label: Text(DateFormat('dd/MM/yyyy').format(tmpHari)),
          ),
        ];
    }
  }

  Widget _buildPieCard() {
    final t = _filteredTerkelola;
    final d = _filteredDiserahkan;
    double organik = 0, anorganik = 0, residu = 0;
    final pakaiTerkelola = jenisPie != "Sampah Diserahkan";
    final pakaiDiserahkan = jenisPie != "Sampah Terkelola";

    if (pakaiTerkelola) {
      for (final r in t) {
        if (r.kategori == 'organik') organik += r.berat;
        if (r.kategori == 'anorganik') anorganik += r.berat;
        if (r.kategori == 'residu') residu += r.berat;
      }
    }
    if (pakaiDiserahkan) {
      for (final r in d) {
        if (r.kategori == 'organik') organik += r.berat;
        if (r.kategori == 'anorganik') anorganik += r.berat;
        if (r.kategori == 'residu') residu += r.berat;
      }
    }

    final slices = [
      _Slice("Organik", organik, Colors.red),
      _Slice("Anorganik", anorganik, Colors.green),
      _Slice("Residu", residu, Colors.amber),
    ];
    final total = organik + anorganik + residu;

    return _card(
      title: "Distribusi Jenis Sampah",
      trailing: _miniDropdown(jenisPie, (v) => setState(() => jenisPie = v!)),
      child: total == 0
          ? _empty()
          : Column(
              children: [
                SizedBox(
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: slices
                          .where((s) => s.value > 0)
                          .map((s) => PieChartSectionData(
                                value: s.value,
                                color: s.color,
                                title:
                                    "${(s.value / total * 100).toStringAsFixed(1)}%",
                                radius: 60,
                                titleStyle: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ))
                          .toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ...slices.map((s) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Container(width: 12, height: 12, color: s.color),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Text(
                                  "${s.label} (${(s.value / total * 100).toStringAsFixed(2)}%)",
                                  style: const TextStyle(fontSize: 12))),
                          Text("${fmt.format(s.value)} kg",
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    )),
              ],
            ),
    );
  }

  Widget _buildBarCard() {
    final Map<String, double> totalLokasi = {};
    final pakaiTerkelola = jenisBar != "Sampah Diserahkan";
    final pakaiDiserahkan = jenisBar != "Sampah Terkelola";

    if (pakaiTerkelola) {
      for (final r in _filteredTerkelola) {
        totalLokasi[r.lokasi] = (totalLokasi[r.lokasi] ?? 0) + r.berat;
      }
    }
    if (pakaiDiserahkan) {
      for (final r in _filteredDiserahkan) {
        totalLokasi[r.lokasi] = (totalLokasi[r.lokasi] ?? 0) + r.berat;
      }
    }

    final lokasiList = totalLokasi.keys.toList();
    final totals = lokasiList.map((l) => totalLokasi[l]!).toList();
    final maxY = totals.isEmpty ? 0.0 : totals.reduce(max);

    return _card(
      title: "Total Sampah per Lokasi",
      trailing: _miniDropdown(jenisBar, (v) => setState(() => jenisBar = v!)),
      child: lokasiList.isEmpty
          ? _empty()
          : SizedBox(
              height: 260,
              child: BarChart(
                BarChartData(
                  maxY: maxY * 1.15,
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles:
                          SideTitles(showTitles: true, reservedSize: 44),
                    ),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 60,
                        getTitlesWidget: (value, meta) {
                          final i = value.toInt();
                          if (i < 0 || i >= lokasiList.length) {
                            return const SizedBox();
                          }
                          final name = lokasiList[i];
                          final short = name.length > 10
                              ? '${name.substring(0, 10)}…'
                              : name;
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Transform.rotate(
                              angle: -0.5,
                              child: Text(short,
                                  style: const TextStyle(fontSize: 9)),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  gridData: const FlGridData(show: true),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    for (int i = 0; i < lokasiList.length; i++)
                      BarChartGroupData(x: i, barRods: [
                        BarChartRodData(
                          toY: totals[i],
                          color: brand,
                          width: 16,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(3)),
                        ),
                      ]),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildRekapCard() {
    final Map<String, Map<String, double>> rekap = {};
    for (final r in _filteredTerkelola) {
      rekap.putIfAbsent(r.lokasi, () => {'t': 0, 'd': 0});
      rekap[r.lokasi]!['t'] = rekap[r.lokasi]!['t']! + r.berat;
    }
    for (final r in _filteredDiserahkan) {
      rekap.putIfAbsent(r.lokasi, () => {'t': 0, 'd': 0});
      rekap[r.lokasi]!['d'] = rekap[r.lokasi]!['d']! + r.berat;
    }

    final lokasiList = rekap.keys.toList();
    double totT = 0, totD = 0;
    for (final l in lokasiList) {
      totT += rekap[l]!['t']!;
      totD += rekap[l]!['d']!;
    }
    final grand = totT + totD;

    String pct(double part, double whole) =>
        whole == 0 ? "0%" : "${(part / whole * 100).toStringAsFixed(2)}%";

    return _card(
      title: "Rekap Neraca Pengelolaan Sampah",
      child: lokasiList.isEmpty
          ? _empty()
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor:
                    WidgetStateProperty.all(brand.withValues(alpha: 0.08)),
                columnSpacing: 18,
                columns: const [
                  DataColumn(label: Text("Lokasi")),
                  DataColumn(label: Text("Terkelola (kg)")),
                  DataColumn(label: Text("% Terkelola")),
                  DataColumn(label: Text("Diserahkan (kg)")),
                  DataColumn(label: Text("% Diserahkan")),
                  DataColumn(label: Text("Total (kg)")),
                ],
                rows: [
                  ...lokasiList.map((l) {
                    final t = rekap[l]!['t']!;
                    final d = rekap[l]!['d']!;
                    final tot = t + d;
                    return DataRow(cells: [
                      DataCell(Text(l)),
                      DataCell(Text(fmt.format(t))),
                      DataCell(Text(pct(t, tot))),
                      DataCell(Text(fmt.format(d))),
                      DataCell(Text(pct(d, tot))),
                      DataCell(Text(fmt.format(tot))),
                    ]);
                  }),
                  DataRow(
                    color: WidgetStateProperty.all(
                        brand.withValues(alpha: 0.05)),
                    cells: [
                      const DataCell(Text("Total",
                          style: TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text(fmt.format(totT),
                          style:
                              const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text(pct(totT, grand),
                          style:
                              const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text(fmt.format(totD),
                          style:
                              const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text(pct(totD, grand),
                          style:
                              const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text(fmt.format(grand),
                          style:
                              const TextStyle(fontWeight: FontWeight.bold))),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _empty() => const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: Text("Belum ada data untuk filter ini")),
      );

  Widget _miniDropdown(String value, ValueChanged<String?> onChanged) {
    return DropdownButton<String>(
      value: value,
      isDense: true,
      underline: const SizedBox(),
      style: const TextStyle(fontSize: 11, color: Colors.black87),
      items: jenisOpsi
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _dropdown<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          isDense: true,
          style: const TextStyle(fontSize: 12, color: Colors.black87),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _card(
      {required String title, required Widget child, Widget? trailing}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(title,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: brand)),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _Row {
  final double berat;
  final String kategori;
  final String lokasi;
  final DateTime? tanggal;
  _Row(
      {required this.berat,
      required this.kategori,
      required this.lokasi,
      required this.tanggal});
}

class _Slice {
  final String label;
  final double value;
  final Color color;
  _Slice(this.label, this.value, this.color);
}

class _Unauthorized implements Exception {}