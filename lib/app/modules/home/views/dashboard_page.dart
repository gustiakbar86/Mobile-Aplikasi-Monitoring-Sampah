import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {

  String nama = "Petugas";

  @override
  void initState() {
    super.initState();
    loadNama();
  }

  // =========================
  // AMBIL NAMA DARI SESSION
  // =========================
  Future<void> loadNama() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      nama = prefs.getString('name') ?? "Petugas";
    });
  }

  // =========================
  // FUNGSI LOGOUT
  // =========================
  Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    Get.snackbar("Berhasil", "Anda telah logout");
    Get.offAllNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // =========================
          // HEADER BIRU
          // =========================
          Container(
            width: double.infinity,
            color: const Color(0xFF1A3A6B),
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [

                // Logo + Judul
                Row(
                  children: [
                    // ✅ SESUDAH — pakai logo pwaste.png
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Image.asset(
                        'assets/images/pwaste.png',
                        height: 38,
                        width: 38,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Dashboard Petugas",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "Aplikasi Pengelolaan Sampah",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Nama + Logout
                Row(
                  children: [
                    const SizedBox(width: 10),
                    // Tombol Logout
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
                      icon: const Icon(
                        Icons.logout,
                        size: 14,
                        color: Colors.white,
                      ),
                      label: const Text(
                        "Logout",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white54),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // =========================
          // KONTEN SCROLLABLE
          // =========================
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // =========================
                  // BANNER SELAMAT DATANG
                  // =========================
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A3A6B),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "Selamat Datang, $nama",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // =========================
                  // FILTER DROPDOWN
                  // =========================
                  Row(
                    children: [

                      Expanded(
                        child: DropdownButtonFormField(
                          items: const [
                            DropdownMenuItem(
                              value: "semua",
                              child: Text(
                                "Semua Sampah",
                                style: TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                          onChanged: (value) {},
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: DropdownButtonFormField(
                          items: const [
                            DropdownMenuItem(
                              value: "minggu",
                              child: Text(
                                "Minggu Ini",
                                style: TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                          onChanged: (value) {},
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  buildCard("Distribusi Jenis Sampah"),

                  const SizedBox(height: 16),

                  buildCard("Distribusi Berat Sampah"),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildCard(String title) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: double.infinity,
        height: 250,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A3A6B),
              ),
            ),

            const Expanded(
              child: Center(
                child: Text("Grafik"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}