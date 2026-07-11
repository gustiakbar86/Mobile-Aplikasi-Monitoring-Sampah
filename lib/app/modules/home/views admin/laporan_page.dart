import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../app/utils/api_endpoints.dart';

class LaporanPage extends StatefulWidget {
  const LaporanPage({super.key});

  @override
  State<LaporanPage> createState() => _LaporanPageState();
}

class _LaporanPageState extends State<LaporanPage> {
  static const Color brand = Color(0xFF1A3A6B);
  String get _baseLaporan => ApiEndpoints.sampahTerkelola
      .replaceFirst(RegExp(r'/sampah-terkelola/?$'), '/laporan-pengunjung');

  bool isLoading = true;
  String? errorMsg;
  List<dynamic> laporan = [];

  int currentPage = 1;
  int lastPage = 1;
  int total = 0;
  final int perPage = 10;

  String? statusFilter; // null = semua
  final List<Map<String, String?>> statusOpsi = const [
    {"label": "-- Semua Status --", "value": null},
    {"label": "Menunggu Delegasi", "value": "Menunggu Delegasi"},
    {"label": "Didelegasikan", "value": "Didelegasikan"},
    {"label": "Selesai", "value": "Selesai"},
  ];

  final TextEditingController searchC = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    fetchLaporan();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    searchC.dispose();
    super.dispose();
  }

  Future<String> _token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? '';
  }

  // Fetch laporan
  Future<void> fetchLaporan({int page = 1}) async {
    if (mounted) setState(() { isLoading = true; errorMsg = null; });
    try {
      final q = searchC.text.trim();
      final params = <String, String>{
        'page': '$page',
        'per_page': '$perPage',
        if (statusFilter != null && statusFilter!.isNotEmpty) 'status': statusFilter!,
        if (q.isNotEmpty) 'search': q,
      };
      final uri = Uri.parse(_baseLaporan).replace(queryParameters: params);

      final res = await http.get(
        uri,
        headers: {'Authorization': 'Bearer ${await _token()}', 'Accept': 'application/json'},
      );

      if (res.statusCode == 401) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        Get.offAllNamed('/login');
        return;
      }
      if (res.statusCode != 200) {
        throw Exception('Gagal memuat data (${res.statusCode})');
      }

      final body = jsonDecode(res.body);
      if (!mounted) return;
      setState(() {
        laporan     = body['data'] ?? [];
        total       = body['total'] ?? 0;
        lastPage    = body['last_page'] ?? 1;
        currentPage = body['current_page'] ?? 1;
        isLoading   = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        errorMsg = e.toString();
      });
    }
  }

  void _onSearch(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () => fetchLaporan(page: 1));
  }

  String _fmtTanggal(dynamic raw) {
    if (raw == null) return '-';
    final s = raw.toString();
    try {
      final d = DateTime.parse(s).toLocal();
      return DateFormat('dd/MM/yyyy HH:mm').format(d);
    } catch (_) {
      return s;
    }
  }

  bool _belumDidelegasikan(String status) =>
      status != 'Didelegasikan' && status != 'Selesai';

    Color _statusColor(String status) {
    final s = status.toLowerCase().trim();
    
    if (s.contains('selesai')) {
      return Colors.green;
    }
    
    if (s.contains('didelegasikan')) {
      return const Color(0xFFFFB300);
    }
    return Colors.grey.shade600; 
  }

  void _previewFoto(String url) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: InteractiveViewer(
              child: Image.network(url, fit: BoxFit.contain, width: double.infinity,
                errorBuilder: (_, __, ___) => Container(
                  height: 300, color: Colors.black,
                  child: const Center(
                      child: Icon(Icons.broken_image, color: Colors.white, size: 48)),
                ),
              ),
            ),
          ),
          Positioned(
            top: 8, right: 8,
            child: GestureDetector(
              onTap: () => Get.back(),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                child: const Icon(Icons.close, color: Colors.white, size: 20),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Future<void> _bukaMaps(String lat, String lng) async {
    final la = lat.trim();
    final ln = lng.trim();
    if (la.isEmpty || ln.isEmpty || la == '-' || ln == '-') {
      Get.snackbar("Koordinat tidak valid", "Titik lokasi tidak tersedia",
          backgroundColor: Colors.orange, colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(12));
      return;
    }

    final webUri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$la,$ln');
    final geoUri = Uri.parse('geo:$la,$ln?q=$la,$ln');

    try {
      if (await canLaunchUrl(webUri)) {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
        return;
      }
      await launchUrl(geoUri, mode: LaunchMode.externalApplication);
    } catch (_) {
      Clipboard.setData(ClipboardData(text: '$la, $ln'));
      Get.snackbar("Tidak bisa membuka peta", "Koordinat disalin: $la, $ln",
          backgroundColor: brand, colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(12));
    }
  }

  Future<void> _hapus(int id, String pelapor) async {
    final ok = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.orange, width: 3)),
            child: const Icon(Icons.priority_high, color: Colors.orange, size: 36),
          ),
          const SizedBox(height: 16),
          const Text("Apakah anda yakin?", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text("Hapus laporan dari $pelapor?",
              textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54)),
        ]),
        actions: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            ElevatedButton(
              onPressed: () => Get.back(result: true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              child: const Text("Ya, hapus!"),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: () => Get.back(result: false),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.grey, foregroundColor: Colors.white),
              child: const Text("Batal"),
            ),
          ]),
        ],
      ),
    );
    if (ok != true) return;

    try {
      final res = await http.delete(
        Uri.parse('$_baseLaporan/$id'),
        headers: {'Authorization': 'Bearer ${await _token()}', 'Accept': 'application/json'},
      );
      final r = jsonDecode(res.body);
      if (res.statusCode == 200 && r['success'] == true) {
        Get.snackbar("Berhasil", r['message'] ?? "Laporan dihapus",
            backgroundColor: Colors.green, colorText: Colors.white);
        fetchLaporan(page: currentPage);
      } else {
        Get.snackbar("Gagal", r['message'] ?? "Gagal menghapus",
            backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar("Error", e.toString(), backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  // Delegasi
  Future<List<Map<String, dynamic>>> _fetchPetugas() async {
    try {
      final res = await http.get(
        Uri.parse('${ApiEndpoints.petugas}?per_page=100'),
        headers: {'Authorization': 'Bearer ${await _token()}', 'Accept': 'application/json'},
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final List data = body['data'] ?? [];
        return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    } catch (_) {}
    return [];
  }

  void _delegasi(Map<String, dynamic> item) async {
    final petugasList = await _fetchPetugas();
    int? selectedPetugas;
    String? jenisDelegasi; // terkelola / diserahkan
    bool loading = false;

    Get.bottomSheet(
      isScrollControlled: true,
      StatefulBuilder(builder: (context, setSheet) {
        return Container(
          padding: EdgeInsets.only(
            left: 16, right: 16, top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Delegasi Laporan",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: brand)),
                    IconButton(onPressed: () => Get.back(), icon: const Icon(Icons.close)),
                  ],
                ),
                const Divider(),

                // Info laporan
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F4F7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Pelapor: ${item['nama_pelapor'] ?? '-'}",
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text("Titik: ${item['latitude'] ?? '-'}, ${item['longitude'] ?? '-'}",
                          style: const TextStyle(fontSize: 12, color: Colors.black54)),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                const Text("Pilih Petugas *",
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                _kotak(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: selectedPetugas,
                      isExpanded: true,
                      hint: Text("-- Pilih Petugas --",
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                      items: petugasList.map((e) {
                        final label = "${e['nama_instansi'] ?? '-'} - ${e['name'] ?? '-'}";
                        return DropdownMenuItem<int>(
                          value: e['id'] is int ? e['id'] : int.tryParse('${e['id']}'),
                          child: Text(label, style: const TextStyle(fontSize: 13)),
                        );
                      }).toList(),
                      onChanged: (v) => setSheet(() => selectedPetugas = v),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                const Text("Jenis Delegasi *",
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                _kotak(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: jenisDelegasi,
                      isExpanded: true,
                      hint: Text("-- Pilih Jenis --",
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                      items: const [
                        DropdownMenuItem(value: "terkelola",
                            child: Text("Terkelola (Organik/Anorganik)", style: TextStyle(fontSize: 13))),
                        DropdownMenuItem(value: "diserahkan",
                            child: Text("Diserahkan (Residu)", style: TextStyle(fontSize: 13))),
                      ],
                      onChanged: (v) => setSheet(() => jenisDelegasi = v),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Petugas akan menerima tugas di menu Riwayat Inputan, lalu melengkapi data sampah. Status otomatis menjadi Selesai setelah diisi.",
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity, height: 44,
                  child: ElevatedButton.icon(
                    onPressed: loading ? null : () async {
                      if (selectedPetugas == null || jenisDelegasi == null) {
                        Get.snackbar("Peringatan", "Petugas dan jenis delegasi wajib dipilih",
                            backgroundColor: Colors.orange, colorText: Colors.white);
                        return;
                      }
                      setSheet(() => loading = true);
                      final berhasil = await _kirimDelegasi(
                        id: item['id'] is int ? item['id'] : int.tryParse('${item['id']}') ?? 0,
                        idPetugas: selectedPetugas!,
                        jenis: jenisDelegasi!,
                      );
                      setSheet(() => loading = false);
                      if (berhasil) {
                        Get.back(); // tutup bottom sheet dulu
                        fetchLaporan(page: currentPage);
                        // Beri jeda singkat agar sheet selesai menutup,
                        // baru tampilkan alert sukses. Tanpa jeda ini,
                        // alert bisa ikut tertutup oleh animasi sheet.
                        await Future.delayed(const Duration(milliseconds: 250));
                        _alertBerhasilDelegasi();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brand,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: loading
                        ? const SizedBox(width: 16, height: 16,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.person_add_alt_1, color: Colors.white, size: 18),
                    label: Text(loading ? "Memproses..." : "Delegasikan",
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      }),
    );
  }

  Future<bool> _kirimDelegasi({
    required int id,
    required int idPetugas,
    required String jenis,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseLaporan/$id/delegasi'),
        headers: {
          'Authorization': 'Bearer ${await _token()}',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'id_petugas': idPetugas, 'jenis_delegasi': jenis}),
      );
      final r = jsonDecode(res.body);
      if ((res.statusCode == 200) && r['success'] == true) {
        // Alert sukses TIDAK ditampilkan di sini, melainkan setelah
        // bottom sheet ditutup (lihat _alertBerhasilDelegasi). Bila
        // ditampilkan di sini, snackbar akan ikut tertutup oleh
        // Get.back() yang menutup sheet, sehingga admin tidak
        // pernah melihat notifikasinya.
        return true;
      } else {
        Get.snackbar("Gagal", r['message'] ?? "Gagal mendelegasikan",
            backgroundColor: Colors.red, colorText: Colors.white);
        return false;
      }
    } catch (e) {
      Get.snackbar("Error", e.toString(), backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }
  }

  /// Dialog sukses (gaya SweetAlert) yang ditampilkan SETELAH bottom
  /// sheet delegasi tertutup, agar tidak ikut hilang bersama sheet.
  void _alertBerhasilDelegasi() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.green, width: 3),
            ),
            child: const Icon(Icons.check, color: Colors.green, size: 36),
          ),
          const SizedBox(height: 16),
          const Text("Berhasil!",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text(
            "Laporan berhasil didelegasikan.\nPetugas akan menerima tugas di menu Riwayat Inputan.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54),
          ),
        ]),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () => Get.back(),
              style: ElevatedButton.styleFrom(
                backgroundColor: brand, foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32),
              ),
              child: const Text("OK"),
            ),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Column(
        children: [
          // Header
          AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle.light,
            child: Container(
              width: double.infinity,
              color: brand,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 12,
                left: 16, right: 16, bottom: 12,
              ),
              child: const Text("Laporan Pengunjung",
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),

          // Filter pencarian
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Column(children: [
              _kotak(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    value: statusFilter,
                    isExpanded: true,
                    items: statusOpsi
                        .map((e) => DropdownMenuItem<String?>(
                              value: e['value'],
                              child: Text(e['label']!, style: const TextStyle(fontSize: 13)),
                            ))
                        .toList(),
                    onChanged: (v) {
                      setState(() => statusFilter = v);
                      fetchLaporan(page: 1);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: searchC,
                onChanged: _onSearch,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: "Cari nama pelapor...",
                  hintStyle: const TextStyle(fontSize: 13),
                  isDense: true,
                  prefixIcon: const Icon(Icons.search, size: 18),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ]),
          ),

          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: brand))
                : errorMsg != null
                    ? _buildError()
                    : RefreshIndicator(
                        color: brand,
                        onRefresh: () => fetchLaporan(page: currentPage),
                        child: laporan.isEmpty
                            ? ListView(children: const [
                                SizedBox(height: 240),
                                Center(child: Text("Tidak ada laporan")),
                              ])
                            : ListView.builder(
                                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                                itemCount: laporan.length,
                                itemBuilder: (c, i) => _kartu(laporan[i]),
                              ),
                      ),
          ),

          if (!isLoading && errorMsg == null && lastPage > 1)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: currentPage > 1 ? () => fetchLaporan(page: currentPage - 1) : null,
                    child: const Text("Sebelumnya"),
                  ),
                  Text("$currentPage / $lastPage",
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: currentPage < lastPage ? () => fetchLaporan(page: currentPage + 1) : null,
                    child: const Text("Selanjutnya"),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(errorMsg ?? "Terjadi kesalahan",
                textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
          ),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: () => fetchLaporan(), child: const Text("Coba lagi")),
        ],
      ),
    );
  }

  // Kartu satu laporan
  Widget _kartu(Map<String, dynamic> item) {
    final status = '${item['status'] ?? '-'}';
    final belum = _belumDidelegasikan(status);
    final fotoUrl = item['foto_url'];
    final lat = '${item['latitude'] ?? '-'}';
    final lng = '${item['longitude'] ?? '-'}';
    final petugasNama = item['nama_petugas'];
    final petugasInstansi = item['nama_instansi'];
    final jenis = item['jenis_delegasi'];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Foto
              GestureDetector(
                onTap: fotoUrl != null ? () => _previewFoto(fotoUrl) : null,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: fotoUrl != null
                      ? Image.network(fotoUrl, width: 60, height: 60, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _fotoKosong())
                      : _fotoKosong(),
                ),
              ),
              const SizedBox(width: 12),
              // Info utama
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['nama_pelapor'] ?? '-',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: brand)),
                    const SizedBox(height: 4),
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _statusColor(status),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(status,
                          style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
              // Waktu lapor
              Text(_fmtTanggal(item['created_at']),
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
            ],
          ),
          const SizedBox(height: 10),

          // Koordinat
          Row(children: [
            const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
            const SizedBox(width: 4),
            Expanded(
              child: Text("$lat, $lng",
                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            GestureDetector(
              onTap: () => _bukaMaps(lat, lng),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: brand),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.map_outlined, size: 13, color: brand),
                  SizedBox(width: 4),
                  Text("Lihat Peta", style: TextStyle(fontSize: 11, color: brand, fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
          ]),

          if (petugasNama != null) ...[
            const SizedBox(height: 6),
            Row(children: [
              const Icon(Icons.badge_outlined, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  "${petugasInstansi ?? '-'} - $petugasNama"
                  "${jenis != null ? '  ·  $jenis' : ''}",
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
              ),
            ]),
          ],

          if (belum) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _delegasi(item),
                  icon: const Icon(Icons.person_add_alt_1, size: 14),
                  label: const Text("Delegasi"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brand, foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    final id = item['id'] is int ? item['id'] : int.tryParse('${item['id']}') ?? 0;
                    _hapus(id, item['nama_pelapor'] ?? '-');
                  },
                  icon: const Icon(Icons.delete, size: 14),
                  label: const Text("Hapus"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red, foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _fotoKosong() => Container(
        width: 60, height: 60, color: Colors.grey.shade200,
        child: const Icon(Icons.image_not_supported_outlined, size: 22, color: Colors.grey),
      );

  Widget _kotak({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(8),
          color: Colors.white,
        ),
        child: child,
      );
}