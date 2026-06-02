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

  // =========================
  // DATA DROPDOWN (hardcode)
  // =========================
  final List<Map<String, dynamic>> listLokasi = [
    {"id": 1, "nama": "Area Kantor"},
    {"id": 2, "nama": "Area Tempat Parkir/Taman/Jalan"},
    {"id": 3, "nama": "Area Ruang Tunggu"},
    {"id": 4, "nama": "Area Tempat Makan"},
    {"id": 5, "nama": "Sampah Kapal"},
    {"id": 6, "nama": "Area Lain"},
  ];

  final List<Map<String, dynamic>> listKategori = [
    {"id": "Organik",    "nama": "Organik"},
    {"id": "Anorganik",  "nama": "Anorganik"},
    {"id": "Residu",     "nama": "Residu"},
  ];

  final Map<String, List<Map<String, dynamic>>> listJenisByKategori = {
    "Organik":   [
      {"id": 1, "nama": "Sisa Makanan"},
      {"id": 2, "nama": "Daun/Ranting"},
    ],
    "Anorganik": [
      {"id": 3, "nama": "Plastik"},
      {"id": 4, "nama": "Kertas"},
      {"id": 5, "nama": "Logam"},
      {"id": 6, "nama": "Kayu"},
    ],
    "Residu":    [
      {"id": 7, "nama": "Residu"},
    ],
  };

  final List<Map<String, dynamic>> listTujuan = [
    {"id": 3, "nama": "TPA Banjar Bakula"},
    {"id": 4, "nama": "Tempat Pembuangan Akhir"},
  ];

  // =========================
  // STATE FORM TERKELOLA
  // =========================
  final TextEditingController beratTerkelolaC  = TextEditingController();
  final TextEditingController alasanTerkelolaC = TextEditingController();
  DateTime tglTerkelola                        = DateTime.now();
  int? selectedLokasiTerkelola;
  String? selectedKategoriTerkelola;
  int? selectedJenisTerkelola;
  File? fotoTerkelola;
  bool isLoadingTerkelola                      = false;

  // =========================
  // STATE FORM DISERAHKAN
  // =========================
  final TextEditingController beratDiserahkanC  = TextEditingController();
  final TextEditingController alasanDiserahkanC = TextEditingController();
  DateTime tglDiserahkan                        = DateTime.now();
  int? selectedLokasiDiserahkan;
  String? selectedKategoriDiserahkan;
  int? selectedJenisDiserahkan;
  int? selectedTujuan;
  File? fotoDiserahkan;
  bool isLoadingDiserahkan                      = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    beratTerkelolaC.dispose();
    alasanTerkelolaC.dispose();
    beratDiserahkanC.dispose();
    alasanDiserahkanC.dispose();
    super.dispose();
  }

  // =========================
  // PILIH TANGGAL
  // =========================
  Future<void> pickDate({required bool isTerkelola}) async {
    final picked = await showDatePicker(
      context:     context,
      initialDate: isTerkelola ? tglTerkelola : tglDiserahkan,
      firstDate:   DateTime(2020),
      lastDate:    DateTime(2030),
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
      source:    ImageSource.gallery,
      imageQuality: 70,
      maxWidth:  1024,
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
        selectedJenisTerkelola  == null ||
        beratTerkelolaC.text.trim().isEmpty) {
      Get.snackbar("Peringatan", "Lengkapi semua field yang wajib diisi",
          backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }

    setState(() => isLoadingTerkelola = true);

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token           = prefs.getString('token');
      String? idUser          = prefs.getString('id_user') ?? '1';

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
      request.fields['alasan_edit']  = alasanTerkelolaC.text.trim();

      if (fotoTerkelola != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'foto_kelola',
          fotoTerkelola!.path,
        ));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data     = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        Get.snackbar(
          "Berhasil",
          "Data sampah terkelola berhasil disimpan",
          backgroundColor: Colors.green,
          colorText:        Colors.white,
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
        selectedJenisDiserahkan  == null ||
        selectedTujuan           == null ||
        beratDiserahkanC.text.trim().isEmpty) {
      Get.snackbar("Peringatan", "Lengkapi semua field yang wajib diisi",
          backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }

    setState(() => isLoadingDiserahkan = true);

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token           = prefs.getString('token');
      String? idUser          = prefs.getString('id_user') ?? '1';

      final request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiEndpoints.sampahDiserahkan),
      );

      request.headers['Authorization'] = 'Bearer $token';

      request.fields['_method']         = 'POST';
      request.fields['id_user']         = idUser;
      request.fields['id_lokasi']       = '$selectedLokasiDiserahkan';
      request.fields['id_jenis']        = '$selectedJenisDiserahkan';
      request.fields['id_tujuan']       = '$selectedTujuan';
      request.fields['jumlah_berat']    = beratDiserahkanC.text.trim();
      request.fields['tgl_diserahkan']  =
          DateFormat('yyyy-MM-dd').format(tglDiserahkan);
      request.fields['alasan_edit']     = alasanDiserahkanC.text.trim();

      if (fotoDiserahkan != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'foto_diserahkan',
          fotoDiserahkan!.path,
        ));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data     = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        Get.snackbar(
          "Berhasil",
          "Data sampah diserahkan berhasil disimpan",
          backgroundColor: Colors.green,
          colorText:        Colors.white,
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
      alasanTerkelolaC.clear();
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
      alasanDiserahkanC.clear();
    });
  }

  // =========================
  // BUILD
  // =========================
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [

          // Header biru
          Container(
            width:   double.infinity,
            color:   const Color(0xFF1A3A6B),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: const Text(
              "Input Data Sampah",
              style: TextStyle(
                color:      Colors.white,
                fontSize:   16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Tab bar
          Container(
            color: Colors.white,
            child: TabBar(
              controller:           _tabController,
              labelColor:           const Color(0xFF1A3A6B),
              unselectedLabelColor: Colors.grey,
              indicatorColor:       const Color(0xFF1A3A6B),
              labelStyle: const TextStyle(
                fontSize:   12,
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
      ),
    );
  }

  // =========================
  // FORM TERKELOLA
  // =========================
  Widget _buildFormTerkelola() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          const SizedBox(height: 8),

          // Tanggal
          _buildLabel("Tanggal", required: true),
          _buildDateField(
            date:       tglTerkelola,
            onTap:      () => pickDate(isTerkelola: true),
          ),

          const SizedBox(height: 16),

          // Sumber Sampah
          _buildLabel("Lokasi Asal", required: true),
          _buildDropdown<int>(
            hint:     "-- Pilih Lokasi --",
            value:    selectedLokasiTerkelola,
            items:    listLokasi.map((e) {
              return DropdownMenuItem<int>(
                value: e['id'],
                child: Text(e['nama'], style: const TextStyle(fontSize: 14)),
              );
            }).toList(),
            onChanged: (val) => setState(() => selectedLokasiTerkelola = val),
          ),

          const SizedBox(height: 16),

          // Kategori Jenis
          _buildLabel("Kategori Jenis", required: true),
          _buildDropdown<String>(
            hint:  "-- Pilih Kategori --",
            value: selectedKategoriTerkelola,
            items: listKategori.map((e) {
              return DropdownMenuItem<String>(
                value: e['id'],
                child: Text(e['nama'], style: const TextStyle(fontSize: 14)),
              );
            }).toList(),
            onChanged: (val) => setState(() {
              selectedKategoriTerkelola = val;
              selectedJenisTerkelola   = null;
            }),
          ),

          const SizedBox(height: 16),

          // Jenis Sampah
          _buildLabel("Jenis Sampah", required: true),
          _buildDropdown<int>(
            hint:     "-- Pilih Jenis --",
            value:    selectedJenisTerkelola,
            enabled:  selectedKategoriTerkelola != null,
            items:    selectedKategoriTerkelola == null
                ? []
                : (listJenisByKategori[selectedKategoriTerkelola] ?? [])
                    .map((e) => DropdownMenuItem<int>(
                          value: e['id'],
                          child: Text(e['nama'],
                              style: const TextStyle(fontSize: 14)),
                        ))
                    .toList(),
            onChanged: (val) => setState(() => selectedJenisTerkelola = val),
          ),

          const SizedBox(height: 16),

          // Berat
          _buildLabel("Berat (Kg)", required: true),
          _buildTextField(
            controller:  beratTerkelolaC,
            hint:        "0.00",
            keyboardType: TextInputType.numberWithOptions(decimal: true),
          ),

          const SizedBox(height: 16),

          // Foto
          _buildLabel("Foto"),
          _buildFotoField(
            foto:   fotoTerkelola,
            onTap:  () => pickFoto(isTerkelola: true),
            onRemove: () => setState(() => fotoTerkelola = null),
          ),

          const SizedBox(height: 16),

          // Alasan Edit
          _buildLabel("Keterangan"),
          _buildTextField(
            controller: alasanTerkelolaC,
            hint:       "Opsional",
            maxLines:   3,
          ),

          const SizedBox(height: 24),

          // Tombol Simpan
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: isLoadingTerkelola ? null : submitTerkelola,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A3A6B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: isLoadingTerkelola
                  ? const SizedBox(
                      width:  18,
                      height: 18,
                      child:  CircularProgressIndicator(
                        color:       Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.save, color: Colors.white),
              label: Text(
                isLoadingTerkelola ? "Menyimpan..." : "Simpan",
                style: const TextStyle(
                  color:      Colors.white,
                  fontSize:   15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          const SizedBox(height: 8),

          // Tanggal
          _buildLabel("Tanggal", required: true),
          _buildDateField(
            date:  tglDiserahkan,
            onTap: () => pickDate(isTerkelola: false),
          ),

          const SizedBox(height: 16),

          // Sumber Sampah
          _buildLabel("Lokasi Asal", required: true),
          _buildDropdown<int>(
            hint:  "-- Pilih Lokasi --",
            value: selectedLokasiDiserahkan,
            items: listLokasi.map((e) {
              return DropdownMenuItem<int>(
                value: e['id'],
                child: Text(e['nama'], style: const TextStyle(fontSize: 14)),
              );
            }).toList(),
            onChanged: (val) =>
                setState(() => selectedLokasiDiserahkan = val),
          ),

          const SizedBox(height: 16),

          // Kategori Jenis
          _buildLabel("Kategori Jenis", required: true),
          _buildDropdown<String>(
            hint:  "-- Pilih Kategori --",
            value: selectedKategoriDiserahkan,
            items: listKategori.map((e) {
              return DropdownMenuItem<String>(
                value: e['id'],
                child: Text(e['nama'], style: const TextStyle(fontSize: 14)),
              );
            }).toList(),
            onChanged: (val) => setState(() {
              selectedKategoriDiserahkan = val;
              selectedJenisDiserahkan   = null;
            }),
          ),

          const SizedBox(height: 16),

          // Jenis Sampah
          _buildLabel("Jenis Sampah", required: true),
          _buildDropdown<int>(
            hint:    "-- Pilih Jenis --",
            value:   selectedJenisDiserahkan,
            enabled: selectedKategoriDiserahkan != null,
            items:   selectedKategoriDiserahkan == null
                ? []
                : (listJenisByKategori[selectedKategoriDiserahkan] ?? [])
                    .map((e) => DropdownMenuItem<int>(
                          value: e['id'],
                          child: Text(e['nama'],
                              style: const TextStyle(fontSize: 14)),
                        ))
                    .toList(),
            onChanged: (val) =>
                setState(() => selectedJenisDiserahkan = val),
          ),

          const SizedBox(height: 16),

          // Tujuan Diserahkan
          _buildLabel("Tujuan Diserahkan", required: true),
          _buildDropdown<int>(
            hint:  "-- Pilih Tujuan --",
            value: selectedTujuan,
            items: listTujuan.map((e) {
              return DropdownMenuItem<int>(
                value: e['id'],
                child: Text(e['nama'], style: const TextStyle(fontSize: 14)),
              );
            }).toList(),
            onChanged: (val) => setState(() => selectedTujuan = val),
          ),

          const SizedBox(height: 16),

          // Berat
          _buildLabel("Berat (Kg)", required: true),
          _buildTextField(
            controller:   beratDiserahkanC,
            hint:         "0.00",
            keyboardType: TextInputType.numberWithOptions(decimal: true),
          ),

          const SizedBox(height: 16),

          // Foto
          _buildLabel("Foto"),
          _buildFotoField(
            foto:     fotoDiserahkan,
            onTap:    () => pickFoto(isTerkelola: false),
            onRemove: () => setState(() => fotoDiserahkan = null),
          ),

          const SizedBox(height: 16),

          // Alasan Edit
          _buildLabel("Keterangan"),
          _buildTextField(
            controller: alasanDiserahkanC,
            hint:       "Opsional",
            maxLines:   3,
          ),

          const SizedBox(height: 24),

          // Tombol Simpan
          SizedBox(
            width:  double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: isLoadingDiserahkan ? null : submitDiserahkan,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A3A6B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: isLoadingDiserahkan
                  ? const SizedBox(
                      width:  18,
                      height: 18,
                      child:  CircularProgressIndicator(
                        color:       Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.save, color: Colors.white),
              label: Text(
                isLoadingDiserahkan ? "Menyimpan..." : "Simpan",
                style: const TextStyle(
                  color:      Colors.white,
                  fontSize:   15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // =========================
  // SHARED WIDGETS
  // =========================
  Widget _buildLabel(String text, {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(
            text,
            style: const TextStyle(
              fontSize:   14,
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
        width:   double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          border:       Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(8),
          color:        Colors.white,
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
      width:   double.infinity,
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
          value:    value,
          hint:     Text(hint, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
          isExpanded: true,
          items:    items,
          onChanged: enabled ? onChanged : null,
          style:    const TextStyle(fontSize: 14, color: Colors.black),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines               = 1,
  }) {
    return TextField(
      controller:  controller,
      keyboardType: keyboardType,
      maxLines:    maxLines,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText:        hint,
        hintStyle:       TextStyle(color: Colors.grey.shade500),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical:   12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:   BorderSide(color: Colors.grey.shade400),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:   BorderSide(color: Colors.grey.shade400),
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
            width:   double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              border:       Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(8),
              color:        Colors.white,
            ),
            child: Row(
              children: [
                const Icon(Icons.attach_file,
                    size: 18, color: Color(0xFF1A3A6B)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    foto != null
                        ? foto.path.split('/').last
                        : "Choose file",
                    style: TextStyle(
                      fontSize: 14,
                      color:    foto != null
                          ? Colors.black
                          : Colors.grey.shade600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (foto != null)
                  GestureDetector(
                    onTap: onRemove,
                    child: const Icon(Icons.close,
                        size: 18, color: Colors.red),
                  ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 4),

        // Preview foto
        if (foto != null) ...[
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              foto,
              height:  150,
              width:   double.infinity,
              fit:     BoxFit.cover,
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