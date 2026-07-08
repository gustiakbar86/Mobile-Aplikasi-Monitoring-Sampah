import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../app/utils/api_endpoints.dart';

class KelolaMasterPage extends StatelessWidget {
  const KelolaMasterPage({super.key});

  static const Color brand = Color(0xFF1A3A6B);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 6,
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F4F7),
        appBar: AppBar(
          backgroundColor: brand,
          foregroundColor: Colors.white,
          title: const Text("Kelola Data Master", style: TextStyle(fontSize: 16)),
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start, //fix bug tampilan
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: "Lokasi"),
              Tab(text: "Jenis"),
              Tab(text: "Tujuan"),
              Tab(text: "Instansi"),
              Tab(text: "Dokumen"),
              // Tab(text: "Export"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _MasterLokasi(),
            _MasterJenis(),
            _MasterTujuan(),
            _MasterInstansi(),
            _MasterDokumen(),
            // _TabExport(),
          ],
        ),
      ),
    );
  }
}

// Helper umum
const Color _brand = Color(0xFF1A3A6B);
const Color _biruMuda = Color(0xFF5B9BD5);

Future<String> _token() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('token') ?? '';
}

Future<bool> _konfirmasiHapus() async {
  final r = await Get.dialog<bool>(
    AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.orange, width: 3),
            ),
            child: const Icon(Icons.priority_high, color: Colors.orange, size: 36),
          ),
          const SizedBox(height: 16),
          const Text("Apakah anda yakin?",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text("Data yang dihapus tidak dapat dikembalikan!",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54)),
        ],
      ),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => Get.back(result: true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: _brand, foregroundColor: Colors.white),
              child: const Text("Ya, hapus!"),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: () => Get.back(result: false),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red, foregroundColor: Colors.white),
              child: const Text("Batal"),
            ),
          ],
        ),
      ],
    ),
  );
  return r == true;
}

InputDecoration _dec(String? hint) => InputDecoration(
      hintText: hint,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    );

// ======================================================
// TAB 1: LOKASI ASAL
// ======================================================
class _MasterLokasi extends StatefulWidget {
  const _MasterLokasi();
  @override
  State<_MasterLokasi> createState() => _MasterLokasiState();
}

class _MasterLokasiState extends State<_MasterLokasi> {
  bool isLoading = true;
  String? errorMsg;
  List<dynamic> all = [];
  String search = '';
  final searchC = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetch();
  }

  @override
  void dispose() {
    searchC.dispose();
    super.dispose();
  }

  Future<void> fetch() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
      errorMsg = null;
    });
    try {
      final res = await http.get(
        Uri.parse(ApiEndpoints.masterLokasi),
        headers: {'Authorization': 'Bearer ${await _token()}', 'Accept': 'application/json'},
      );
      if (res.statusCode != 200) throw Exception('Gagal memuat (${res.statusCode})');
      final body = jsonDecode(res.body);
      if (!mounted) return;
      setState(() {
        all = body['data'] ?? [];
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        errorMsg = e.toString();
      });
    }
  }

  List<dynamic> get filtered => search.isEmpty
      ? all
      : all
          .where((e) => (e['nama_lokasi'] ?? '')
              .toString()
              .toLowerCase()
              .contains(search.toLowerCase()))
          .toList();

    void _form({Map<String, dynamic>? data}) {
    final isEdit = data != null;
    final c = TextEditingController(text: data?['nama_lokasi'] ?? '');

    Get.bottomSheet(
      isScrollControlled: true,
      Container(
        // 1. Batasi tinggi maksimal agar bottom sheet rounded corner tetap terlihat
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          // 2. SafeArea menjaga isi form tidak melebihi batas atas status bar/notch
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 16),
            child: Padding(
              // 3. Pindahkan viewInsets.bottom ke sini untuk keyboard spacer
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(isEdit ? "Edit Lokasi Asal" : "Tambah Lokasi Asal",
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold, color: _brand)),
                  ),
                  const SizedBox(height: 16),
                  const Text("Nama Lokasi",
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  TextField(controller: c, decoration: _dec("Masukkan nama lokasi")),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Get.back(),
                          icon: const Icon(Icons.arrow_back, size: 16),
                          label: const Text("Kembali"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _simpan(isEdit, data?['id_lokasi'], c.text.trim()),
                          icon: const Icon(Icons.save, size: 16),
                          label: const Text("Simpan"),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: _brand, foregroundColor: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _simpan(bool isEdit, int? id, String nama) async {
    if (nama.isEmpty) {
      Get.snackbar("Lengkapi", "Nama lokasi wajib diisi",
          backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }
    try {
      final headers = {
        'Authorization': 'Bearer ${await _token()}',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      final body = jsonEncode({'nama_lokasi': nama});
      final res = isEdit
          ? await http.put(Uri.parse('${ApiEndpoints.masterLokasi}/$id'),
              headers: headers, body: body)
          : await http.post(Uri.parse(ApiEndpoints.masterLokasi),
              headers: headers, body: body);
      final r = jsonDecode(res.body);
      if ((res.statusCode == 200 || res.statusCode == 201) && r['success'] == true) {
        Get.back();
        Get.snackbar("Berhasil", r['message'] ?? "Tersimpan",
            backgroundColor: Colors.green, colorText: Colors.white);
        fetch();
      } else {
        String msg = r['message'] ?? "Gagal";
        if (r['errors'] != null) msg = (r['errors'] as Map).values.first[0].toString();
        Get.snackbar("Gagal", msg, backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar("Error", e.toString(),
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<void> _hapus(int id) async {
    if (!await _konfirmasiHapus()) return;
    try {
      final res = await http.delete(
        Uri.parse('${ApiEndpoints.masterLokasi}/$id'),
        headers: {'Authorization': 'Bearer ${await _token()}', 'Accept': 'application/json'},
      );
      final r = jsonDecode(res.body);
      if (res.statusCode == 200 && r['success'] == true) {
        Get.snackbar("Berhasil", "Lokasi dihapus",
            backgroundColor: Colors.green, colorText: Colors.white);
        fetch();
      } else {
        Get.snackbar("Gagal", r['message'] ?? "Gagal menghapus",
            backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar("Error", e.toString(),
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _MasterScaffold(
      tambahLabel: "Tambah Lokasi",
      onTambah: () => _form(),
      searchC: searchC,
      onSearch: (v) => setState(() => search = v),
      isLoading: isLoading,
      errorMsg: errorMsg,
      onRetry: fetch,
      child: filtered.isEmpty
          ? const Center(child: Text("Tidak ada data"))
          : RefreshIndicator(
              onRefresh: fetch,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                itemCount: filtered.length,
                itemBuilder: (c, i) {
                  final e = filtered[i];
                  return _kartu(
                    judul: e['nama_lokasi'] ?? '-',
                    subtitle: null,
                    onEdit: () => _form(data: e),
                    onHapus: () => _hapus(e['id_lokasi']),
                  );
                },
              ),
            ),
    );
  }
}

// ======================================================
// TAB 2: JENIS SAMPAH
// ======================================================
class _MasterJenis extends StatefulWidget {
  const _MasterJenis();
  @override
  State<_MasterJenis> createState() => _MasterJenisState();
}

class _MasterJenisState extends State<_MasterJenis> {
  bool isLoading = true;
  String? errorMsg;
  List<dynamic> all = [];
  String search = '';
  final searchC = TextEditingController();
  final kategoriOpsi = const ["Organik", "Anorganik", "Residu"];

  @override
  void initState() {
    super.initState();
    fetch();
  }

  @override
  void dispose() {
    searchC.dispose();
    super.dispose();
  }

  Future<void> fetch() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
      errorMsg = null;
    });
    try {
      final res = await http.get(
        Uri.parse(ApiEndpoints.masterJenis),
        headers: {'Authorization': 'Bearer ${await _token()}', 'Accept': 'application/json'},
      );
      if (res.statusCode != 200) throw Exception('Gagal memuat (${res.statusCode})');
      final body = jsonDecode(res.body);
      if (!mounted) return;
      setState(() {
        all = body['data'] ?? [];
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        errorMsg = e.toString();
      });
    }
  }

  List<dynamic> get filtered => search.isEmpty
      ? all
      : all.where((e) {
          final t = "${e['nama_jenis']} ${e['kategori_jenis']}".toLowerCase();
          return t.contains(search.toLowerCase());
        }).toList();

    void _form({Map<String, dynamic>? data}) {
    final isEdit = data != null;
    final namaC = TextEditingController(text: data?['nama_jenis'] ?? '');
    String? kategori = data?['kategori_jenis'];

    Get.bottomSheet(
      isScrollControlled: true,
      StatefulBuilder(builder: (context, setSheet) {
        return Container(
          // 1. Batasi tinggi maksimal
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: SafeArea(
            // 2. SafeArea
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 16),
              child: Padding(
                // 3. Spacer keyboard
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(isEdit ? "Edit Jenis Sampah" : "Tambah Jenis Sampah",
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold, color: _brand)),
                    ),
                    const SizedBox(height: 16),
                    const Text("Kategori Jenis",
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      value: kategori,
                      isExpanded: true,
                      decoration: _dec("-- Pilih Kategori --"),
                      items: kategoriOpsi
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (v) => setSheet(() => kategori = v),
                    ),
                    const SizedBox(height: 12),
                    const Text("Nama Jenis",
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    TextField(controller: namaC, decoration: _dec("Mis. Botol Plastik")),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => Get.back(),
                            icon: const Icon(Icons.arrow_back, size: 16),
                            label: const Text("Kembali"),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _simpan(
                                isEdit, data?['id_jenis'], kategori, namaC.text.trim()),
                            icon: const Icon(Icons.save, size: 16),
                            label: const Text("Simpan"),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: _brand, foregroundColor: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Future<void> _simpan(bool isEdit, int? id, String? kategori, String nama) async {
    if (kategori == null || nama.isEmpty) {
      Get.snackbar("Lengkapi", "Kategori dan nama wajib diisi",
          backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }
    try {
      final headers = {
        'Authorization': 'Bearer ${await _token()}',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      final body = jsonEncode({'kategori_jenis': kategori, 'nama_jenis': nama});
      final res = isEdit
          ? await http.put(Uri.parse('${ApiEndpoints.masterJenis}/$id'),
              headers: headers, body: body)
          : await http.post(Uri.parse(ApiEndpoints.masterJenis),
              headers: headers, body: body);
      final r = jsonDecode(res.body);
      if ((res.statusCode == 200 || res.statusCode == 201) && r['success'] == true) {
        Get.back();
        Get.snackbar("Berhasil", r['message'] ?? "Tersimpan",
            backgroundColor: Colors.green, colorText: Colors.white);
        fetch();
      } else {
        String msg = r['message'] ?? "Gagal";
        if (r['errors'] != null) msg = (r['errors'] as Map).values.first[0].toString();
        Get.snackbar("Gagal", msg, backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar("Error", e.toString(),
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<void> _hapus(int id) async {
    if (!await _konfirmasiHapus()) return;
    try {
      final res = await http.delete(
        Uri.parse('${ApiEndpoints.masterJenis}/$id'),
        headers: {'Authorization': 'Bearer ${await _token()}', 'Accept': 'application/json'},
      );
      final r = jsonDecode(res.body);
      if (res.statusCode == 200 && r['success'] == true) {
        Get.snackbar("Berhasil", "Jenis dihapus",
            backgroundColor: Colors.green, colorText: Colors.white);
        fetch();
      } else {
        Get.snackbar("Gagal", r['message'] ?? "Gagal menghapus",
            backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar("Error", e.toString(),
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _MasterScaffold(
      tambahLabel: "Tambah Jenis",
      onTambah: () => _form(),
      searchC: searchC,
      onSearch: (v) => setState(() => search = v),
      isLoading: isLoading,
      errorMsg: errorMsg,
      onRetry: fetch,
      child: filtered.isEmpty
          ? const Center(child: Text("Tidak ada data"))
          : RefreshIndicator(
              onRefresh: fetch,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                itemCount: filtered.length,
                itemBuilder: (c, i) {
                  final e = filtered[i];
                  return _kartu(
                    judul: e['nama_jenis'] ?? '-',
                    subtitle: "Kategori: ${e['kategori_jenis'] ?? '-'}",
                    onEdit: () => _form(data: e),
                    onHapus: () => _hapus(e['id_jenis']),
                  );
                },
              ),
            ),
    );
  }
}

// ======================================================
// TAB 3: TUJUAN SAMPAH
// ======================================================
class _MasterTujuan extends StatefulWidget {
  const _MasterTujuan();
  @override
  State<_MasterTujuan> createState() => _MasterTujuanState();
}

class _MasterTujuanState extends State<_MasterTujuan> {
  bool isLoading = true;
  String? errorMsg;
  List<dynamic> all = [];
  String search = '';
  final searchC = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetch();
  }

  @override
  void dispose() {
    searchC.dispose();
    super.dispose();
  }

  Future<void> fetch() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
      errorMsg = null;
    });
    try {
      final res = await http.get(
        Uri.parse(ApiEndpoints.masterTujuan),
        headers: {'Authorization': 'Bearer ${await _token()}', 'Accept': 'application/json'},
      );
      if (res.statusCode != 200) throw Exception('Gagal memuat (${res.statusCode})');
      final body = jsonDecode(res.body);
      if (!mounted) return;
      setState(() {
        all = body['data'] ?? [];
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        errorMsg = e.toString();
      });
    }
  }

  List<dynamic> get filtered => search.isEmpty
      ? all
      : all.where((e) {
          final t = "${e['nama_tujuan']} ${e['kategori_tujuan']}".toLowerCase();
          return t.contains(search.toLowerCase());
        }).toList();

    void _form({Map<String, dynamic>? data}) {
    final isEdit = data != null;
    final namaC = TextEditingController(text: data?['nama_tujuan'] ?? '');
    final alamatC = TextEditingController(text: data?['alamat'] ?? '');
    final kategoriTujuanOpsi = const [
      {"value": "bank_sampah", "label": "Bank Sampah"},
      {"value": "tpa", "label": "TPA"},
    ];
    final rawKat = (data?['kategori_tujuan'] ?? '').toString();
    String? kategoriTujuan =
        kategoriTujuanOpsi.any((e) => e['value'] == rawKat) ? rawKat : null;
    int status = data?['status'] ?? 1;

    Get.bottomSheet(
      isScrollControlled: true,
      StatefulBuilder(builder: (context, setSheet) {
        return Container(
          // 1. Batasi tinggi maksimal
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: SafeArea(
            // 2. SafeArea
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 16),
              child: Padding(
                // 3. Spacer keyboard
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(isEdit ? "Edit Tujuan Sampah" : "Tambah Tujuan Sampah",
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold, color: _brand)),
                    ),
                    const SizedBox(height: 16),
                    _label("Nama Tujuan"),
                    TextField(controller: namaC, decoration: _dec("Mis. TPA Basirih")),
                    const SizedBox(height: 12),
                    _label("Kategori Tujuan"),
                    DropdownButtonFormField<String>(
                      value: kategoriTujuan,
                      isExpanded: true,
                      decoration: _dec("-- Pilih Kategori --"),
                      items: kategoriTujuanOpsi
                          .map((e) => DropdownMenuItem<String>(
                                value: e['value'],
                                child: Text(e['label']!),
                              ))
                          .toList(),
                      onChanged: (v) => setSheet(() => kategoriTujuan = v),
                    ),
                    const SizedBox(height: 12),
                    _label("Alamat"),
                    TextField(controller: alamatC, decoration: _dec("Alamat (opsional)"), maxLines: 2),
                    const SizedBox(height: 12),
                    _label("Status"),
                    DropdownButtonFormField<int>(
                      value: status,
                      isExpanded: true,
                      decoration: _dec(null),
                      items: const [
                        DropdownMenuItem(value: 1, child: Text("Aktif")),
                        DropdownMenuItem(value: 0, child: Text("Nonaktif")),
                      ],
                      onChanged: (v) => setSheet(() => status = v ?? 1),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => Get.back(),
                            icon: const Icon(Icons.arrow_back, size: 16),
                            label: const Text("Kembali"),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _simpan(isEdit, data?['id_tujuan'],
                                namaC.text.trim(), kategoriTujuan ?? '', alamatC.text.trim(), status),
                            icon: const Icon(Icons.save, size: 16),
                            label: const Text("Simpan"),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: _brand, foregroundColor: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(t, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      );

  Future<void> _simpan(bool isEdit, int? id, String nama, String kat,
      String alamat, int status) async {
    if (nama.isEmpty || kat.isEmpty) {
      Get.snackbar("Lengkapi", "Nama dan kategori wajib diisi",
          backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }
    try {
      final headers = {
        'Authorization': 'Bearer ${await _token()}',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      final body = jsonEncode({
        'nama_tujuan': nama,
        'kategori_tujuan': kat,
        'alamat': alamat,
        'status': status,
      });
      final res = isEdit
          ? await http.put(Uri.parse('${ApiEndpoints.masterTujuan}/$id'),
              headers: headers, body: body)
          : await http.post(Uri.parse(ApiEndpoints.masterTujuan),
              headers: headers, body: body);
      final r = jsonDecode(res.body);
      if ((res.statusCode == 200 || res.statusCode == 201) && r['success'] == true) {
        Get.back();
        Get.snackbar("Berhasil", r['message'] ?? "Tersimpan",
            backgroundColor: Colors.green, colorText: Colors.white);
        fetch();
      } else {
        String msg = r['message'] ?? "Gagal";
        if (r['errors'] != null) msg = (r['errors'] as Map).values.first[0].toString();
        Get.snackbar("Gagal", msg, backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar("Error", e.toString(),
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<void> _hapus(int id) async {
    if (!await _konfirmasiHapus()) return;
    try {
      final res = await http.delete(
        Uri.parse('${ApiEndpoints.masterTujuan}/$id'),
        headers: {'Authorization': 'Bearer ${await _token()}', 'Accept': 'application/json'},
      );
      final r = jsonDecode(res.body);
      if (res.statusCode == 200 && r['success'] == true) {
        Get.snackbar("Berhasil", "Tujuan dihapus",
            backgroundColor: Colors.green, colorText: Colors.white);
        fetch();
      } else {
        Get.snackbar("Gagal", r['message'] ?? "Gagal menghapus",
            backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar("Error", e.toString(),
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

    @override
  Widget build(BuildContext context) {
    return _MasterScaffold(
      tambahLabel: "Tambah Tujuan",
      onTambah: () => _form(),
      searchC: searchC,
      onSearch: (v) => setState(() => search = v),
      isLoading: isLoading,
      errorMsg: errorMsg,
      onRetry: fetch,
      child: filtered.isEmpty
          ? const Center(child: Text("Tidak ada data"))
          : RefreshIndicator(
              onRefresh: fetch,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                itemCount: filtered.length,
                itemBuilder: (c, i) {
                  final e = filtered[i];
                  final statusTxt = (e['status'] == 1 || e['status'] == '1')
                      ? "Aktif"
                      : "Nonaktif";
                      
                  // Memetakan kategori mentah dari API menjadi teks yang rapi
                  final rawKat = e['kategori_tujuan']?.toString() ?? '-';
                  final katTxt = rawKat == 'bank_sampah'
                      ? 'Bank Sampah'
                      : (rawKat == 'tpa' ? 'TPA' : rawKat);

                  return _kartu(
                    judul: e['nama_tujuan'] ?? '-',
                    subtitle:
                        "$katTxt · $statusTxt${(e['alamat'] ?? '').toString().isEmpty ? '' : '\n${e['alamat']}'}",
                    onEdit: () => _form(data: e),
                    onHapus: () => _hapus(e['id_tujuan']),
                  );
                },
              ),
            ),
    );
  }
}



// ======================================================
// TAB 4: INSTANSI
// ======================================================
class _MasterInstansi extends StatefulWidget {
  const _MasterInstansi();
  @override
  State<_MasterInstansi> createState() => _MasterInstansiState();
}

class _MasterInstansiState extends State<_MasterInstansi> {
  bool isLoading = true;
  String? errorMsg;
  List<dynamic> all = [];
  String search = '';
  final searchC = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetch();
  }

  @override
  void dispose() {
    searchC.dispose();
    super.dispose();
  }

  Future<void> fetch() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
      errorMsg = null;
    });
    try {
      final res = await http.get(
        Uri.parse(ApiEndpoints.masterInstansi),
        headers: {'Authorization': 'Bearer ${await _token()}', 'Accept': 'application/json'},
      );
      if (res.statusCode != 200) throw Exception('Gagal memuat (${res.statusCode})');
      final body = jsonDecode(res.body);
      if (!mounted) return;
      setState(() {
        all = body['data'] ?? [];
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        errorMsg = e.toString();
      });
    }
  }

  List<dynamic> get filtered => search.isEmpty
      ? all
      : all.where((e) {
          final t = "${e['nama_instansi']} ${e['kode_instansi']}".toLowerCase();
          return t.contains(search.toLowerCase());
        }).toList();

  void _form({Map<String, dynamic>? data}) {
    final isEdit = data != null;
    final namaC = TextEditingController(text: data?['nama_instansi'] ?? '');
    final kodeC = TextEditingController(text: data?['kode_instansi'] ?? '');

    Get.bottomSheet(
      isScrollControlled: true,
      Container(
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
              Center(
                child: Text(isEdit ? "Edit Instansi" : "Tambah Instansi",
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold, color: _brand)),
              ),
              const SizedBox(height: 16),
              const Text("Nama Instansi",
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              TextField(controller: namaC, decoration: _dec("Mis. Sub Regional")),
              const SizedBox(height: 12),
              const Text("Kode Instansi",
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              TextField(controller: kodeC, decoration: _dec("Mis. 01")),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.arrow_back, size: 16),
                      label: const Text("Kembali"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _simpan(isEdit, data?['id_instansi'],
                          namaC.text.trim(), kodeC.text.trim()),
                      icon: const Icon(Icons.save, size: 16),
                      label: const Text("Simpan"),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: _brand, foregroundColor: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _simpan(bool isEdit, int? id, String nama, String kode) async {
    if (nama.isEmpty || kode.isEmpty) {
      Get.snackbar("Lengkapi", "Nama dan kode instansi wajib diisi",
          backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }
    try {
      final headers = {
        'Authorization': 'Bearer ${await _token()}',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      final body = jsonEncode({'nama_instansi': nama, 'kode_instansi': kode});
      final res = isEdit
          ? await http.put(Uri.parse('${ApiEndpoints.masterInstansi}/$id'),
              headers: headers, body: body)
          : await http.post(Uri.parse(ApiEndpoints.masterInstansi),
              headers: headers, body: body);
      final r = jsonDecode(res.body);
      if ((res.statusCode == 200 || res.statusCode == 201) && r['success'] == true) {
        Get.back();
        Get.snackbar("Berhasil", r['message'] ?? "Tersimpan",
            backgroundColor: Colors.green, colorText: Colors.white);
        fetch();
      } else {
        String msg = r['message'] ?? "Gagal";
        if (r['errors'] != null) msg = (r['errors'] as Map).values.first[0].toString();
        Get.snackbar("Gagal", msg, backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar("Error", e.toString(),
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<void> _hapus(int id) async {
    if (!await _konfirmasiHapus()) return;
    try {
      final res = await http.delete(
        Uri.parse('${ApiEndpoints.masterInstansi}/$id'),
        headers: {'Authorization': 'Bearer ${await _token()}', 'Accept': 'application/json'},
      );
      final r = jsonDecode(res.body);
      if (res.statusCode == 200 && r['success'] == true) {
        Get.snackbar("Berhasil", "Instansi dihapus",
            backgroundColor: Colors.green, colorText: Colors.white);
        fetch();
      } else {
        Get.snackbar("Gagal", r['message'] ?? "Gagal menghapus",
            backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar("Error", e.toString(),
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _MasterScaffold(
      tambahLabel: "Tambah Instansi",
      onTambah: () => _form(),
      searchC: searchC,
      onSearch: (v) => setState(() => search = v),
      isLoading: isLoading,
      errorMsg: errorMsg,
      onRetry: fetch,
      child: filtered.isEmpty
          ? const Center(child: Text("Tidak ada data"))
          : RefreshIndicator(
              onRefresh: fetch,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                itemCount: filtered.length,
                itemBuilder: (c, i) {
                  final e = filtered[i];
                  return _kartu(
                    judul: e['nama_instansi'] ?? '-',
                    subtitle: "Kode: ${e['kode_instansi'] ?? '-'}",
                    onEdit: () => _form(data: e),
                    onHapus: () => _hapus(e['id_instansi']),
                  );
                },
              ),
            ),
    );
  }
}

// ======================================================
// TAB 5: DOKUMEN  (CRUD penuh via API /dokumen, termasuk upload file)
// ======================================================
class _MasterDokumen extends StatefulWidget {
  const _MasterDokumen();
  @override
  State<_MasterDokumen> createState() => _MasterDokumenState();
}

class _MasterDokumenState extends State<_MasterDokumen> {
  bool isLoading = true;
  String? errorMsg;
  List<dynamic> all = [];
  String search = '';
  final searchC = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetch();
  }

  @override
  void dispose() {
    searchC.dispose();
    super.dispose();
  }

  Future<void> fetch() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
      errorMsg = null;
    });
    try {
      final res = await http.get(
        Uri.parse('${ApiEndpoints.dokumen}?per_page=100'),
        headers: {'Authorization': 'Bearer ${await _token()}', 'Accept': 'application/json'},
      );
      if (res.statusCode != 200) throw Exception('Gagal memuat (${res.statusCode})');
      final body = jsonDecode(res.body);
      if (!mounted) return;
      setState(() {
        all = body['data'] ?? [];
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        errorMsg = e.toString();
      });
    }
  }

  List<dynamic> get filtered => search.isEmpty
      ? all
      : all.where((e) {
          final t =
              "${e['nama_dokumen']} ${e['no_dokumen']} ${e['instansi_kerjasama']}"
                  .toLowerCase();
          return t.contains(search.toLowerCase());
        }).toList();

    void _form({Map<String, dynamic>? data}) {
    final isEdit = data != null;
    final namaC = TextEditingController(text: data?['nama_dokumen'] ?? '');
    final instansiC =
        TextEditingController(text: data?['instansi_kerjasama'] ?? '');
    final ketC = TextEditingController(text: data?['keterangan_dokumen'] ?? '');
    final berakhirC = TextEditingController(
        text: (data?['berakhir'] ?? '').toString().split('T').first);
    int berlaku = (data?['berlaku'] == 1 || data?['berlaku'] == true) ? 1 : 0;

    // File terpilih dari perangkat (null jika belum memilih).
    PlatformFile? pickedFile;

    Get.bottomSheet(
      isScrollControlled: true,
      StatefulBuilder(builder: (context, setSheet) {
        Future<void> pickFile() async {
          try {
            final result = await FilePicker.platform.pickFiles(
              type: FileType.custom,
              allowedExtensions: const ['pdf', 'doc', 'docx', 'xls', 'xlsx'],
              withData: false, // pakai path, hemat memori
            );
            if (result != null && result.files.isNotEmpty) {
              setSheet(() => pickedFile = result.files.first);
            }
          } catch (e) {
            Get.snackbar("Error", "Gagal memilih file: $e",
                backgroundColor: Colors.red, colorText: Colors.white);
          }
        }

        final fileLamaAda =
            isEdit && (data['file_dokumen'] ?? '').toString().isNotEmpty;

        return Container(
          // 1. Batasi tinggi maksimal
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: SafeArea(
            // 2. SafeArea
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 16),
              child: Padding(
                // 3. Spacer keyboard
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(isEdit ? "Edit Dokumen" : "Tambah Dokumen",
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold, color: _brand)),
                    ),
                    const SizedBox(height: 16),
                    _lbl("Nama Dokumen *"),
                    TextField(controller: namaC, decoration: _dec("Mis. MoU Kerjasama 2026")),
                    const SizedBox(height: 12),
                    _lbl("Instansi Kerjasama"),
                    TextField(controller: instansiC, decoration: _dec("Mis. Bank Sampah Sejahtera")),
                    const SizedBox(height: 12),

                    _lbl(isEdit ? "File Dokumen" : "File Dokumen *"),
                    // Info file lama saat edit
                    if (fileLamaAda)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF2FB),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.insert_drive_file, size: 18, color: _brand),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "File saat ini: ${(data['file_dokumen'] ?? '').toString().split('/').last}",
                                style: const TextStyle(fontSize: 12),
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if ((data['file_url'] ?? '').toString().isNotEmpty)
                              TextButton(
                                onPressed: () => _lihatFile(data['file_url'] ?? ''),
                                child: const Text("Lihat", style: TextStyle(fontSize: 12)),
                              ),
                          ],
                        ),
                      ),
                    // Tombol pilih file
                    OutlinedButton.icon(
                      onPressed: pickFile,
                      icon: const Icon(Icons.upload_file, size: 18),
                      label: Text(
                        pickedFile == null
                            ? (isEdit ? "Pilih File Pengganti (opsional)" : "Pilih File")
                            : pickedFile!.name,
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _brand,
                        side: const BorderSide(color: _brand),
                        minimumSize: const Size(double.infinity, 44),
                        alignment: Alignment.centerLeft,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text(
                        "Format: PDF, DOC, DOCX, XLS, XLSX. Maksimal 10MB."
                        " Kosongkan saat edit jika tidak ingin mengganti.",
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ),
                    const SizedBox(height: 12),

                    _lbl("Tanggal Berakhir"),
                    TextField(
                      controller: berakhirC,
                      readOnly: true,
                      decoration: _dec("YYYY-MM-DD (opsional)").copyWith(
                        suffixIcon: const Icon(Icons.calendar_today, size: 18),
                      ),
                      onTap: () async {
                        final now = DateTime.now();
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: now,
                          firstDate: DateTime(now.year - 2),
                          lastDate: DateTime(now.year + 10),
                        );
                        if (picked != null) {
                          berakhirC.text =
                              "${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    _lbl("Status Berlaku"),
                    DropdownButtonFormField<int>(
                      value: berlaku,
                      isExpanded: true,
                      decoration: _dec(null),
                      items: const [
                        DropdownMenuItem(value: 1, child: Text("Berlaku")),
                        DropdownMenuItem(value: 0, child: Text("Tidak Berlaku")),
                      ],
                      onChanged: (v) => setSheet(() => berlaku = v ?? 1),
                    ),
                    const SizedBox(height: 12),
                    _lbl("Keterangan"),
                    TextField(controller: ketC, decoration: _dec("Keterangan (opsional)"), maxLines: 2),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => Get.back(),
                            icon: const Icon(Icons.arrow_back, size: 16),
                            label: const Text("Kembali"),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _simpan(
                              isEdit: isEdit,
                              id: data?['id'],
                              nama: namaC.text.trim(),
                              instansi: instansiC.text.trim(),
                              berakhir: berakhirC.text.trim(),
                              berlaku: berlaku,
                              keterangan: ketC.text.trim(),
                              file: pickedFile,
                            ),
                            icon: const Icon(Icons.save, size: 16),
                            label: const Text("Simpan"),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: _brand, foregroundColor: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _lbl(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(t, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      );

  /// Unduh file dokumen ke penyimpanan sementara aplikasi lalu buka
  /// langsung dengan aplikasi bawaan perangkat (PDF/Word/Excel).
  Future<void> _lihatFile(String url) async {
    if (url.isEmpty) {
      Get.snackbar("Tidak ada file", "File dokumen tidak tersedia",
          backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }

    // Dialog loading (tidak bisa ditutup manual) selama proses unduh.
    Get.dialog(
      const Center(child: CircularProgressIndicator(color: _brand)),
      barrierDismissible: false,
    );

    try {
      // Nama file: ambil dari URL, bersihkan query bila ada.
      String namaFile = Uri.parse(url).pathSegments.isNotEmpty
          ? Uri.parse(url).pathSegments.last
          : 'dokumen_${DateTime.now().millisecondsSinceEpoch}';
      if (namaFile.contains('?')) namaFile = namaFile.split('?').first;
      if (namaFile.isEmpty) {
        namaFile = 'dokumen_${DateTime.now().millisecondsSinceEpoch}';
      }

      final dir = await getApplicationDocumentsDirectory();
      final savePath = '${dir.path}/$namaFile';

      // Jika file dokumen dilindungi auth, tambahkan header di sini:
      //   options: Options(headers: {'Authorization': 'Bearer ${await _token()}'})
      await Dio().download(url, savePath);

      // Tutup dialog loading sebelum membuka file.
      if (Get.isDialogOpen ?? false) Get.back();

      final result = await OpenFilex.open(savePath);
      if (result.type != ResultType.done) {
        Get.snackbar(
          "Tidak dapat membuka",
          "Tidak ada aplikasi untuk membuka file ini. (${result.message})",
          backgroundColor: Colors.orange, colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      Get.snackbar("Gagal", "Gagal mengunduh file: $e",
          backgroundColor: Colors.red, colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> _simpan({
    required bool isEdit,
    required int? id,
    required String nama,
    required String instansi,
    required String berakhir,
    required int berlaku,
    required String keterangan,
    required PlatformFile? file,
  }) async {
    if (nama.isEmpty) {
      Get.snackbar("Lengkapi", "Nama dokumen wajib diisi",
          backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }
    if (!isEdit && file == null) {
      Get.snackbar("Lengkapi", "File dokumen wajib dipilih",
          backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }

    try {
      // Endpoint: POST /dokumen (tambah) atau POST /dokumen/{id} + _method=PUT (edit).
      final uri = isEdit
          ? Uri.parse('${ApiEndpoints.dokumen}/$id')
          : Uri.parse(ApiEndpoints.dokumen);

      final req = http.MultipartRequest('POST', uri)
        ..headers.addAll({
          'Authorization': 'Bearer ${await _token()}',
          'Accept': 'application/json',
        })
        ..fields['nama_dokumen'] = nama
        ..fields['instansi_kerjasama'] = instansi
        ..fields['berlaku'] = berlaku.toString()
        ..fields['keterangan_dokumen'] = keterangan;

      if (isEdit) req.fields['_method'] = 'PUT';
      if (berakhir.isNotEmpty) req.fields['berakhir'] = berakhir;

      // Lampirkan file bila ada (wajib saat tambah, opsional saat edit).
      if (file != null && file.path != null) {
        req.files.add(await http.MultipartFile.fromPath('file_dokumen', file.path!));
      }

      final streamed = await req.send();
      final res = await http.Response.fromStream(streamed);
      final r = jsonDecode(res.body);

      if ((res.statusCode == 200 || res.statusCode == 201) && r['success'] == true) {
        Get.back();
        Get.snackbar("Berhasil", r['message'] ?? "Tersimpan",
            backgroundColor: Colors.green, colorText: Colors.white);
        fetch();
      } else {
        String msg = r['message'] ?? "Gagal";
        if (r['errors'] != null) msg = (r['errors'] as Map).values.first[0].toString();
        Get.snackbar("Gagal", msg, backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar("Error", e.toString(),
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<void> _hapus(int id) async {
    if (!await _konfirmasiHapus()) return;
    try {
      final res = await http.delete(
        Uri.parse('${ApiEndpoints.dokumen}/$id'),
        headers: {'Authorization': 'Bearer ${await _token()}', 'Accept': 'application/json'},
      );
      final r = jsonDecode(res.body);
      if (res.statusCode == 200 && r['success'] == true) {
        Get.snackbar("Berhasil", "Dokumen dihapus",
            backgroundColor: Colors.green, colorText: Colors.white);
        fetch();
      } else {
        Get.snackbar("Gagal", r['message'] ?? "Gagal menghapus",
            backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar("Error", e.toString(),
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _MasterScaffold(
      tambahLabel: "Tambah Dokumen",
      onTambah: () => _form(),
      searchC: searchC,
      onSearch: (v) => setState(() => search = v),
      isLoading: isLoading,
      errorMsg: errorMsg,
      onRetry: fetch,
      child: filtered.isEmpty
          ? const Center(child: Text("Tidak ada dokumen"))
          : RefreshIndicator(
              onRefresh: fetch,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                itemCount: filtered.length,
                itemBuilder: (c, i) {
                  final e = filtered[i];
                  final berlakuTxt =
                      (e['berlaku'] == 1 || e['berlaku'] == true) ? "Berlaku" : "Tidak Berlaku";
                  final berakhir =
                      (e['berakhir'] ?? '').toString().split('T').first;
                  final sub = StringBuffer();
                  sub.write("No: ${e['no_dokumen'] ?? '-'}");
                  if ((e['instansi_kerjasama'] ?? '').toString().isNotEmpty) {
                    sub.write("\nInstansi: ${e['instansi_kerjasama']}");
                  }
                  sub.write("\n$berlakuTxt");
                  if (berakhir.isNotEmpty) sub.write(" · Berakhir: $berakhir");
                  return _kartuDokumen(
                    judul: e['nama_dokumen'] ?? '-',
                    subtitle: sub.toString(),
                    fileUrl: (e['file_url'] ?? '').toString(),
                    onLihat: () => _lihatFile(e['file_url'] ?? ''),
                    onEdit: () => _form(data: e),
                    onHapus: () => _hapus(e['id']),
                  );
                },
              ),
            ),
    );
  }
}

// Kartu khusus dokumen: ada tombol "Lihat File" bila tersedia.
Widget _kartuDokumen({
  required String judul,
  String? subtitle,
  required String fileUrl,
  required VoidCallback onLihat,
  required VoidCallback onEdit,
  required VoidCallback onHapus,
}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2)),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(judul,
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.bold, color: _brand)),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.black54)),
        ],
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (fileUrl.isNotEmpty) ...[
              OutlinedButton.icon(
                onPressed: onLihat,
                icon: const Icon(Icons.picture_as_pdf, size: 14),
                label: const Text("Lihat"),
                style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.teal,
                    side: const BorderSide(color: Colors.teal),
                    padding: const EdgeInsets.symmetric(horizontal: 12)),
              ),
              const SizedBox(width: 8),
            ],
            OutlinedButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit, size: 14),
              label: const Text("Edit"),
              style: OutlinedButton.styleFrom(
                  foregroundColor: _brand,
                  side: const BorderSide(color: _brand),
                  padding: const EdgeInsets.symmetric(horizontal: 12)),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: onHapus,
              icon: const Icon(Icons.delete, size: 14),
              label: const Text("Hapus"),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12)),
            ),
          ],
        ),
      ],
    ),
  );
}

/*
// ======================================================
// TAB 6: EXPORT EXCEL
// ======================================================
class _TabExport extends StatefulWidget {
  const _TabExport();
  @override
  State<_TabExport> createState() => _TabExportState();
}

class _TabExportState extends State<_TabExport> {
  int tahun = DateTime.now().month >= 7
      ? DateTime.now().year
      : DateTime.now().year - 1;

  // Jenis laporan yang tersedia (mengikuti export sisi web).
  String jenisLaporan = 'lengkap'; // 'lengkap' | 'bulanan' | 'neraca'

  bool loading = false;

  /// Mengunduh file Excel dari endpoint export (dibuat di backend) ke
  /// penyimpanan aplikasi, lalu membukanya langsung dengan aplikasi
  /// pembuka Excel di perangkat. Token dikirim melalui header Authorization
  /// (endpoint export dilindungi auth:sanctum).
  Future<void> _export() async {
    setState(() => loading = true);

    // Dialog loading selama proses unduh (tidak bisa ditutup manual).
    Get.dialog(
      const Center(child: CircularProgressIndicator(color: _brand)),
      barrierDismissible: false,
    );

    try {
      final token = await _token();

      // Nama file lokal: sertakan tahun & tipe agar mudah dikenali.
      final namaFile =
          'Laporan_${jenisLaporan}_${tahun}-${tahun + 1}.xlsx';
      final dir = await getApplicationDocumentsDirectory();
      final savePath = '${dir.path}/$namaFile';

      final uri = Uri.parse(ApiEndpoints.exportLaporan).replace(
        queryParameters: {
          'tahun': tahun.toString(),
          'tipe': jenisLaporan,
        },
      ).toString();

      await Dio().download(
        uri,
        savePath,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept':
                'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          },
          // Terima status apa pun agar bisa menampilkan pesan error
          // dari server bila bukan file (mis. 401/500).
          followRedirects: true,
          validateStatus: (s) => s != null && s < 500,
        ),
      );

      // Tutup dialog loading sebelum membuka file.
      if (Get.isDialogOpen ?? false) Get.back();

      final result = await OpenFilex.open(savePath);
      if (result.type != ResultType.done) {
        Get.snackbar(
          "Tidak dapat membuka",
          "File terunduh, tetapi tidak ada aplikasi untuk membuka Excel. "
              "Silakan pasang aplikasi seperti WPS Office atau Google Sheets. "
              "(${result.message})",
          backgroundColor: Colors.orange, colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 5),
        );
      }
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      Get.snackbar("Gagal", "Gagal mengunduh laporan: $e",
          backgroundColor: Colors.red, colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tahunSekarang = DateTime.now().year;
    final opsiTahun =
        List<int>.generate(6, (i) => tahunSekarang - i); // 6 tahun terakhir

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.file_download_outlined, color: _brand),
                    SizedBox(width: 8),
                    Text("Export Laporan Excel",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold, color: _brand)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  "Unduh rekapitulasi data sampah dalam format Excel (.xlsx). "
                  "File akan tersimpan di folder Download perangkat.",
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const Divider(height: 24),

                _lbl("Tahun Periode"),
                DropdownButtonFormField<int>(
                  value: tahun,
                  isExpanded: true,
                  decoration: _dec(null),
                  items: opsiTahun
                      .map((y) => DropdownMenuItem(
                            value: y,
                            child: Text("$y / ${y + 1}"),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => tahun = v ?? tahun),
                ),
                const SizedBox(height: 12),

                _lbl("Jenis Laporan"),
                DropdownButtonFormField<String>(
                  value: jenisLaporan,
                  isExpanded: true,
                  decoration: _dec(null),
                  items: const [
                    DropdownMenuItem(
                        value: 'lengkap',
                        child: Text("Laporan Lengkap (Neraca + Bulanan)")),
                    DropdownMenuItem(
                        value: 'bulanan',
                        child: Text("Laporan Bulanan (Harian per Bulan)")),
                    DropdownMenuItem(
                        value: 'neraca',
                        child: Text("Laporan Neraca")),
                  ],
                  onChanged: (v) => setState(() => jenisLaporan = v ?? 'lengkap'),
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: loading ? null : _export,
                    icon: loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.download),
                    label: Text(loading ? "Memproses..." : "Export & Unduh"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _brand,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF2FB),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, size: 18, color: _brand),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Periode tahunan mengikuti tahun anggaran (Juli s.d. Juni tahun berikutnya). "
                    "Unduhan diproses melalui browser perangkat.",
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _lbl(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(t, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      );
}

*/

// ======================================================
// KOMPONEN BERSAMA
// ======================================================
class _MasterScaffold extends StatelessWidget {
  final String tambahLabel;
  final VoidCallback onTambah;
  final TextEditingController searchC;
  final ValueChanged<String> onSearch;
  final bool isLoading;
  final String? errorMsg;
  final VoidCallback onRetry;
  final Widget child;

  const _MasterScaffold({
    required this.tambahLabel,
    required this.onTambah,
    required this.searchC,
    required this.onSearch,
    required this.isLoading,
    required this.errorMsg,
    required this.onRetry,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: searchC,
                      decoration: InputDecoration(
                        hintText: "Cari data...",
                        prefixIcon: const Icon(Icons.search),
                        isDense: true,
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onChanged: onSearch,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onTambah,
                  icon: const Icon(Icons.add),
                  label: Text(tambahLabel),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _biruMuda,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : errorMsg != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
                          const SizedBox(height: 8),
                          Text(errorMsg!, style: const TextStyle(color: Colors.grey)),
                          const SizedBox(height: 12),
                          ElevatedButton(onPressed: onRetry, child: const Text("Coba lagi")),
                        ],
                      ),
                    )
                  : child,
        ),
      ],
    );
  }
}

Widget _kartu({
  required String judul,
  String? subtitle,
  required VoidCallback onEdit,
  required VoidCallback onHapus,
}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2)),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(judul,
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.bold, color: _brand)),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.black54)),
        ],
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit, size: 14),
              label: const Text("Edit"),
              style: OutlinedButton.styleFrom(
                  foregroundColor: _brand,
                  side: const BorderSide(color: _brand),
                  padding: const EdgeInsets.symmetric(horizontal: 12)),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: onHapus,
              icon: const Icon(Icons.delete, size: 14),
              label: const Text("Hapus"),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12)),
            ),
          ],
        ),
      ],
    ),
  );
}