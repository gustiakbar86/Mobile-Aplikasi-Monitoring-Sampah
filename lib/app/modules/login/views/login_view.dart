import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/login_controller.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    // Local controllers to avoid referencing missing members on LoginController
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();

    return Scaffold(
      backgroundColor: Colors.white,
      // SafeArea agar tampilan tidak tertutup poni/kamera HP atas
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 60),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Logo & Judul Aplikasi
              const Icon(Icons.recycling, size: 100, color: Colors.green),
              const SizedBox(height: 20),
              const Text(
                "P-WASTE MOBILE",
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.green),
              ),
              const Text(
                "PT Pelindo Subregional Kalimantan",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 50),

              // Form Input Email (terkoneksi ke local controller)
              TextField(
                controller: emailController, 
                decoration: InputDecoration(
                  labelText: 'Email / Username',
                  prefixIcon: const Icon(Icons.person, color: Colors.green),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 20),
              
              // Form Input Password (menggunakan local controller)
              TextField(
                controller: passwordController, 
                obscureText: true, // Menyembunyikan teks (titik-titik)
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock, color: Colors.green),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 30),

              // Tombol Login Internal
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    // Handle login locally to avoid depending on controller API
                    final String email = emailController.text.trim();
                    final String password = passwordController.text;
                    if (email.isEmpty || password.isEmpty) {
                      Get.snackbar("Error", "Email dan password tidak boleh kosong");
                      return;
                    }
                    // TODO: panggil controller.prosesLogin(email, password) jika tersedia
                    Get.snackbar("Info", "Memproses login untuk $email...");
                  },
                  child: const Text("LOGIN INTERNAL",
                      style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),

              const SizedBox(height: 30),
              const Divider(thickness: 1),
              const SizedBox(height: 20),

              // Tombol khusus Masyarakat/Pengunjung (Tanpa Login)
              const Text("Bukan petugas? Lapor temuan sampah di sini:",
                  style: TextStyle(fontSize: 12)),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.green),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.camera_alt, color: Colors.green),
                  label: const Text("LAPOR SAMPAT (PENGUNJUNG)",
                      style: TextStyle(color: Colors.green)),
                  onPressed: () {
                    // Nanti kita arahkan ke halaman form pengunjung
                    Get.snackbar("Info", "Membuka halaman laporan pengunjung...");
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}