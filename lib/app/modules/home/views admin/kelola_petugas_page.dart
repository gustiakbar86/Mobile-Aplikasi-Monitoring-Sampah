import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../app/utils/api_endpoints.dart';

class KelolaPetugasPage extends StatefulWidget {
  const KelolaPetugasPage({super.key});

  @override
  State<KelolaPetugasPage> createState() => _KelolaPetugasPageState();
}

class _KelolaPetugasPageState extends State<KelolaPetugasPage> {
  static const Color brand = Color(0xFF1A3A6B);
  static const Color biruMuda = Color(0xFF5B9BD5);

  bool isLoading = true;
  String? errorMsg;
  List<dynamic> petugas = [];
  List<Map<String, dynamic>> instansiList = [];

  int currentPage = 1;
  int lastPage = 1;
  String search = '';
  final TextEditingController searchC = TextEditingController();

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    searchC.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    await fetchInstansi();
    await fetchPetugas();
  }

  Future<String> _token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? '';
  }

  Future<void> fetchInstansi() async {
    try {
      final res = await http.get(
        Uri.parse(ApiEndpoints.masterInstansi),
        headers: {'Authorization': 'Bearer ${await _token()}', 'Accept': 'application/json'},
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final List<dynamic> data = body['data'] ?? [];
        if (!mounted) return;
        setState(() {
          instansiList = data
              .map((e) => {
                    'id_instansi': e['id_instansi'],
                    'nama_instansi': e['nama_instansi'] ?? '-',
                  })
              .toList();
        });
      }
    } catch (_) {}
  }

  Future<void> fetchPetugas() async {
    setState(() {
      isLoading = true;
      errorMsg = null;
    });
    try {
      final searchParam = search.isEmpty ? '' : '&search=${Uri.encodeComponent(search)}';
      final res = await http.get(
        Uri.parse('${ApiEndpoints.petugas}?per_page=10&page=$currentPage$searchParam'),
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
        petugas = body['data'] ?? [];
        lastPage = body['last_page'] ?? 1;
        currentPage = body['current_page'] ?? 1;
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

  void _doSearch() {
    setState(() {
      search = searchC.text.trim();
      currentPage = 1;
    });
    fetchPetugas();
  }

  Future<void> _hapus(int id, String nama) async {
    final konfirmasi = await Get.dialog<bool>(
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
            const Text("Konfirmasi",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("Apakah anda yakin ingin menghapus petugas $nama?",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54)),
          ],
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () => Get.back(result: true),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red, foregroundColor: Colors.white),
                child: const Text("Ya, Hapus"),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () => Get.back(result: false),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey, foregroundColor: Colors.white),
                child: const Text("Batal"),
              ),
            ],
          ),
        ],
      ),
    );

    if (konfirmasi != true) return;

    try {
      final res = await http.delete(
        Uri.parse('${ApiEndpoints.petugas}/$id'),
        headers: {'Authorization': 'Bearer ${await _token()}', 'Accept': 'application/json'},
      );
      final body = jsonDecode(res.body);
      if (res.statusCode == 200 && body['success'] == true) {
        Get.snackbar("Berhasil", "Petugas berhasil dihapus",
            backgroundColor: Colors.green, colorText: Colors.white);
        fetchPetugas();
      } else {
        Get.snackbar("Gagal", body['message'] ?? "Gagal menghapus",
            backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar("Error", e.toString(),
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  // Dibuat async: selalu memuat ulang daftar instansi terbaru sebelum form dibuka,
  // agar instansi yang baru ditambahkan di menu master ikut tampil di dropdown.
  Future<void> _formPetugas({Map<String, dynamic>? data}) async {
    await fetchInstansi();

    final isEdit = data != null;
    final emailC = TextEditingController(text: data?['email'] ?? '');
    final namaC = TextEditingController(text: data?['name'] ?? '');
    final passC = TextEditingController();
    final pass2C = TextEditingController();
    int? instansiId = data?['id_instansi'];
    // Cegah error dropdown bila instansi lama sudah tidak ada di daftar
    if (instansiId != null &&
        !instansiList.any((e) => e['id_instansi'] == instansiId)) {
      instansiId = null;
    }

    Get.bottomSheet(
      isScrollControlled: true,
      StatefulBuilder(
        builder: (context, setSheet) {
          return Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
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
                    child: Text(isEdit ? "Edit Petugas" : "Tambah Petugas",
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: brand)),
                  ),
                  const SizedBox(height: 16),
                  _field("Email", emailC, hint: "email@example.com",
                      keyboard: TextInputType.emailAddress),
                  _field("Nama Lengkap", namaC, hint: "Nama lengkap petugas"),
                  const Text("Instansi",
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<int>(
                    value: instansiId,
                    isExpanded: true,
                    decoration: _dec("-- Pilih Instansi --"),
                    items: instansiList
                        .map((e) => DropdownMenuItem<int>(
                              value: e['id_instansi'] as int,
                              child: Text(e['nama_instansi']),
                            ))
                        .toList(),
                    onChanged: (v) => setSheet(() => instansiId = v),
                  ),
                  const SizedBox(height: 12),
                  _field("Password", passC,
                      hint: isEdit
                          ? "Kosongkan jika tidak ingin mengubah"
                          : "Minimal 6 karakter",
                      obscure: true),
                  _field("Konfirmasi Password", pass2C,
                      hint: "Ulangi password", obscure: true),
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
                            email: emailC.text.trim(),
                            nama: namaC.text.trim(),
                            instansiId: instansiId,
                            pass: passC.text,
                            pass2: pass2C.text,
                          ),
                          icon: const Icon(Icons.save, size: 16),
                          label: const Text("Simpan"),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: brand,
                              foregroundColor: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _simpan({
    required bool isEdit,
    int? id,
    required String email,
    required String nama,
    required int? instansiId,
    required String pass,
    required String pass2,
  }) async {
    if (email.isEmpty || nama.isEmpty || instansiId == null) {
      Get.snackbar("Lengkapi Data", "Email, nama, dan instansi wajib diisi",
          backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }
    if (!isEdit && pass.isEmpty) {
      Get.snackbar("Lengkapi Data", "Password wajib diisi",
          backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }
    if (pass.isNotEmpty && pass != pass2) {
      Get.snackbar("Tidak Cocok", "Konfirmasi password tidak sama",
          backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }

    try {
      http.Response res;
      final headers = {
        'Authorization': 'Bearer ${await _token()}',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      if (isEdit) {
        res = await http.put(
          Uri.parse('${ApiEndpoints.petugas}/$id'),
          headers: headers,
          body: jsonEncode({
            'name': nama,
            'email': email,
            'id_instansi': instansiId,
            'password': pass,
          }),
        );
      } else {
        res = await http.post(
          Uri.parse(ApiEndpoints.registerPetugas),
          headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
          body: jsonEncode({
            'name': nama,
            'email': email,
            'password': pass,
            'id_instansi': instansiId,
          }),
        );
      }

      final body = jsonDecode(res.body);
      if ((res.statusCode == 200 || res.statusCode == 201) &&
          body['success'] == true) {
        Get.back();
        Get.snackbar("Berhasil",
            isEdit ? "Petugas berhasil diperbarui" : "Petugas berhasil ditambahkan",
            backgroundColor: Colors.green, colorText: Colors.white);
        fetchPetugas();
      } else {
        String msg = body['message'] ?? "Gagal menyimpan data";
        if (body['errors'] != null) {
          final errs = body['errors'] as Map<String, dynamic>;
          msg = errs.values.first[0].toString();
        }
        Get.snackbar("Gagal", msg,
            backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar("Error", e.toString(),
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      appBar: AppBar(
        backgroundColor: brand,
        foregroundColor: Colors.white,
        title: const Text("Kelola Data Petugas", style: TextStyle(fontSize: 16)),
      ),
      body: Column(
        children: [
          // Pencarian + Tambah
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
                          hintText: "Cari nama atau email...",
                          prefixIcon: const Icon(Icons.search),
                          isDense: true,
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        onSubmitted: (_) => _doSearch(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _doSearch,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: brand, foregroundColor: Colors.white),
                      child: const Text("Cari"),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _formPetugas(),
                    icon: const Icon(Icons.add),
                    label: const Text("Tambah Petugas"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: biruMuda,
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
                    ? _buildError()
                    : petugas.isEmpty
                        ? const Center(child: Text("Tidak ada data petugas"))
                        : RefreshIndicator(
                            onRefresh: fetchPetugas,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                              itemCount: petugas.length,
                              itemBuilder: (context, i) => _kartuPetugas(petugas[i]),
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
                    onPressed: currentPage > 1
                        ? () {
                            setState(() => currentPage--);
                            fetchPetugas();
                          }
                        : null,
                    child: const Text("Sebelumnya"),
                  ),
                  Text("$currentPage / $lastPage",
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: currentPage < lastPage
                        ? () {
                            setState(() => currentPage++);
                            fetchPetugas();
                          }
                        : null,
                    child: const Text("Selanjutnya"),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _kartuPetugas(Map<String, dynamic> p) {
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
          Text(p['name'] ?? '-',
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.bold, color: brand)),
          const SizedBox(height: 4),
          Row(children: [
            const Icon(Icons.email_outlined, size: 14, color: Colors.grey),
            const SizedBox(width: 6),
            Expanded(
                child: Text(p['email'] ?? '-',
                    style: const TextStyle(fontSize: 13, color: Colors.black87))),
          ]),
          const SizedBox(height: 2),
          Row(children: [
            const Icon(Icons.business_outlined, size: 14, color: Colors.grey),
            const SizedBox(width: 6),
            Text(p['nama_instansi'] ?? '-',
                style: const TextStyle(fontSize: 13, color: Colors.black54)),
          ]),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: () => _formPetugas(data: p),
                icon: const Icon(Icons.edit, size: 14),
                label: const Text("Edit"),
                style: OutlinedButton.styleFrom(
                    foregroundColor: brand,
                    side: const BorderSide(color: brand),
                    padding: const EdgeInsets.symmetric(horizontal: 12)),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _hapus(p['id'], p['name'] ?? ''),
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

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
          const SizedBox(height: 8),
          Text(errorMsg ?? "Terjadi kesalahan",
              style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: fetchPetugas, child: const Text("Coba lagi")),
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController c,
      {String? hint, bool obscure = false, TextInputType? keyboard}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        TextField(
          controller: c,
          obscureText: obscure,
          keyboardType: keyboard,
          decoration: _dec(hint),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  InputDecoration _dec(String? hint) {
    return InputDecoration(
      hintText: hint,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}