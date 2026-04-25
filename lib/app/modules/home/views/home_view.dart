import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 60),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Logo & Judul
              const Icon(Icons.recycling, size: 100, color: Colors.green),
              const SizedBox(height: 20),
              const Text(
                "P-WASTE MOBILE",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.green),
              ),
              const Text(
                "PT Pelindo Subregional Kalimantan",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 50),

              // Form Login (Untuk Petugas & Admin)
              TextField(
                controller: controller.emailController, // Nyambung ke Controller
                decoration: InputDecoration(
                  labelText: 'Email / Username',
                  prefixIcon: const Icon(Icons.person, color: Colors.green),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller.passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock, color: Colors.green),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    controller.loginInternal(); // Panggil fungsi di Controller
                  },
                  child: const Text("LOGIN INTERNAL", style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
              
              const SizedBox(height: 30),
              const Divider(thickness: 1),
              const SizedBox(height: 20),

              // Tombol Lapor Pengunjung (Revisi Pak Arifin)
              const Text("Bukan petugas? Lapor temuan sampah di sini:", style: TextStyle(fontSize: 12)),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.green),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.camera_alt, color: Colors.green),
                  label: const Text("LAPOR SAMPAH (PENGUNJUNG)", style: TextStyle(color: Colors.green)),
                  onPressed: () {
                    controller.goToPengunjung(); // Panggil fungsi di Controller
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