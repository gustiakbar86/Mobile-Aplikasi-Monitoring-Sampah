import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../utils/api_endpoints.dart';

class InputSampahPage extends StatefulWidget {
  const InputSampahPage({super.key});

  @override
  State<InputSampahPage> createState() => _InputSampahPageState();
}

class _InputSampahPageState extends State<InputSampahPage>
    with SingleTickerProviderStateMixin {

  late TabController _tabController;

  // =========================================================
  // KATEGORI (tetap, sesuai aturan bisnis & web)
  //  - Terkelola : hanya Organik & Anorganik
  //  - Diserahkan: hanya Residu
  // Turunan (jenis) tetap diambil dinamis dari master.
  // =========================================================
  static const List<Map<String, String>> kategoriTerkelola = [
    {"id": "Organik", "nama": "Organik"},
    {"id": "Anorganik", "nama": "Anorganik"},
  ];
  static const List<Map<String, String>> kategoriDiserahkan = [
    {"id": "Residu", "nama": "Residu"},
  ];

  // =========================================================
  // DATA MASTER (diambil dinamis dari API /master-data)
  // =========================================================
  List<Map<String, dynamic>> lokasiList = [];
  List<Map<String, dynamic>> jenisAll   = []; // id_jenis, nama_jenis, kategori_jenis
  List<Map<String, dynamic>> tujuanList = [];
  bool isLoadingMaster = true;
  String? masterError;

  // =========================
  // STATE FORM TERKELOLA
  // =========================
  final TextEditingController beratTerkelolaC = TextEditingController();
  DateTime tglTerkelola = DateTime.now();
  int? selectedLokasiTerkelola;
  String? selectedKategoriTerkelola;
  int? selectedJenisTerkelola;
  File? fotoTerkelola;
  bool isLoadingTerkelola = false;

  // =========================
  // STATE FORM DISERAHKAN
  // =========================
  final TextEditingController beratDiserahkanC = TextEditingController();
  DateTime tglDiserahkan = DateTime.now();
  int? selectedLokasiDiserahkan;
  String? selectedKategoriDiserahkan;
  int? selectedJenisDiserahkan;
  int? selectedTujuan;
  File? fotoDiserahkan;
  bool isLoadingDiserahkan = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchMasterData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    beratTerkelolaC.dispose();
    beratDiserahkanC.dispose();
    super.dispose();
  }

  // =========================================================
  // AMBIL DATA MASTER DARI API (/master-data)
  // Endpoint ini satu level dengan sampah-terkelola, jadi URL-nya
  // diturunkan dari ApiEndpoints.sampahTerkelola agar tidak perlu
  // konstanta baru. (Boleh diganti ke ApiEndpoints.masterData.)
  // =========================================================
  String get _masterDataUrl => ApiEndpoints.sampahTerkelola
      .replaceFirst(RegExp(r'/sampah-terkelola/?$'), '/master-data');

  int? _asInt(dynamic v) => v is int ? v : int.tryParse('$v');

  // Tujuan dianggap aktif jika status = 1/true
  bool _isActive(dynamic s) => s == true || '$s' == '1';

  List<Map<String, dynamic>> _toListMap(dynamic raw) {
    if (raw is List) {
      return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return [];
  }

  Future<void> fetchMasterData() async {
    setState(() {
      isLoadingMaster = true;
      masterError = null;
    });

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
        setState(() {
          lokasiList = _toListMap(data['lokasi_asal']);
          jenisAll   = _toListMap(data['jenis']);
          tujuanList = _toListMap(data['tujuan_sampah']);
          isLoadingMaster = false;
        });
      } else {
        setState(() {
          masterError = body['message']?.toString() ?? 'Gagal memuat data master';
          isLoadingMaster = false;
        });
      }
    } catch (e) {
      setState(() {
        masterError = e.toString();
        isLoadingMaster = false;
      });
    }
  }

  // Filter jenis berdasarkan kategori terpilih (case-insensitive)
  List<Map<String, dynamic>> jenisByKategori(String? kategori) {
    if (kategori == null) return [];
    final k = kategori.toLowerCase();
    return jenisAll
        .where((e) => '${e['kategori_jenis'] ?? ''}'.toLowerCase() == k)
        .toList();
  }

  // =========================
  // PILIH TANGGAL
  // =========================
  Future<void> pickDate({required bool isTerkelola}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isTerkelola ? tglTerkelola : tglDiserahkan,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1A3A6B),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isTerkelola) {
          tglTerkelola = picked;
        } else {
          tglDiserahkan = picked;
        }
      });
    }
  }

  // =========================
  // PILIH FOTO
  // =========================
  Future<void> pickFoto({required bool isTerkelola}) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.rear,
      imageQuality: 70,
      maxWidth: 1024,
    );

    if (picked != null) {
      setState(() {
        if (isTerkelola) {
          fotoTerkelola = File(picked.path);
        } else {
          fotoDiserahkan = File(picked.path);
        }
      });
    }
  }

  // =========================
  // SUBMIT TERKELOLA
  // =========================
  Future<void> submitTerkelola() async {
    if (selectedLokasiTerkelola == null ||
        selectedJenisTerkelola == null ||
        beratTerkelolaC.text.trim().isEmpty) {
      Get.snackbar("Peringatan", "Lengkapi semua field yang wajib diisi",
          backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }

    setState(() => isLoadingTerkelola = true);

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      String? idUser = prefs.getString('id_user') ?? '1';

      final request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiEndpoints.sampahTerkelola),
      );

      request.headers['Authorization'] = 'Bearer $token';

      request.fields['_method']      = 'POST';
      request.fields['id_user']      = idUser;
      request.fields['id_lokasi']    = '$selectedLokasiTerkelola';
      request.fields['id_jenis']     = '$selectedJenisTerkelola';
      request.fields['jumlah_berat'] = beratTerkelolaC.text.trim();
      request.fields['tgl']          =
          DateFormat('yyyy-MM-dd').format(tglTerkelola);

      if (fotoTerkelola != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'foto_kelola',
          fotoTerkelola!.path,
        ));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        Get.snackbar(
          "Berhasil",
          "Data sampah terkelola berhasil disimpan",
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        _resetFormTerkelola();
      } else {
        Get.snackbar("Gagal", data['message'] ?? "Terjadi kesalahan",
            backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar("Error", e.toString(),
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      setState(() => isLoadingTerkelola = false);
    }
  }

  // =========================
  // SUBMIT DISERAHKAN
  // =========================
  Future<void> submitDiserahkan() async {
    if (selectedLokasiDiserahkan == null ||
        selectedJenisDiserahkan == null ||
        selectedTujuan == null ||
        beratDiserahkanC.text.trim().isEmpty) {
      Get.snackbar("Peringatan", "Lengkapi semua field yang wajib diisi",
          backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }

    setState(() => isLoadingDiserahkan = true);

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      String? idUser = prefs.getString('id_user') ?? '1';

      final request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiEndpoints.sampahDiserahkan),
      );

      request.headers['Authorization'] = 'Bearer $token';

      request.fields['_method']        = 'POST';
      request.fields['id_user']        = idUser;
      request.fields['id_lokasi']      = '$selectedLokasiDiserahkan';
      request.fields['id_jenis']       = '$selectedJenisDiserahkan';
      request.fields['id_tujuan']      = '$selectedTujuan';
      request.fields['jumlah_berat']   = beratDiserahkanC.text.trim();
      request.fields['tgl_diserahkan'] =
          DateFormat('yyyy-MM-dd').format(tglDiserahkan);

      if (fotoDiserahkan != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'foto_diserahkan',
          fotoDiserahkan!.path,
        ));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        Get.snackbar(
          "Berhasil",
          "Data sampah diserahkan berhasil disimpan",
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        _resetFormDiserahkan();
      } else {
        Get.snackbar("Gagal", data['message'] ?? "Terjadi kesalahan",
            backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar("Error", e.toString(),
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      setState(() => isLoadingDiserahkan = false);
    }
  }

  // =========================
  // RESET FORM
  // =========================
  void _resetFormTerkelola() {
    setState(() {
      selectedLokasiTerkelola   = null;
      selectedKategoriTerkelola = null;
      selectedJenisTerkelola    = null;
      fotoTerkelola             = null;
      tglTerkelola              = DateTime.now();
      beratTerkelolaC.clear();
    });
  }

  void _resetFormDiserahkan() {
    setState(() {
      selectedLokasiDiserahkan   = null;
      selectedKategoriDiserahkan = null;
      selectedJenisDiserahkan    = null;
      selectedTujuan             = null;
      fotoDiserahkan             = null;
      tglDiserahkan              = DateTime.now();
      beratDiserahkanC.clear();
    });
  }

  // =========================
  // BUILD
  // =========================
  @override
  Widget build(BuildContext context) {
    // 1. Hapus SafeArea, langsung gunakan Column
    return Column(
      children: [
        // Header biru
        Container(
          width: double.infinity,
          color: const Color(0xFF1A3A6B),
          // 2. Sesuaikan padding agar memperhitungkan tinggi status bar
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 12, // 👈 Padding atas dinamis
            bottom: 12,
            left: 16,
            right: 16,
          ),
          child: const Text(
            "Input Data Sampah",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        if (isLoadingMaster)
          const Expanded(
            child: Center(
              child: CircularProgressIndicator(color: Color(0xFF1A3A6B)),
            ),
          )
        else if (masterError != null)
          Expanded(child: _buildErrorState())
        else ...[
          // Tab bar
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF1A3A6B),
              unselectedLabelColor: Colors.grey,
              indicatorColor: const Color(0xFF1A3A6B),
              labelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              tabs: const [
                Tab(text: "Sampah Terkelola"),
                Tab(text: "Sampah Diserahkan"),
              ],
            ),
          ),

          // Konten
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildFormTerkelola(),
                _buildFormDiserahkan(),
              ],
            ),
          ),
        ],
      ],
    ); // 3. Pastikan penutupnya cukup menggunakan titik koma di sini (karena SafeArea dihapus)
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              "Gagal memuat data master.\n$masterError",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: fetchMasterData,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A3A6B),
              ),
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text("Coba Lagi",
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // =========================
  // FORM TERKELOLA
  // =========================
  Widget _buildFormTerkelola() {
    final jenisItems = jenisByKategori(selectedKategoriTerkelola);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          const SizedBox(height: 8),

          // Tanggal
          _buildLabel("Tanggal", required: true),
          _buildDateField(
            date: tglTerkelola,
            onTap: () => pickDate(isTerkelola: true),
          ),

          const SizedBox(height: 16),

          // Lokasi Asal
          _buildLabel("Lokasi Asal", required: true),
          _buildDropdown<int>(
            hint: "-- Pilih Lokasi --",
            value: selectedLokasiTerkelola,
            items: lokasiList.map((e) {
              return DropdownMenuItem<int>(
                value: _asInt(e['id_lokasi']),
                child: Text('${e['nama_lokasi']}',
                    style: const TextStyle(fontSize: 14)),
              );
            }).toList(),
            onChanged: (val) => setState(() => selectedLokasiTerkelola = val),
          ),

          const SizedBox(height: 16),

          // Kategori Jenis (tetap: Organik / Anorganik)
          _buildLabel("Kategori Jenis", required: true),
          _buildDropdown<String>(
            hint: "-- Pilih Kategori --",
            value: selectedKategoriTerkelola,
            items: kategoriTerkelola.map((e) {
              return DropdownMenuItem<String>(
                value: e['id'],
                child: Text(e['nama']!, style: const TextStyle(fontSize: 14)),
              );
            }).toList(),
            onChanged: (val) => setState(() {
              selectedKategoriTerkelola = val;
              selectedJenisTerkelola = null;
            }),
          ),

          const SizedBox(height: 16),

          // Jenis Sampah (dinamis dari master, sesuai kategori)
          _buildLabel("Jenis Sampah", required: true),
          _buildDropdown<int>(
            hint: "-- Pilih Jenis --",
            value: selectedJenisTerkelola,
            enabled: selectedKategoriTerkelola != null,
            items: jenisItems.map((e) {
              return DropdownMenuItem<int>(
                value: _asInt(e['id_jenis']),
                child: Text('${e['nama_jenis']}',
                    style: const TextStyle(fontSize: 14)),
              );
            }).toList(),
            onChanged: (val) => setState(() => selectedJenisTerkelola = val),
          ),

          const SizedBox(height: 16),

          // Berat
          _buildLabel("Berat (Kg)", required: true),
          _buildTextField(
            controller: beratTerkelolaC,
            hint: "0.00",
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),

          const SizedBox(height: 16),

          // Foto
          _buildLabel("Foto"),
          _buildFotoField(
            foto: fotoTerkelola,
            onTap: () => pickFoto(isTerkelola: true),
            onRemove: () => setState(() => fotoTerkelola = null),
          ),

          const SizedBox(height: 24),

          // Tombol Simpan
          _buildSubmitButton(
            isLoading: isLoadingTerkelola,
            onPressed: submitTerkelola,
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // =========================
  // FORM DISERAHKAN
  // =========================
  Widget _buildFormDiserahkan() {
    final jenisItems = jenisByKategori(selectedKategoriDiserahkan);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          const SizedBox(height: 8),

          // Tanggal
          _buildLabel("Tanggal", required: true),
          _buildDateField(
            date: tglDiserahkan,
            onTap: () => pickDate(isTerkelola: false),
          ),

          const SizedBox(height: 16),

          // Lokasi Asal
          _buildLabel("Lokasi Asal", required: true),
          _buildDropdown<int>(
            hint: "-- Pilih Lokasi --",
            value: selectedLokasiDiserahkan,
            items: lokasiList.map((e) {
              return DropdownMenuItem<int>(
                value: _asInt(e['id_lokasi']),
                child: Text('${e['nama_lokasi']}',
                    style: const TextStyle(fontSize: 14)),
              );
            }).toList(),
            onChanged: (val) =>
                setState(() => selectedLokasiDiserahkan = val),
          ),

          const SizedBox(height: 16),

          // Kategori Jenis (dikunci: hanya Residu)
          _buildLabel("Kategori Jenis", required: true),
          _buildDropdown<String>(
            hint: "-- Pilih Kategori --",
            value: selectedKategoriDiserahkan,
            items: kategoriDiserahkan.map((e) {
              return DropdownMenuItem<String>(
                value: e['id'],
                child: Text(e['nama']!, style: const TextStyle(fontSize: 14)),
              );
            }).toList(),
            onChanged: (val) => setState(() {
              selectedKategoriDiserahkan = val;
              selectedJenisDiserahkan = null;
            }),
          ),

          const SizedBox(height: 16),

          // Jenis Sampah (dinamis dari master, kategori Residu)
          _buildLabel("Jenis Sampah", required: true),
          _buildDropdown<int>(
            hint: "-- Pilih Jenis --",
            value: selectedJenisDiserahkan,
            enabled: selectedKategoriDiserahkan != null,
            items: jenisItems.map((e) {
              return DropdownMenuItem<int>(
                value: _asInt(e['id_jenis']),
                child: Text('${e['nama_jenis']}',
                    style: const TextStyle(fontSize: 14)),
              );
            }).toList(),
            onChanged: (val) =>
                setState(() => selectedJenisDiserahkan = val),
          ),

          const SizedBox(height: 16),

          // Tujuan Diserahkan (dinamis dari master)
          _buildLabel("Tujuan Diserahkan", required: true),
          _buildDropdown<int>(
            hint: "-- Pilih Tujuan --",
            value: selectedTujuan,
            items: tujuanList.where((e) => _isActive(e['status'])).map((e) {
              return DropdownMenuItem<int>(
                value: _asInt(e['id_tujuan']),
                child: Text('${e['nama_tujuan']}',
                    style: const TextStyle(fontSize: 14)),
              );
            }).toList(),
            onChanged: (val) => setState(() => selectedTujuan = val),
          ),

          const SizedBox(height: 16),

          // Berat
          _buildLabel("Berat (Kg)", required: true),
          _buildTextField(
            controller: beratDiserahkanC,
            hint: "0.00",
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),

          const SizedBox(height: 16),

          // Foto
          _buildLabel("Foto"),
          _buildFotoField(
            foto: fotoDiserahkan,
            onTap: () => pickFoto(isTerkelola: false),
            onRemove: () => setState(() => fotoDiserahkan = null),
          ),

          const SizedBox(height: 24),

          // Tombol Simpan
          _buildSubmitButton(
            isLoading: isLoadingDiserahkan,
            onPressed: submitDiserahkan,
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // =========================
  // SHARED WIDGETS
  // =========================
  Widget _buildSubmitButton({
    required bool isLoading,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1A3A6B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        icon: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.save, color: Colors.white),
        label: Text(
          isLoading ? "Menyimpan..." : "Simpan",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (required)
            const Text(
              " *",
              style: TextStyle(color: Colors.red, fontSize: 14),
            ),
        ],
      ),
    );
  }

  Widget _buildDateField({
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(8),
          color: Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              DateFormat('dd/MM/yyyy').format(date),
              style: const TextStyle(fontSize: 14),
            ),
            const Icon(Icons.calendar_today,
                size: 18, color: Color(0xFF1A3A6B)),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String hint,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required Function(T?) onChanged,
    bool enabled = true,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(
          color: enabled ? Colors.grey.shade400 : Colors.grey.shade300,
        ),
        borderRadius: BorderRadius.circular(8),
        color: enabled ? Colors.white : Colors.grey.shade100,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(hint,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
          isExpanded: true,
          items: items,
          onChanged: enabled ? onChanged : null,
          style: const TextStyle(fontSize: 14, color: Colors.black),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade500),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF1A3A6B), width: 1.5),
        ),
      ),
    );
  }

  Widget _buildFotoField({
    required File? foto,
    required VoidCallback onTap,
    required VoidCallback onRemove,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // Tombol pilih foto
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            child: Row(
              children: [
                const Icon(Icons.camera_alt,
                    size: 18, color: Color(0xFF1A3A6B)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    foto != null ? foto.path.split('/').last : "Ambil Foto (Kamera)",
                    style: TextStyle(
                      fontSize: 14,
                      color: foto != null
                          ? Colors.black
                          : Colors.grey.shade600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (foto != null)
                  GestureDetector(
                    onTap: onRemove,
                    child: const Icon(Icons.close, size: 18, color: Colors.red),
                  ),
              ],
            ),
          ),
        ),

        // Preview foto
        if (foto != null) ...[
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              foto,
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        ],

        const SizedBox(height: 4),
        Text(
          "* Format: JPG, PNG, GIF (Max 2MB)",
          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
        ),
      ],
    );
  }
}