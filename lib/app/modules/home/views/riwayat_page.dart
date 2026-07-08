import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../utils/api_endpoints.dart';

// =========================
// MODEL SAMPAH TERKELOLA
// =========================
class SampahTerkelola {
  final int id;
  final int idLokasi;
  final int idJenis;
  final String tanggal;
  final String lokasiAsal;
  final String jenisSampah;
  final String kategoriJenis;
  final double beratKg;
  final String? alasanEdit;
  final String? foto;

  SampahTerkelola({
    required this.id,
    required this.idLokasi,
    required this.idJenis,
    required this.tanggal,
    required this.lokasiAsal,
    required this.jenisSampah,
    required this.kategoriJenis,
    required this.beratKg,
    this.alasanEdit,
    this.foto,
  });

  factory SampahTerkelola.fromJson(Map<String, dynamic> json) {
    return SampahTerkelola(
      id:            json['id'],
      idLokasi:      json['id_lokasi'] is int ? json['id_lokasi'] : int.tryParse(json['id_lokasi'].toString()) ?? 0,
      idJenis:       json['id_jenis']  is int ? json['id_jenis']  : int.tryParse(json['id_jenis'].toString())  ?? 0,
      tanggal:       json['tgl'] ?? '-',
      lokasiAsal:    json['lokasi_asal']?['nama_lokasi'] ?? '-',
      jenisSampah:   "${json['jenis']?['kategori_jenis'] ?? '-'} - ${json['jenis']?['nama_jenis'] ?? '-'}",
      kategoriJenis: json['jenis']?['kategori_jenis'] ?? '',
      beratKg:       double.tryParse(json['jumlah_berat'].toString()) ?? 0,
      alasanEdit:    json['alasan_edit'],
      foto:          json['foto_url'] ?? json['foto_kelola'],
    );
  }
}

// =========================
// MODEL SAMPAH DISERAHKAN
// =========================
class SampahDiserahkan {
  final int id;
  final int idLokasi;
  final int idJenis;
  final int idTujuan;
  final String tanggal;
  final String lokasiAsal;
  final String jenisSampah;
  final String kategoriJenis;
  final String tujuan;
  final double beratKg;
  final String? alasanEdit;
  final String? foto;

  SampahDiserahkan({
    required this.id,
    required this.idLokasi,
    required this.idJenis,
    required this.idTujuan,
    required this.tanggal,
    required this.lokasiAsal,
    required this.jenisSampah,
    required this.kategoriJenis,
    required this.tujuan,
    required this.beratKg,
    this.alasanEdit,
    this.foto,
  });

  // Perbaikan parsing tanggal dengan format fleksibel hanya di sampah diserahkan
  factory SampahDiserahkan.fromJson(Map<String, dynamic> json) {
    String rawDate = json['tgl_diserahkan']?.toString() ?? '-';
    String formattedDate = '-';

    if (rawDate != '-') {
      String cleanDate = rawDate.split('T')[0].split(' ')[0];
      try {
        DateTime parsedDate = DateTime.parse(cleanDate);
        formattedDate = DateFormat('dd-MM-yyyy').format(parsedDate);
      } catch (e) {
        formattedDate = cleanDate;
      }
    }

    return SampahDiserahkan(
      id:            json['id'],
      idLokasi:      json['id_lokasi'] is int ? json['id_lokasi'] : int.tryParse(json['id_lokasi'].toString()) ?? 0,
      idJenis:       json['id_jenis']  is int ? json['id_jenis']  : int.tryParse(json['id_jenis'].toString())  ?? 0,
      idTujuan:      json['id_tujuan'] is int ? json['id_tujuan'] : int.tryParse(json['id_tujuan'].toString()) ?? 0,
      tanggal:       formattedDate,
      lokasiAsal:    json['lokasi_asal']?['nama_lokasi'] ?? '-',
      jenisSampah:   "${json['jenis']?['kategori_jenis'] ?? '-'} - ${json['jenis']?['nama_jenis'] ?? '-'}",
      kategoriJenis: json['jenis']?['kategori_jenis'] ?? '',
      tujuan:        json['tujuan_sampah']?['nama_tujuan'] ?? '-',
      beratKg:       double.tryParse(json['jumlah_berat'].toString()) ?? 0,
      alasanEdit:    json['alasan_edit'],
      foto:          json['foto_url'],
    );
  }
}

// =========================
// HELPER PARSING TANGGAL
// =========================
DateTime _parseDateFlexible(String dateStr) {
  if (dateStr == '-') return DateTime.now();

  DateTime? parsed = DateTime.tryParse(dateStr);
  if (parsed != null) return parsed;

  try {
    List<String> parts = [];
    if (dateStr.contains('/')) {
      parts = dateStr.split('/');
    } else if (dateStr.contains('-')) {
      parts = dateStr.split('-');
    } else if (dateStr.contains(' ')) {
      parts = dateStr.split(' ')[0].split('-');
    }

    if (parts.length == 3) {
      if (parts[0].length <= 2 && parts[2].length >= 4) {
        int year = int.parse(parts[2].split(' ')[0]);
        return DateTime(year, int.parse(parts[1]), int.parse(parts[0]));
      }
      if (parts[0].length >= 4 && parts[2].length <= 2) {
        int year = int.parse(parts[0]);
        return DateTime(year, int.parse(parts[1]), int.parse(parts[2].split(' ')[0]));
      }
    }
  } catch (e) {
    // abaikan
  }

  return DateTime.now();
}

// =========================
// HALAMAN RIWAYAT
// =========================
class RiwayatPage extends StatefulWidget {
  const RiwayatPage({super.key});

  @override
  State<RiwayatPage> createState() => _RiwayatPageState();
}

class _RiwayatPageState extends State<RiwayatPage>
    with SingleTickerProviderStateMixin {

  late TabController _tabController;
  Timer? _debounceTerkelola;
  Timer? _debounceDiserahkan;

  // =========================================================
  // KATEGORI TETAP (sesuai aturan bisnis & web)
  // =========================================================
  static const List<Map<String, String>> kategoriTerkelola = [
    {"id": "Organik", "nama": "Organik"},
    {"id": "Anorganik", "nama": "Anorganik"},
  ];
  static const List<Map<String, String>> kategoriDiserahkan = [
    {"id": "Residu", "nama": "Residu"},
  ];

  // =========================================================
  // DATA MASTER (dinamis dari API /master-data)
  // =========================================================
  List<Map<String, dynamic>> lokasiMaster = [];
  List<Map<String, dynamic>> jenisMaster  = []; // id_jenis, nama_jenis, kategori_jenis
  List<Map<String, dynamic>> tujuanAktif  = []; // hanya status aktif
  List<Map<String, dynamic>> tujuanAll    = []; // semua (utk menampilkan tujuan existing yg dinonaktifkan)

  // ---- Sampah Terkelola ----
  List<SampahTerkelola> listTerkelola       = [];
  List<SampahTerkelola> listTerkelolaFilter = [];
  bool isLoadingTerkelola                   = false;
  String errorTerkelola                     = '';
  final TextEditingController searchTerkelolaC = TextEditingController();
  int pageTerkelola                         = 1;
  int perPageTerkelola                      = 10;
  int totalTerkelola                        = 0;
  int lastPageTerkelola                     = 1;

  // ---- Sampah Diserahkan ----
  List<SampahDiserahkan> listDiserahkan       = [];
  List<SampahDiserahkan> listDiserahkanFilter = [];
  bool isLoadingDiserahkan                    = false;
  String errorDiserahkan                      = '';
  final TextEditingController searchDiserahkanC = TextEditingController();
  int pageDiserahkan                          = 1;
  int perPageDiserahkan                       = 10;
  int totalDiserahkan                         = 0;
  int lastPageDiserahkan                      = 1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 1 && listDiserahkan.isEmpty) {
        fetchSampahDiserahkan();
      }
    });
    fetchMasterData();
    fetchSampahTerkelola();
  }

  @override
  void dispose() {
    _debounceTerkelola?.cancel();
    _debounceDiserahkan?.cancel();
    _tabController.dispose();
    searchTerkelolaC.dispose();
    searchDiserahkanC.dispose();
    super.dispose();
  }

  // =========================================================
  // FETCH DATA MASTER (untuk dropdown form edit)
  // =========================================================
  String get _masterDataUrl => ApiEndpoints.sampahTerkelola
      .replaceFirst(RegExp(r'/sampah-terkelola/?$'), '/master-data');

  int? _asInt(dynamic v) => v is int ? v : int.tryParse('$v');

  List<Map<String, dynamic>> _toListMap(dynamic raw) {
    if (raw is List) {
      return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return [];
  }

  Future<void> fetchMasterData() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.get(
        Uri.parse(_masterDataUrl),
        headers: {
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      final body = jsonDecode(response.body);
      if (response.statusCode == 200 && body['success'] == true) {
        final data = body['data'] ?? {};
        if (mounted) {
          setState(() {
            lokasiMaster = _toListMap(data['lokasi_asal']);
            jenisMaster  = _toListMap(data['jenis']);
            tujuanAktif  = _toListMap(data['tujuan_sampah']);
            // tujuan_sampah_all = semua (fallback ke tujuan_sampah bila backend belum diperbarui)
            final all = _toListMap(data['tujuan_sampah_all']);
            tujuanAll = all.isNotEmpty ? all : tujuanAktif;
          });
        }
      }
    } catch (e) {
      // diabaikan; dropdown akan kosong bila gagal, tidak membuat crash
    }
  }

  // Filter jenis berdasarkan kategori terpilih (case-insensitive)
  List<Map<String, dynamic>> _jenisByKategori(String? kategori) {
    if (kategori == null) return [];
    final k = kategori.toLowerCase();
    return jenisMaster
        .where((e) => '${e['kategori_jenis'] ?? ''}'.toLowerCase() == k)
        .toList();
  }

  // Cocokkan teks kategori (apa pun kapitalisasinya) ke salah satu id kategori tetap
  String? _matchKategori(List<Map<String, String>> list, String? raw) {
    if (raw == null) return null;
    final r = raw.toLowerCase();
    for (final e in list) {
      if (e['id']!.toLowerCase() == r) return e['id'];
    }
    return null;
  }

  // Cari kategori dari id jenis (lewat master)
  String? _kategoriFromIdJenis(int idJenis) {
    final f = jenisMaster.firstWhere(
      (e) => _asInt(e['id_jenis']) == idJenis,
      orElse: () => {},
    );
    return f.isEmpty ? null : '${f['kategori_jenis']}';
  }

  // =========================
  // FETCH SAMPAH TERKELOLA
  // =========================
  Future<void> fetchSampahTerkelola({int page = 1}) async {
    if (mounted) setState(() { isLoadingTerkelola = true; errorTerkelola = ''; });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token           = prefs.getString('token');

      final q = searchTerkelolaC.text.trim();
      final uri = Uri.parse(ApiEndpoints.sampahTerkelola).replace(queryParameters: {
        'page': '$page',
        'per_page': '$perPageTerkelola',
        if (q.isNotEmpty) 'tgl': q,
      });

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List list = data['data'];
          if (mounted) setState(() {
            listTerkelola       = list.map((e) => SampahTerkelola.fromJson(e)).toList();
            listTerkelolaFilter = listTerkelola;
            totalTerkelola      = data['total']        ?? 0;
            lastPageTerkelola   = data['last_page']    ?? 1;
            pageTerkelola       = data['current_page'] ?? 1;
          });
        }
      } else if (response.statusCode == 401) {
        _handleUnauthorized();
      } else {
        if (mounted) setState(() => errorTerkelola = 'Gagal memuat data');
      }
    } catch (e) {
      if (mounted) setState(() => errorTerkelola = e.toString());
    } finally {
      if (mounted) setState(() => isLoadingTerkelola = false);
    }
  }

  // =========================
  // FETCH SAMPAH DISERAHKAN
  // =========================
  Future<void> fetchSampahDiserahkan({int page = 1}) async {
    if (mounted) setState(() { isLoadingDiserahkan = true; errorDiserahkan = ''; });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token           = prefs.getString('token');

      final q = searchDiserahkanC.text.trim();
      final uri = Uri.parse(ApiEndpoints.sampahDiserahkan).replace(queryParameters: {
        'page': '$page',
        'per_page': '$perPageDiserahkan',
        if (q.isNotEmpty) 'tgl': q,
      });

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List list = data['data'];
          if (mounted) setState(() {
            listDiserahkan       = list.map((e) => SampahDiserahkan.fromJson(e)).toList();
            listDiserahkanFilter = listDiserahkan;
            totalDiserahkan      = data['total']        ?? 0;
            lastPageDiserahkan   = data['last_page']    ?? 1;
            pageDiserahkan       = data['current_page'] ?? 1;
          });
        }
      } else if (response.statusCode == 401) {
        _handleUnauthorized();
      } else {
        if (mounted) setState(() => errorDiserahkan = 'Gagal memuat data');
      }
    } catch (e) {
      if (mounted) setState(() => errorDiserahkan = e.toString());
    } finally {
      if (mounted) setState(() => isLoadingDiserahkan = false);
    }
  }

  // =========================================================
  // Ambil pesan error yang informatif dari response backend.
  // Laravel mengirim 'message' untuk error umum (mis. 500), tapi untuk
  // error validasi (422) hanya mengirim 'errors' (map field -> [pesan]).
  // Tanpa ini, petugas hanya melihat "Terjadi kesalahan" tanpa tahu
  // field mana yang bermasalah (mis. saat edit hasil delegasi admin,
  // yang mana berat/lokasi/jenis masih kosong/0 dan wajib diisi ulang).
  // =========================================================
  String _extractErrorMessage(dynamic data) {
    if (data is Map) {
      if (data['message'] is String && (data['message'] as String).isNotEmpty) {
        return data['message'];
      }
      if (data['errors'] is Map) {
        final errors = data['errors'] as Map;
        final messages = errors.values
            .expand((v) => v is List ? v : [v])
            .map((e) => '$e')
            .toList();
        if (messages.isNotEmpty) return messages.join('\n');
      }
    }
    return "Terjadi kesalahan";
  }

  Future<void> _handleUnauthorized() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Get.offAllNamed('/login');
  }

  void onSearchTerkelola(String query) {
    // Pencarian berbasis tanggal (mis. ketik 19 -> hanya tgl 19), diproses di server.
    _debounceTerkelola?.cancel();
    _debounceTerkelola = Timer(const Duration(milliseconds: 450), () {
      fetchSampahTerkelola(page: 1);
    });
  }

  void onSearchDiserahkan(String query) {
    // Pencarian berbasis tanggal (mis. ketik 19 -> hanya tgl 19), diproses di server.
    _debounceDiserahkan?.cancel();
    _debounceDiserahkan = Timer(const Duration(milliseconds: 450), () {
      fetchSampahDiserahkan(page: 1);
    });
  }

  // =========================
  // PREVIEW FOTO
  // =========================
  // =========================
  // PILIH SUMBER FOTO (kamera / galeri) + batasi resolusi
  // =========================
  // Resolusi & kualitas dibatasi supaya file tetap di bawah limit backend
  // (2MB) walau diambil langsung dari kamera beresolusi tinggi.
  Future<File?> _pilihFoto() async {
    final source = await Get.bottomSheet<ImageSource>(
      SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text("Ambil Foto Dari", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF1A3A6B)),
                title: const Text("Kamera"),
                onTap: () => Get.back(result: ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Color(0xFF1A3A6B)),
                title: const Text("Galeri"),
                onTap: () => Get.back(result: ImageSource.gallery),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );

    if (source == null) return null;

    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 70,
      maxWidth: 1600,   // turunkan resolusi agar file tetap ringan (< 2MB)
      maxHeight: 1600,
    );
    return picked != null ? File(picked.path) : null;
  }

  void _previewFoto(String urlFoto) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding:    const EdgeInsets.all(16),
        child: Stack(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: InteractiveViewer(
              child: Image.network(
                urlFoto, fit: BoxFit.contain, width: double.infinity,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(height: 300, color: Colors.black,
                    child: const Center(child: CircularProgressIndicator(color: Colors.white)));
                },
                errorBuilder: (_, __, ___) => Container(height: 300, color: Colors.black,
                  child: const Center(child: Icon(Icons.broken_image, color: Colors.white, size: 48))),
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

  // =========================
  // SHOW EDIT TERKELOLA
  // =========================
  void _showEditTerkelola(SampahTerkelola item) {
    // Record hasil delegasi admin punya berat default 0 (belum diisi petugas).
    // Kosongkan field-nya supaya jelas terlihat wajib diisi, bukan dianggap "sudah 0".
    final beratC  = TextEditingController(
      text: item.beratKg > 0 ? "${item.beratKg}" : "",
    );
    final alasanC = TextEditingController(text: item.alasanEdit ?? '');

    // Kategori tetap (Organik / Anorganik), diresolusi dari data existing
    String? resolvedKategori = _matchKategori(kategoriTerkelola, item.kategoriJenis)
        ?? _matchKategori(kategoriTerkelola, _kategoriFromIdJenis(item.idJenis));

    DateTime tgl = _parseDateFlexible(item.tanggal);

    int? selectedLokasi = lokasiMaster.any((e) => _asInt(e['id_lokasi']) == item.idLokasi)
        ? item.idLokasi : null;
    String? selectedKategori = resolvedKategori;
    int? selectedJenis = _jenisByKategori(resolvedKategori)
            .any((e) => _asInt(e['id_jenis']) == item.idJenis)
        ? item.idJenis : null;
    File? foto;
    bool isLoading = false;

      Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setStateSheet) {
          final jenisItems = _jenisByKategori(selectedKategori);
          return Container(
            // 1. Membatasi tinggi maksimal bottom sheet agar rounded corner tetap terlihat
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            decoration: const BoxDecoration(
              color:        Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: SafeArea(
              // 2. SafeArea menjaga isi form tidak menabrak status bar/notch di atas layar
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 16),
                child: Padding(
                  // 3. Pindahkan viewInsets.bottom ke sini agar area scroll view tetap luas 
                  // dan form bisa di-scroll ke atas keyboard dengan lancar
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Edit Sampah Terkelola",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A3A6B))),
                          IconButton(onPressed: () => Get.back(), icon: const Icon(Icons.close)),
                        ],
                      ),
                      const Divider(),

                      // Tanggal
                      _editLabel("Tanggal", required: true),
                      GestureDetector(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context, initialDate: tgl,
                            firstDate: DateTime(2020), lastDate: DateTime(2030),
                            builder: (ctx, child) => Theme(
                              data: Theme.of(ctx).copyWith(
                                colorScheme: const ColorScheme.light(primary: Color(0xFF1A3A6B))),
                              child: child!,
                            ),
                          );
                          if (picked != null) setStateSheet(() => tgl = picked);
                        },
                        child: _editDateField(tgl),
                      ),

                      const SizedBox(height: 12),

                      // Lokasi
                      _editLabel("Lokasi Asal", required: true),
                      _editDropdown<int>(
                        hint:  "-- Pilih Lokasi --",
                        value: selectedLokasi,
                        items: lokasiMaster.map((e) => DropdownMenuItem<int>(
                          value: _asInt(e['id_lokasi']),
                          child: Text('${e['nama_lokasi']}', style: const TextStyle(fontSize: 13)),
                        )).toList(),
                        onChanged: (val) => setStateSheet(() => selectedLokasi = val),
                      ),

                      const SizedBox(height: 12),

                      // Kategori
                      _editLabel("Kategori Jenis", required: true),
                      _editDropdown<String>(
                        hint:  "-- Pilih Kategori --",
                        value: selectedKategori,
                        items: kategoriTerkelola.map((e) => DropdownMenuItem<String>(
                          value: e['id'],
                          child: Text(e['nama']!, style: const TextStyle(fontSize: 13)),
                        )).toList(),
                        onChanged: (val) => setStateSheet(() {
                          selectedKategori = val;
                          selectedJenis    = null;
                        }),
                      ),

                      const SizedBox(height: 12),

                      // Jenis
                      _editLabel("Jenis Sampah", required: true),
                      _editDropdown<int>(
                        hint:    "-- Pilih Jenis --",
                        value:   selectedJenis,
                        enabled: selectedKategori != null,
                        items:   jenisItems.map((e) => DropdownMenuItem<int>(
                              value: _asInt(e['id_jenis']),
                              child: Text('${e['nama_jenis']}', style: const TextStyle(fontSize: 13)),
                            )).toList(),
                        onChanged: (val) => setStateSheet(() => selectedJenis = val),
                      ),

                      const SizedBox(height: 12),

                      // Berat
                      _editLabel("Berat (Kg)", required: true),
                      _editTextField(controller: beratC, hint: "0.00", isNumber: true),

                      const SizedBox(height: 12),

                      // Foto
                      _editLabel("Foto"),
                      _editFotoField(
                        foto:        foto,
                        fotoLamaUrl: item.foto,
                        onPick: () async {
                          final picked = await _pilihFoto();
                          if (picked != null) setStateSheet(() => foto = picked);
                        },
                        onRemove:  () => setStateSheet(() => foto = null),
                        onPreview: item.foto != null ? () => _previewFoto(item.foto!) : null,
                      ),

                      const SizedBox(height: 12),

                      // Keterangan (Alasan Edit)
                      _editLabel("Alasan Edit", required: true),
                      _editTextField(controller: alasanC, hint: "Jelaskan alasan perubahan", maxLines: 10),

                      const SizedBox(height: 16),

                      // Tombol Simpan
                      SizedBox(
                        width: double.infinity, height: 44,
                        child: ElevatedButton.icon(
                          onPressed: isLoading ? null : () async {
                            final beratVal = double.tryParse(beratC.text.trim().replaceAll(',', '.'));
                            if (selectedLokasi == null || selectedJenis == null ||
                                alasanC.text.trim().isEmpty) {
                              Get.snackbar("Peringatan", "Lengkapi semua field yang wajib (termasuk Alasan Edit)",
                                  backgroundColor: Colors.orange, colorText: Colors.white);
                              return;
                            }
                            if (beratVal == null || beratVal <= 0) {
                              Get.snackbar("Peringatan", "Berat wajib diisi dan harus lebih dari 0",
                                  backgroundColor: Colors.orange, colorText: Colors.white);
                              return;
                            }
                            setStateSheet(() => isLoading = true);
                            try {
                              SharedPreferences prefs = await SharedPreferences.getInstance();
                              String? token  = prefs.getString('token');
                              String? idUser = prefs.getString('id_user') ?? '1';

                              final request = http.MultipartRequest(
                                'POST',
                                Uri.parse("${ApiEndpoints.sampahTerkelola}/${item.id}"),
                              );
                              request.headers['Authorization'] = 'Bearer $token';
                              request.fields['_method']        = 'PUT';
                              request.fields['id_user']        = idUser;
                              request.fields['id_lokasi']      = '$selectedLokasi';
                              request.fields['id_jenis']       = '$selectedJenis';
                              request.fields['jumlah_berat']   = beratC.text.trim();
                              request.fields['tgl']            = DateFormat('yyyy-MM-dd').format(tgl);
                              request.fields['alasan_edit']    = alasanC.text.trim();

                              if (foto != null) {
                                request.files.add(await http.MultipartFile.fromPath(
                                  'foto_kelola', foto!.path));
                              }

                              final streamed = await request.send();
                              final response = await http.Response.fromStream(streamed);
                              final data     = jsonDecode(response.body);

                              if (response.statusCode == 200 && data['success'] == true) {
                                Get.back();
                                Get.snackbar("Berhasil", "Data berhasil diperbarui",
                                    backgroundColor: Colors.green, colorText: Colors.white);
                                fetchSampahTerkelola(page: pageTerkelola);
                              } else {
                                Get.snackbar("Gagal", _extractErrorMessage(data),
                                    backgroundColor: Colors.red, colorText: Colors.white);
                              }
                            } catch (e) {
                              Get.snackbar("Error", e.toString(),
                                  backgroundColor: Colors.red, colorText: Colors.white);
                            } finally {
                              setStateSheet(() => isLoading = false);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1A3A6B),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: isLoading
                              ? const SizedBox(width: 16, height: 16,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.save, color: Colors.white, size: 18),
                          label: Text(isLoading ? "Menyimpan..." : "Simpan Perubahan",
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
      isScrollControlled: true,
    );
  }

  // =========================
  // SHOW EDIT DISERAHKAN
  // =========================
  void _showEditDiserahkan(SampahDiserahkan item) {
    // Record hasil delegasi admin punya berat default 0 (belum diisi petugas).
    // Kosongkan field-nya supaya jelas terlihat wajib diisi, bukan dianggap "sudah 0".
    final beratC  = TextEditingController(
      text: item.beratKg > 0 ? "${item.beratKg}" : "",
    );
    final alasanC = TextEditingController(text: item.alasanEdit ?? '');

    // Kategori dikunci ke Residu
    String? resolvedKategori = _matchKategori(kategoriDiserahkan, item.kategoriJenis)
        ?? _matchKategori(kategoriDiserahkan, _kategoriFromIdJenis(item.idJenis))
        ?? (kategoriDiserahkan.isNotEmpty ? kategoriDiserahkan.first['id'] : null);

    DateTime tgl = _parseDateFlexible(item.tanggal);

    int? selectedLokasi = lokasiMaster.any((e) => _asInt(e['id_lokasi']) == item.idLokasi)
        ? item.idLokasi : null;
    String? selectedKategori = resolvedKategori;
    int? selectedJenis = _jenisByKategori(resolvedKategori)
            .any((e) => _asInt(e['id_jenis']) == item.idJenis)
        ? item.idJenis : null;

    // Tujuan untuk edit = aktif + tujuan yang sedang dipakai (walau sudah nonaktif)
    final List<Map<String, dynamic>> tujuanItems = [...tujuanAktif];
    if (!tujuanItems.any((e) => _asInt(e['id_tujuan']) == item.idTujuan)) {
      final cur = tujuanAll.firstWhere(
        (e) => _asInt(e['id_tujuan']) == item.idTujuan,
        orElse: () => {},
      );
      if (cur.isNotEmpty) tujuanItems.add(cur);
    }
    int? selectedTujuan = tujuanItems.any((e) => _asInt(e['id_tujuan']) == item.idTujuan)
        ? item.idTujuan : null;

    File? foto;
    bool isLoading = false;

          Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setStateSheet) {
          final jenisItems = _jenisByKategori(selectedKategori);
          return Container(
            // 1. Membatasi tinggi maksimal bottom sheet agar rounded corner tetap terlihat
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            decoration: const BoxDecoration(
              color:        Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: SafeArea(
              // 2. SafeArea menjaga isi form tidak menabrak status bar/notch di atas layar
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 16),
                child: Padding(
                  // 3. Pindahkan viewInsets.bottom ke sini agar area scroll view tetap luas 
                  // dan form bisa di-scroll ke atas keyboard dengan lancar
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Edit Sampah Diserahkan",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A3A6B))),
                          IconButton(onPressed: () => Get.back(), icon: const Icon(Icons.close)),
                        ],
                      ),
                      const Divider(),

                      // Tanggal
                      _editLabel("Tanggal", required: true),
                      GestureDetector(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context, initialDate: tgl,
                            firstDate: DateTime(2020), lastDate: DateTime(2030),
                            builder: (ctx, child) => Theme(
                              data: Theme.of(ctx).copyWith(
                                colorScheme: const ColorScheme.light(primary: Color(0xFF1A3A6B))),
                              child: child!,
                            ),
                          );
                          if (picked != null) setStateSheet(() => tgl = picked);
                        },
                        child: _editDateField(tgl),
                      ),

                      const SizedBox(height: 12),

                      // Lokasi
                      _editLabel("Lokasi Asal", required: true),
                      _editDropdown<int>(
                        hint:  "-- Pilih Lokasi --",
                        value: selectedLokasi,
                        items: lokasiMaster.map((e) => DropdownMenuItem<int>(
                          value: _asInt(e['id_lokasi']),
                          child: Text('${e['nama_lokasi']}', style: const TextStyle(fontSize: 13)),
                        )).toList(),
                        onChanged: (val) => setStateSheet(() => selectedLokasi = val),
                      ),

                      const SizedBox(height: 12),

                      // Kategori
                      _editLabel("Kategori Jenis", required: true),
                      _editDropdown<String>(
                        hint:  "-- Pilih Kategori --",
                        value: selectedKategori,
                        items: kategoriDiserahkan.map((e) => DropdownMenuItem<String>(
                          value: e['id'],
                          child: Text(e['nama']!, style: const TextStyle(fontSize: 13)),
                        )).toList(),
                        onChanged: (val) => setStateSheet(() {
                          selectedKategori = val;
                          selectedJenis    = null;
                        }),
                      ),

                      const SizedBox(height: 12),

                      // Jenis
                      _editLabel("Jenis Sampah", required: true),
                      _editDropdown<int>(
                        hint:    "-- Pilih Jenis --",
                        value:   selectedJenis,
                        enabled: selectedKategori != null,
                        items:   jenisItems.map((e) => DropdownMenuItem<int>(
                              value: _asInt(e['id_jenis']),
                              child: Text('${e['nama_jenis']}', style: const TextStyle(fontSize: 13)),
                            )).toList(),
                        onChanged: (val) => setStateSheet(() => selectedJenis = val),
                      ),

                      const SizedBox(height: 12),

                      // Tujuan
                      _editLabel("Tujuan Diserahkan", required: true),
                      _editDropdown<int>(
                        hint:  "-- Pilih Tujuan --",
                        value: selectedTujuan,
                        items: tujuanItems.map((e) => DropdownMenuItem<int>(
                          value: _asInt(e['id_tujuan']),
                          child: Text('${e['nama_tujuan']}', style: const TextStyle(fontSize: 13)),
                        )).toList(),
                        onChanged: (val) => setStateSheet(() => selectedTujuan = val),
                      ),

                      const SizedBox(height: 12),

                      // Berat
                      _editLabel("Berat (Kg)", required: true),
                      _editTextField(controller: beratC, hint: "0.00", isNumber: true),

                      const SizedBox(height: 12),

                      // Foto
                      _editLabel("Foto"),
                      _editFotoField(
                        foto:        foto,
                        fotoLamaUrl: item.foto,
                        onPick: () async {
                          final picked = await _pilihFoto();
                          if (picked != null) setStateSheet(() => foto = picked);
                        },
                        onRemove:  () => setStateSheet(() => foto = null),
                        onPreview: item.foto != null ? () => _previewFoto(item.foto!) : null,
                      ),

                      const SizedBox(height: 12),

                      // Keterangan (Alasan Edit)
                      _editLabel("Alasan Edit", required: true),
                      _editTextField(controller: alasanC, hint: "Jelaskan alasan perubahan", maxLines: 10),

                      const SizedBox(height: 16),

                      // Tombol Simpan
                      SizedBox(
                        width: double.infinity, height: 44,
                        child: ElevatedButton.icon(
                          onPressed: isLoading ? null : () async {
                            final beratVal = double.tryParse(beratC.text.trim().replaceAll(',', '.'));
                            if (selectedLokasi == null || selectedJenis == null ||
                                selectedTujuan == null || alasanC.text.trim().isEmpty) {
                              Get.snackbar("Peringatan", "Lengkapi semua field yang wajib (termasuk Alasan Edit)",
                                  backgroundColor: Colors.orange, colorText: Colors.white);
                              return;
                            }
                            if (beratVal == null || beratVal <= 0) {
                              Get.snackbar("Peringatan", "Berat wajib diisi dan harus lebih dari 0",
                                  backgroundColor: Colors.orange, colorText: Colors.white);
                              return;
                            }
                            setStateSheet(() => isLoading = true);
                            try {
                              SharedPreferences prefs = await SharedPreferences.getInstance();
                              String? token  = prefs.getString('token');
                              String? idUser = prefs.getString('id_user') ?? '1';

                              final request = http.MultipartRequest(
                                'POST',
                                Uri.parse("${ApiEndpoints.sampahDiserahkan}/${item.id}"),
                              );
                              request.headers['Authorization'] = 'Bearer $token';
                              request.fields['_method']        = 'PUT';
                              request.fields['id_user']        = idUser;
                              request.fields['id_lokasi']      = '$selectedLokasi';
                              request.fields['id_jenis']       = '$selectedJenis';
                              request.fields['id_tujuan']      = '$selectedTujuan';
                              request.fields['jumlah_berat']   = beratC.text.trim();
                              request.fields['tgl_diserahkan'] = DateFormat('yyyy-MM-dd').format(tgl);
                              request.fields['alasan_edit']    = alasanC.text.trim();

                              if (foto != null) {
                                request.files.add(await http.MultipartFile.fromPath(
                                  'foto_diserahkan', foto!.path));
                              }

                              final streamed = await request.send();
                              final response = await http.Response.fromStream(streamed);
                              final data     = jsonDecode(response.body);

                              if (response.statusCode == 200 && data['success'] == true) {
                                Get.back();
                                Get.snackbar("Berhasil", "Data berhasil diperbarui",
                                    backgroundColor: Colors.green, colorText: Colors.white);
                                fetchSampahDiserahkan(page: pageDiserahkan);
                              } else {
                                Get.snackbar("Gagal", _extractErrorMessage(data),
                                    backgroundColor: Colors.red, colorText: Colors.white);
                              }
                            } catch (e) {
                              Get.snackbar("Error", e.toString(),
                                  backgroundColor: Colors.red, colorText: Colors.white);
                            } finally {
                              setStateSheet(() => isLoading = false);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1A3A6B),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: isLoading
                              ? const SizedBox(width: 16, height: 16,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.save, color: Colors.white, size: 18),
                          label: Text(isLoading ? "Menyimpan..." : "Simpan Perubahan",
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
      isScrollControlled: true,
    );
  }

  // =========================
  // BUILD
  // =========================
  @override
  Widget build(BuildContext context) {
    // 1. Hapus SafeArea, langsung gunakan Column
    return Column(
      children: [
        Container(
          width: double.infinity,
          color: const Color(0xFF1A3A6B),
          // 2. Sesuaikan padding untuk memperhitungkan status bar (poni HP)
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 12, // 👈 Padding atas dinamis
            bottom: 12,
            left: 16,
            right: 16,
          ),
          child: const Text("Riwayat Inputan",
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        Container(
          color: Colors.white,
          child: TabBar(
            controller:             _tabController,
            labelColor:             const Color(0xFF1A3A6B),
            unselectedLabelColor: Colors.grey,
            indicatorColor:         const Color(0xFF1A3A6B),
            labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: "Sampah Terkelola"),
              Tab(text: "Sampah Diserahkan"),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [_buildTerkelolaTab(), _buildDiserahkanTab()],
          ),
        ),
      ],
    ); // 3. Pastikan penutupnya cukup menggunakan titik koma (;) di sini
  }

  static const _headerStyle = TextStyle(
    color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold,
  );

  // =========================
  // TAB TERKELOLA
  // =========================
  Widget _buildTerkelolaTab() {
    if (isLoadingTerkelola) return const Center(child: CircularProgressIndicator());
    if (errorTerkelola.isNotEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(errorTerkelola, style: const TextStyle(color: Colors.red)),
        const SizedBox(height: 12),
        ElevatedButton(onPressed: fetchSampahTerkelola, child: const Text("Coba Lagi")),
      ]));
    }
    return Column(children: [
      _buildSearchBar(
        controller: searchTerkelolaC, onSearch: onSearchTerkelola, perPage: perPageTerkelola,
        onPerPageChanged: (val) {
          setState(() { perPageTerkelola = val!; pageTerkelola = 1; });
          fetchSampahTerkelola(page: 1);
        },
      ),
      Expanded(
        child: RefreshIndicator(
          color: const Color(0xFF1A3A6B),
          onRefresh: () => fetchSampahTerkelola(page: pageTerkelola),
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            physics: const AlwaysScrollableScrollPhysics(),
            child: listTerkelolaFilter.isEmpty
                ? const SizedBox(
                    height: 320,
                    child: Center(child: Text("Tidak ada data")),
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: 780,
                      child: Column(children: [
                        _buildTerkelolaHeader(),
                        ...listTerkelolaFilter.asMap().entries.map((entry) {
                          final index = (pageTerkelola - 1) * perPageTerkelola + entry.key + 1;
                          return _buildTerkelolaRow(index, entry.value);
                        }),
                        const SizedBox(height: 8),
                        _buildPagination(
                          currentPage: pageTerkelola, totalPages: lastPageTerkelola,
                          totalData:   totalTerkelola,
                          onPrev: pageTerkelola > 1 ? () => fetchSampahTerkelola(page: pageTerkelola - 1) : null,
                          onNext: pageTerkelola < lastPageTerkelola ? () => fetchSampahTerkelola(page: pageTerkelola + 1) : null,
                        ),
                        const SizedBox(height: 16),
                      ]),
                    ),
                  ),
          ),
        ),
      ),
    ]);
  }

  Widget _buildTerkelolaHeader() {
    return Container(
      color: const Color(0xFF1A3A6B),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: Row(children: const [
        SizedBox(width: 30,  child: Text("No",           style: _headerStyle, textAlign: TextAlign.center)),
        SizedBox(width: 50,  child: Text("Foto",         style: _headerStyle, textAlign: TextAlign.center)),
        SizedBox(width: 75,  child: Text("Tanggal",      style: _headerStyle, textAlign: TextAlign.center)),
        SizedBox(width: 110, child: Text("Lokasi Asal",  style: _headerStyle)),
        SizedBox(width: 120, child: Text("Jenis Sampah", style: _headerStyle)),
        SizedBox(width: 60,  child: Text("Berat\n(Kg)",  style: _headerStyle, textAlign: TextAlign.center)),
        SizedBox(width: 110, child: Text("Keterangan",   style: _headerStyle)),
        SizedBox(width: 50,  child: Text("Aksi",         style: _headerStyle, textAlign: TextAlign.center)),
      ]),
    );
  }

  Widget _buildTerkelolaRow(int index, SampahTerkelola item) {
    final isEven = index % 2 == 0;
    return Container(
      color: isEven ? Colors.grey.shade100 : Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        SizedBox(width: 30,  child: Text("$index", style: const TextStyle(fontSize: 11), textAlign: TextAlign.center)),
        SizedBox(width: 50,  child: Center(child: _buildFotoWidget(item.foto))),
        SizedBox(width: 75,  child: Text(item.tanggal, style: const TextStyle(fontSize: 11), textAlign: TextAlign.center)),
        SizedBox(width: 110, child: Text(item.lokasiAsal, style: const TextStyle(fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis)),
        SizedBox(width: 120, child: Text(item.jenisSampah, style: const TextStyle(fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis)),
        SizedBox(width: 60,  child: Text("${item.beratKg}", style: const TextStyle(fontSize: 11), textAlign: TextAlign.center)),
        SizedBox(width: 110, child: Text(item.alasanEdit ?? "-", style: const TextStyle(fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis)),
        SizedBox(width: 50,  child: Center(child: _buildAksiButton(() => _showEditTerkelola(item)))),
      ]),
    );
  }

  // =========================
  // TAB DISERAHKAN
  // =========================
  Widget _buildDiserahkanTab() {
    if (isLoadingDiserahkan) return const Center(child: CircularProgressIndicator());
    if (errorDiserahkan.isNotEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(errorDiserahkan, style: const TextStyle(color: Colors.red)),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: () => fetchSampahDiserahkan(page: pageDiserahkan),
          child: const Text("Coba Lagi"),
        ),
      ]));
    }
    if (listDiserahkan.isEmpty && !isLoadingDiserahkan) {
      return Center(
        child: ElevatedButton(
          onPressed: () => fetchSampahDiserahkan(),
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A3A6B)),
          child: const Text("Muat Data", style: TextStyle(color: Colors.white)),
        ),
      );
    }
    return Column(children: [
      _buildSearchBar(
        controller: searchDiserahkanC, onSearch: onSearchDiserahkan, perPage: perPageDiserahkan,
        onPerPageChanged: (val) {
          setState(() { perPageDiserahkan = val!; pageDiserahkan = 1; });
          fetchSampahDiserahkan(page: 1);
        },
      ),
      Expanded(
        child: RefreshIndicator(
          color: const Color(0xFF1A3A6B),
          onRefresh: () => fetchSampahDiserahkan(page: pageDiserahkan),
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            physics: const AlwaysScrollableScrollPhysics(),
            child: listDiserahkanFilter.isEmpty
                ? const SizedBox(
                    height: 320,
                    child: Center(child: Text("Tidak ada data")),
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: 870,
                      child: Column(children: [
                        _buildDiserahkanHeader(),
                        ...listDiserahkanFilter.asMap().entries.map((entry) {
                          final index = (pageDiserahkan - 1) * perPageDiserahkan + entry.key + 1;
                          return _buildDiserahkanRow(index, entry.value);
                        }),
                        const SizedBox(height: 8),
                        _buildPagination(
                          currentPage: pageDiserahkan, totalPages: lastPageDiserahkan,
                          totalData:   totalDiserahkan,
                          onPrev: pageDiserahkan > 1 ? () => fetchSampahDiserahkan(page: pageDiserahkan - 1) : null,
                          onNext: pageDiserahkan < lastPageDiserahkan ? () => fetchSampahDiserahkan(page: pageDiserahkan + 1) : null,
                        ),
                        const SizedBox(height: 16),
                      ]),
                    ),
                  ),
          ),
        ),
      ),
    ]);
  }

  Widget _buildDiserahkanHeader() {
    return Container(
      color: const Color(0xFF1A3A6B),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: Row(children: const [
        SizedBox(width: 30,  child: Text("No",           style: _headerStyle, textAlign: TextAlign.center)),
        SizedBox(width: 50,  child: Text("Foto",         style: _headerStyle, textAlign: TextAlign.center)),
        SizedBox(width: 75,  child: Text("Tanggal",      style: _headerStyle, textAlign: TextAlign.center)),
        SizedBox(width: 110, child: Text("Lokasi Asal",  style: _headerStyle)),
        SizedBox(width: 110, child: Text("Jenis Sampah", style: _headerStyle)),
        SizedBox(width: 110, child: Text("Tujuan",       style: _headerStyle)),
        SizedBox(width: 60,  child: Text("Berat\n(Kg)",  style: _headerStyle, textAlign: TextAlign.center)),
        SizedBox(width: 100, child: Text("Keterangan",   style: _headerStyle)),
        SizedBox(width: 50,  child: Text("Aksi",         style: _headerStyle, textAlign: TextAlign.center)),
      ]),
    );
  }

  Widget _buildDiserahkanRow(int index, SampahDiserahkan item) {
    final isEven = index % 2 == 0;
    return Container(
      color: isEven ? Colors.grey.shade100 : Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        SizedBox(width: 30,  child: Text("$index", style: const TextStyle(fontSize: 11), textAlign: TextAlign.center)),
        SizedBox(width: 50,  child: Center(child: _buildFotoWidget(item.foto))),
        SizedBox(width: 75,  child: Text(item.tanggal, style: const TextStyle(fontSize: 11), textAlign: TextAlign.center)),
        SizedBox(width: 110, child: Text(item.lokasiAsal, style: const TextStyle(fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis)),
        SizedBox(width: 110, child: Text(item.jenisSampah, style: const TextStyle(fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis)),
        SizedBox(width: 110, child: Text(item.tujuan, style: const TextStyle(fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis)),
        SizedBox(width: 60,  child: Text("${item.beratKg}", style: const TextStyle(fontSize: 11), textAlign: TextAlign.center)),
        SizedBox(width: 100, child: Text(item.alasanEdit ?? "-", style: const TextStyle(fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis)),
        SizedBox(width: 50,  child: Center(child: _buildAksiButton(() => _showEditDiserahkan(item)))),
      ]),
    );
  }

  // =========================
  // SHARED WIDGETS
  // =========================
  Widget _buildFotoWidget(String? foto) {
    if (foto == null) return const Text("-", style: TextStyle(fontSize: 11), textAlign: TextAlign.center);
    return GestureDetector(
      onTap: () => _previewFoto(foto),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.network(foto, width: 36, height: 36, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 20, color: Colors.grey)),
      ),
    );
  }

  Widget _buildAksiButton(VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(color: const Color(0xFFFFC107), borderRadius: BorderRadius.circular(4)),
        child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.edit, size: 10, color: Colors.white),
          SizedBox(width: 2),
          Text("Edit", style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
        ]),
      ),
    );
  }

  Widget _buildSearchBar({
    required TextEditingController controller,
    required Function(String) onSearch,
    required int perPage,
    required Function(int?) onPerPageChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(children: [
        const Text("Tampilkan ", style: TextStyle(fontSize: 12)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(4)),
          child: DropdownButton<int>(
            value: perPage, underline: const SizedBox(), isDense: true,
            style: const TextStyle(fontSize: 12, color: Colors.black),
            items: [10, 25, 50].map((e) => DropdownMenuItem(value: e, child: Text("$e"))).toList(),
            onChanged: onPerPageChanged,
          ),
        ),
        const Text(" entri", style: TextStyle(fontSize: 12)),
        const Spacer(),
        SizedBox(
          width: 150,
          child: TextField(
            controller: controller, onChanged: onSearch,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 12),
            decoration: InputDecoration(
              hintText: "Cari tgl (mis. 19)", hintStyle: const TextStyle(fontSize: 11), isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
              prefixIcon: const Icon(Icons.search, size: 16),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildPagination({
    required int currentPage, required int totalPages,
    required int totalData, VoidCallback? onPrev, VoidCallback? onNext,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("Halaman $currentPage dari $totalPages ($totalData data)",
            style: const TextStyle(fontSize: 11, color: Colors.grey)),
          Row(children: [
            _pageButton(icon: Icons.chevron_left,  onTap: onPrev),
            const SizedBox(width: 8),
            _pageButton(icon: Icons.chevron_right, onTap: onNext),
          ]),
        ],
      ),
    );
  }

  Widget _pageButton({required IconData icon, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: onTap != null ? const Color(0xFF1A3A6B) : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(icon, size: 16, color: onTap != null ? Colors.white : Colors.grey),
      ),
    );
  }

  // =========================
  // HELPER EDIT WIDGETS
  // =========================
  Widget _editLabel(String text, {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        if (required) const Text(" *", style: TextStyle(color: Colors.red)),
      ]),
    );
  }

  Widget _editDateField(DateTime date) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(DateFormat('dd/MM/yyyy').format(date), style: const TextStyle(fontSize: 13)),
          const Icon(Icons.calendar_today, size: 16, color: Color(0xFF1A3A6B)),
        ],
      ),
    );
  }

  Widget _editDropdown<T>({
    required String hint, required T? value,
    required List<DropdownMenuItem<T>> items,
    required Function(T?) onChanged, bool enabled = true,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border:       Border.all(color: enabled ? Colors.grey.shade400 : Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        color:        enabled ? Colors.white : Colors.grey.shade100,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint:  Text(hint, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          isExpanded: true, items: items,
          onChanged: enabled ? onChanged : null,
          style: const TextStyle(fontSize: 13, color: Colors.black),
        ),
      ),
    );
  }

  Widget _editTextField({
    required TextEditingController controller,
    required String hint,
    bool isNumber = false, int maxLines = 1,
  }) {
    return TextField(
      controller:   controller,
      keyboardType: isNumber
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        hintText: hint, isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF1A3A6B)),
        ),
      ),
    );
  }

  Widget _editFotoField({
    required File? foto, required String? fotoLamaUrl,
    required VoidCallback onPick, required VoidCallback onRemove,
    VoidCallback? onPreview,
  }) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      GestureDetector(
        onTap: onPick,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(8)),
          child: Row(children: [
            const Icon(Icons.attach_file, size: 16, color: Color(0xFF1A3A6B)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                foto != null ? foto.path.split('/').last : "Pilih foto baru (opsional)",
                style: TextStyle(fontSize: 13, color: foto != null ? Colors.black : Colors.grey),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (foto != null)
              GestureDetector(onTap: onRemove,
                child: const Icon(Icons.close, size: 16, color: Colors.red)),
          ]),
        ),
      ),

      if (foto != null) ...[
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(foto, height: 100, width: double.infinity, fit: BoxFit.cover),
        ),
      ],

      if (fotoLamaUrl != null && foto == null) ...[
        const SizedBox(height: 6),
        Row(children: [
          const Text("Foto saat ini:", style: TextStyle(fontSize: 12, color: Colors.grey)),
          if (onPreview != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onPreview,
              child: const Text("Lihat", style: TextStyle(
                fontSize: 12, color: Color(0xFF1A3A6B),
                decoration: TextDecoration.underline)),
            ),
          ],
        ]),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(fotoLamaUrl, height: 80, width: double.infinity, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const SizedBox()),
        ),
      ],
    ]);
  }
}