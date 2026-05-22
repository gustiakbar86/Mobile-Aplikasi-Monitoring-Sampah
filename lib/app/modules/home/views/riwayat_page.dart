import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../utils/api_endpoints.dart';

// =========================
// MODEL SAMPAH TERKELOLA
// =========================
class SampahTerkelola {
  final int id;
  final String tanggal;
  final String lokasiAsal;
  final String jenisSampah;
  final double beratKg;
  final String? alasanEdit;
  final String? foto;

  SampahTerkelola({
    required this.id,
    required this.tanggal,
    required this.lokasiAsal,
    required this.jenisSampah,
    required this.beratKg,
    this.alasanEdit,
    this.foto,
  });

  factory SampahTerkelola.fromJson(Map<String, dynamic> json) {
    return SampahTerkelola(
      id:          json['id'],
      tanggal:     json['tgl'] ?? '-',
      lokasiAsal:  json['lokasi_asal']?['nama_lokasi'] ?? '-',
      jenisSampah:
          "${json['jenis']?['kategori_jenis'] ?? '-'} - ${json['jenis']?['nama_jenis'] ?? '-'}",
      beratKg:     double.tryParse(json['jumlah_berat'].toString()) ?? 0,
      alasanEdit:  json['alasan_edit'],
      foto:        json['foto_url'] ?? json['foto_kelola'],
    );
  }
}

// =========================
// MODEL SAMPAH DISERAHKAN
// =========================
class SampahDiserahkan {
  final int id;
  final String tanggal;
  final String lokasiAsal;
  final String jenisSampah;
  final String tujuan;
  final double beratKg;
  final String? alasanEdit;
  final String? foto;

  SampahDiserahkan({
    required this.id,
    required this.tanggal,
    required this.lokasiAsal,
    required this.jenisSampah,
    required this.tujuan,
    required this.beratKg,
    this.alasanEdit,
    this.foto,
  });

  factory SampahDiserahkan.fromJson(Map<String, dynamic> json) {
    return SampahDiserahkan(
      id:          json['id'],
      tanggal:     json['tgl_diserahkan'] ?? '-',
      lokasiAsal:  json['lokasi_asal']?['nama_lokasi'] ?? '-',
      jenisSampah:
          "${json['jenis']?['kategori_jenis'] ?? '-'} - ${json['jenis']?['nama_jenis'] ?? '-'}",
      tujuan:      json['tujuan_sampah']?['nama_tujuan'] ?? '-',
      beratKg:     double.tryParse(json['jumlah_berat'].toString()) ?? 0,
      alasanEdit:  json['alasan_edit'],
      foto:        json['foto_url'],
    );
  }
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

  // ---- Sampah Terkelola ----
  List<SampahTerkelola> listTerkelola       = [];
  List<SampahTerkelola> listTerkelolaFilter = [];
  bool isLoadingTerkelola                   = false;
  String errorTerkelola                     = '';
  final TextEditingController searchTerkelolaC = TextEditingController();
  int pageTerkelola                         = 1;
  int perPageTerkelola                      = 10;

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
    fetchSampahTerkelola();
  }

  @override
  void dispose() {
    _tabController.dispose();
    searchTerkelolaC.dispose();
    searchDiserahkanC.dispose();
    super.dispose();
  }

  // =========================
  // FETCH SAMPAH TERKELOLA
  // =========================
  Future<void> fetchSampahTerkelola() async {
    setState(() {
      isLoadingTerkelola = true;
      errorTerkelola     = '';
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token           = prefs.getString('token');

      final response = await http.get(
        Uri.parse(ApiEndpoints.sampahTerkelola),
        headers: {
          'Content-Type':  'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List list = data['data'];
          setState(() {
            listTerkelola       = list.map((e) => SampahTerkelola.fromJson(e)).toList();
            listTerkelolaFilter = listTerkelola;
          });
        }
      } else if (response.statusCode == 401) {
        _handleUnauthorized();
      } else {
        setState(() => errorTerkelola = 'Gagal memuat data');
      }
    } catch (e) {
      setState(() => errorTerkelola = e.toString());
    } finally {
      setState(() => isLoadingTerkelola = false);
    }
  }

  // =========================
  // FETCH SAMPAH DISERAHKAN
  // =========================
  Future<void> fetchSampahDiserahkan({int page = 1}) async {
    setState(() {
      isLoadingDiserahkan = true;
      errorDiserahkan     = '';
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token           = prefs.getString('token');

      final uri = Uri.parse(ApiEndpoints.sampahDiserahkan)
          .replace(queryParameters: {
        'page':     '$page',
        'per_page': '$perPageDiserahkan',
      });

      final response = await http.get(
        uri,
        headers: {
          'Content-Type':  'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List list = data['data'];
          setState(() {
            listDiserahkan       = list.map((e) => SampahDiserahkan.fromJson(e)).toList();
            listDiserahkanFilter = listDiserahkan;
            totalDiserahkan      = data['total']     ?? 0;
            lastPageDiserahkan   = data['last_page'] ?? 1;
            pageDiserahkan       = data['current_page'] ?? 1;
          });
        }
      } else if (response.statusCode == 401) {
        _handleUnauthorized();
      } else {
        setState(() => errorDiserahkan = 'Gagal memuat data');
      }
    } catch (e) {
      setState(() => errorDiserahkan = e.toString());
    } finally {
      setState(() => isLoadingDiserahkan = false);
    }
  }

  // =========================
  // UNAUTHORIZED
  // =========================
  Future<void> _handleUnauthorized() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Get.offAllNamed('/login');
  }

  // =========================
  // SEARCH TERKELOLA
  // =========================
  void onSearchTerkelola(String query) {
    setState(() {
      pageTerkelola       = 1;
      listTerkelolaFilter = listTerkelola.where((item) {
        return item.lokasiAsal.toLowerCase().contains(query.toLowerCase())  ||
               item.jenisSampah.toLowerCase().contains(query.toLowerCase()) ||
               item.tanggal.contains(query);
      }).toList();
    });
  }

  // =========================
  // SEARCH DISERAHKAN
  // =========================
  void onSearchDiserahkan(String query) {
    setState(() {
      listDiserahkanFilter = listDiserahkan.where((item) {
        return item.lokasiAsal.toLowerCase().contains(query.toLowerCase())  ||
               item.jenisSampah.toLowerCase().contains(query.toLowerCase()) ||
               item.tujuan.toLowerCase().contains(query.toLowerCase())      ||
               item.tanggal.contains(query);
      }).toList();
    });
  }

  // =========================
  // PAGINATION TERKELOLA
  // =========================
  List<SampahTerkelola> get paginatedTerkelola {
    final start = (pageTerkelola - 1) * perPageTerkelola;
    final end   = start + perPageTerkelola;
    return listTerkelolaFilter.sublist(
      start,
      end > listTerkelolaFilter.length ? listTerkelolaFilter.length : end,
    );
  }

  int get totalPagesTerkelola => listTerkelolaFilter.isEmpty
      ? 1
      : (listTerkelolaFilter.length / perPageTerkelola).ceil();

  // =========================
  // PREVIEW FOTO
  // =========================
  void _previewFoto(String urlFoto) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding:    const EdgeInsets.all(16),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: InteractiveViewer(
                child: Image.network(
                  urlFoto,
                  fit:   BoxFit.contain,
                  width: double.infinity,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 300,
                      color:  Colors.black,
                      child:  const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    );
                  },
                  errorBuilder: (_, __, ___) => Container(
                    height: 300,
                    color:  Colors.black,
                    child:  const Center(
                      child: Icon(Icons.broken_image, color: Colors.white, size: 48),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top:   8,
              right: 8,
              child: GestureDetector(
                onTap: () => Get.back(),
                child: Container(
                  padding:    const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
            width: double.infinity,
            color: const Color(0xFF1A3A6B),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: const Text(
              "Riwayat Inputan",
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

          // Konten tab
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTerkelolaTab(),
                _buildDiserahkanTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  // SHARED STYLE
  // =========================
  static const _headerStyle = TextStyle(
    color:      Colors.white,
    fontSize:   11,
    fontWeight: FontWeight.bold,
  );

  // =========================
  // TAB SAMPAH TERKELOLA
  // =========================
  Widget _buildTerkelolaTab() {
    if (isLoadingTerkelola) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorTerkelola.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(errorTerkelola, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: fetchSampahTerkelola,
              child: const Text("Coba Lagi"),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildSearchBar(
          controller: searchTerkelolaC,
          onSearch:   onSearchTerkelola,
          perPage:    perPageTerkelola,
          onPerPageChanged: (val) => setState(() {
            perPageTerkelola = val!;
            pageTerkelola    = 1;
          }),
        ),
        Expanded(
          child: listTerkelolaFilter.isEmpty
              ? const Center(child: Text("Tidak ada data"))
              : SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: 780,
                      child: Column(
                        children: [
                          _buildTerkelolaHeader(),
                          ...paginatedTerkelola.asMap().entries.map((entry) {
                            final index = (pageTerkelola - 1) * perPageTerkelola + entry.key + 1;
                            return _buildTerkelolaRow(index, entry.value);
                          }),
                          const SizedBox(height: 8),
                          _buildPagination(
                            currentPage: pageTerkelola,
                            totalPages:  totalPagesTerkelola,
                            totalData:   listTerkelolaFilter.length,
                            onPrev: pageTerkelola > 1
                                ? () => setState(() => pageTerkelola--)
                                : null,
                            onNext: pageTerkelola < totalPagesTerkelola
                                ? () => setState(() => pageTerkelola++)
                                : null,
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildTerkelolaHeader() {
    return Container(
      color: const Color(0xFF1A3A6B),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: Row(
        children: const [
          SizedBox(width: 30,  child: Text("No",           style: _headerStyle, textAlign: TextAlign.center)),
          SizedBox(width: 50,  child: Text("Foto",         style: _headerStyle, textAlign: TextAlign.center)),
          SizedBox(width: 75,  child: Text("Tanggal",      style: _headerStyle, textAlign: TextAlign.center)),
          SizedBox(width: 110, child: Text("Lokasi Asal",  style: _headerStyle)),
          SizedBox(width: 120, child: Text("Jenis Sampah", style: _headerStyle)),
          SizedBox(width: 60,  child: Text("Berat\n(Kg)",  style: _headerStyle, textAlign: TextAlign.center)),
          SizedBox(width: 110, child: Text("Alasan Edit",  style: _headerStyle)),
          SizedBox(width: 50,  child: Text("Aksi",         style: _headerStyle, textAlign: TextAlign.center)),
        ],
      ),
    );
  }

  Widget _buildTerkelolaRow(int index, SampahTerkelola item) {
    final isEven = index % 2 == 0;
    return Container(
      color: isEven ? Colors.grey.shade100 : Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(width: 30, child: Text("$index", style: const TextStyle(fontSize: 11), textAlign: TextAlign.center)),
          SizedBox(width: 50, child: Center(child: _buildFotoWidget(item.foto))),
          SizedBox(width: 75, child: Text(item.tanggal, style: const TextStyle(fontSize: 11), textAlign: TextAlign.center)),
          SizedBox(width: 110, child: Text(item.lokasiAsal, style: const TextStyle(fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis)),
          SizedBox(width: 120, child: Text(item.jenisSampah, style: const TextStyle(fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis)),
          SizedBox(width: 60, child: Text("${item.beratKg}", style: const TextStyle(fontSize: 11), textAlign: TextAlign.center)),
          SizedBox(width: 110, child: Text(item.alasanEdit ?? "-", style: const TextStyle(fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis)),
          SizedBox(width: 50, child: Center(child: _buildAksiButton(() => _showDetailTerkelola(item)))),
        ],
      ),
    );
  }

  // =========================
  // TAB SAMPAH DISERAHKAN
  // =========================
  Widget _buildDiserahkanTab() {
    if (isLoadingDiserahkan) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorDiserahkan.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(errorDiserahkan, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => fetchSampahDiserahkan(page: pageDiserahkan),
              child: const Text("Coba Lagi"),
            ),
          ],
        ),
      );
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

    return Column(
      children: [
        _buildSearchBar(
          controller: searchDiserahkanC,
          onSearch:   onSearchDiserahkan,
          perPage:    perPageDiserahkan,
          onPerPageChanged: (val) {
            setState(() {
              perPageDiserahkan = val!;
              pageDiserahkan    = 1;
            });
            fetchSampahDiserahkan(page: 1);
          },
        ),
        Expanded(
          child: listDiserahkanFilter.isEmpty
              ? const Center(child: Text("Tidak ada data"))
              : SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: 870,
                      child: Column(
                        children: [
                          _buildDiserahkanHeader(),
                          ...listDiserahkanFilter.asMap().entries.map((entry) {
                            final index = (pageDiserahkan - 1) * perPageDiserahkan + entry.key + 1;
                            return _buildDiserahkanRow(index, entry.value);
                          }),
                          const SizedBox(height: 8),
                          _buildPagination(
                            currentPage: pageDiserahkan,
                            totalPages:  lastPageDiserahkan,
                            totalData:   totalDiserahkan,
                            onPrev: pageDiserahkan > 1
                                ? () => fetchSampahDiserahkan(page: pageDiserahkan - 1)
                                : null,
                            onNext: pageDiserahkan < lastPageDiserahkan
                                ? () => fetchSampahDiserahkan(page: pageDiserahkan + 1)
                                : null,
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildDiserahkanHeader() {
    return Container(
      color: const Color(0xFF1A3A6B),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: Row(
        children: const [
          SizedBox(width: 30,  child: Text("No",           style: _headerStyle, textAlign: TextAlign.center)),
          SizedBox(width: 50,  child: Text("Foto",         style: _headerStyle, textAlign: TextAlign.center)),
          SizedBox(width: 75,  child: Text("Tanggal",      style: _headerStyle, textAlign: TextAlign.center)),
          SizedBox(width: 110, child: Text("Lokasi Asal",  style: _headerStyle)),
          SizedBox(width: 110, child: Text("Jenis Sampah", style: _headerStyle)),
          SizedBox(width: 110, child: Text("Tujuan",       style: _headerStyle)),
          SizedBox(width: 60,  child: Text("Berat\n(Kg)",  style: _headerStyle, textAlign: TextAlign.center)),
          SizedBox(width: 100, child: Text("Alasan Edit",  style: _headerStyle)),
          SizedBox(width: 50,  child: Text("Aksi",         style: _headerStyle, textAlign: TextAlign.center)),
        ],
      ),
    );
  }

  Widget _buildDiserahkanRow(int index, SampahDiserahkan item) {
    final isEven = index % 2 == 0;
    return Container(
      color: isEven ? Colors.grey.shade100 : Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(width: 30,  child: Text("$index", style: const TextStyle(fontSize: 11), textAlign: TextAlign.center)),
          SizedBox(width: 50,  child: Center(child: _buildFotoWidget(item.foto))),
          SizedBox(width: 75,  child: Text(item.tanggal, style: const TextStyle(fontSize: 11), textAlign: TextAlign.center)),
          SizedBox(width: 110, child: Text(item.lokasiAsal, style: const TextStyle(fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis)),
          SizedBox(width: 110, child: Text(item.jenisSampah, style: const TextStyle(fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis)),
          SizedBox(width: 110, child: Text(item.tujuan, style: const TextStyle(fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis)),
          SizedBox(width: 60,  child: Text("${item.beratKg}", style: const TextStyle(fontSize: 11), textAlign: TextAlign.center)),
          SizedBox(width: 100, child: Text(item.alasanEdit ?? "-", style: const TextStyle(fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis)),
          SizedBox(width: 50,  child: Center(child: _buildAksiButton(() => _showDetailDiserahkan(item)))),
        ],
      ),
    );
  }

  // =========================
  // SHARED WIDGETS
  // =========================
  Widget _buildFotoWidget(String? foto) {
    if (foto == null) {
      return const Text("-", style: TextStyle(fontSize: 11), textAlign: TextAlign.center);
    }
    return GestureDetector(
      onTap: () => _previewFoto(foto),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.network(
          foto,
          width:  36,
          height: 36,
          fit:    BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.broken_image, size: 20, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildAksiButton(VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color:        const Color(0xFFFFC107),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.edit, size: 10, color: Colors.white),
            SizedBox(width: 2),
            Text("Edit", style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
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
      child: Row(
        children: [
          const Text("Tampilkan ", style: TextStyle(fontSize: 12)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              border:       Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(4),
            ),
            child: DropdownButton<int>(
              value:     perPage,
              underline: const SizedBox(),
              isDense:   true,
              style:     const TextStyle(fontSize: 12, color: Colors.black),
              items: [10, 25, 50].map((e) {
                return DropdownMenuItem(value: e, child: Text("$e"));
              }).toList(),
              onChanged: onPerPageChanged,
            ),
          ),
          const Text(" entri", style: TextStyle(fontSize: 12)),
          const Spacer(),
          SizedBox(
            width: 140,
            child: TextField(
              controller: controller,
              onChanged:  onSearch,
              style: const TextStyle(fontSize: 12),
              decoration: InputDecoration(
                hintText:  "Cari...",
                hintStyle: const TextStyle(fontSize: 12),
                isDense:   true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                prefixIcon: const Icon(Icons.search, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPagination({
    required int currentPage,
    required int totalPages,
    required int totalData,
    VoidCallback? onPrev,
    VoidCallback? onNext,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Halaman $currentPage dari $totalPages ($totalData data)",
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
          Row(
            children: [
              _pageButton(icon: Icons.chevron_left,  onTap: onPrev),
              const SizedBox(width: 8),
              _pageButton(icon: Icons.chevron_right, onTap: onNext),
            ],
          ),
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
  // DETAIL TERKELOLA
  // =========================
  void _showDetailTerkelola(SampahTerkelola item) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color:        Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize:       MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Detail Sampah Terkelola",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A3A6B)),
              ),
              const Divider(),
              _detailRow("Tanggal",     item.tanggal),
              _detailRow("Lokasi",      item.lokasiAsal),
              _detailRow("Jenis",       item.jenisSampah),
              _detailRow("Berat",       "${item.beratKg} Kg"),
              _detailRow("Alasan Edit", item.alasanEdit ?? '-'),
              if (item.foto != null) ...[
                const SizedBox(height: 8),
                const Text("Foto:", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () { Get.back(); _previewFoto(item.foto!); },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      item.foto!,
                      height: 150, width: double.infinity, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 48),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A3A6B)),
                  child: const Text("Tutup", style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================
  // DETAIL DISERAHKAN
  // =========================
  void _showDetailDiserahkan(SampahDiserahkan item) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color:        Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize:       MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Detail Sampah Diserahkan",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A3A6B)),
              ),
              const Divider(),
              _detailRow("Tanggal",     item.tanggal),
              _detailRow("Lokasi",      item.lokasiAsal),
              _detailRow("Jenis",       item.jenisSampah),
              _detailRow("Tujuan",      item.tujuan),
              _detailRow("Berat",       "${item.beratKg} Kg"),
              _detailRow("Alasan Edit", item.alasanEdit ?? '-'),
              if (item.foto != null) ...[
                const SizedBox(height: 8),
                const Text("Foto:", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () { Get.back(); _previewFoto(item.foto!); },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      item.foto!,
                      height: 150, width: double.infinity, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 48),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A3A6B)),
                  child: const Text("Tutup", style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey)),
          ),
          const Text(": "),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}