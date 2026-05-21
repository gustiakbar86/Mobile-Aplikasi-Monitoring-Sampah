import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {

  String nama = "Petugas"; // ← default sebelum data dimuat

  @override
  void initState() {
    super.initState();
    loadNama(); // ✅ ambil nama saat halaman dibuka
  }

  // =========================
  // AMBIL NAMA DARI SESSION
  // =========================
  Future<void> loadNama() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      nama = prefs.getString('name') ?? "Petugas"; // ✅ ambil key 'name'
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
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // =========================
            // HEADER + TOMBOL LOGOUT
            // =========================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [

                const Text(
                  "Dashboard",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                IconButton(
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
                    color: Colors.red,
                  ),
                  tooltip: "Logout",
                ),
              ],
            ),

            const SizedBox(height: 8),

            // ✅ Nama dinamis dari session
            Text("Selamat datang, $nama"),

            const SizedBox(height: 20),

            Row(
              children: [

                Expanded(
                  child: DropdownButtonFormField(
                    items: const [
                      DropdownMenuItem(
                        value: "semua",
                        child: Text("Semua Sampah"),
                      ),
                    ],
                    onChanged: (value) {},
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: DropdownButtonFormField(
                    items: const [
                      DropdownMenuItem(
                        value: "minggu",
                        child: Text("Minggu Ini"),
                      ),
                    ],
                    onChanged: (value) {},
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
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