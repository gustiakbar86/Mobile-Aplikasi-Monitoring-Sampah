import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../app/utils/api_endpoints.dart';

class KelolaMasterPage extends StatelessWidget {
  const KelolaMasterPage({super.key});

  static const Color brand = Color(0xFF1A3A6B);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F4F7),
        appBar: AppBar(
          backgroundColor: brand,
          foregroundColor: Colors.white,
          title: const Text("Kelola Data Master", style: TextStyle(fontSize: 16)),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: "Lokasi"),
              Tab(text: "Jenis"),
              Tab(text: "Tujuan"),
              Tab(text: "Instansi"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _MasterLokasi(),
            _MasterJenis(),
            _MasterTujuan(),
            _MasterInstansi(),
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
    // Kategori tujuan = dropdown tetap (samakan dengan web): bank_sampah / tpa
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
                  return _kartu(
                    judul: e['nama_tujuan'] ?? '-',
                    subtitle:
                        "${e['kategori_tujuan'] ?? '-'} · $statusTxt${(e['alamat'] ?? '').toString().isEmpty ? '' : '\n${e['alamat']}'}",
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