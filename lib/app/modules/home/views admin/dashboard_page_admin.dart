import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardPageAdmin extends StatefulWidget {
  const DashboardPageAdmin({super.key});

  @override
  State<DashboardPageAdmin> createState() => _DashboardPageAdminState();
}

class _DashboardPageAdminState extends State<DashboardPageAdmin> {
  String nama = "Admin";
  String role = "admin";

  @override
  void initState() {
    super.initState();
    loadProfil();
  }

  Future<void> loadProfil() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      nama = prefs.getString('name') ?? "Admin";
      role = prefs.getString('login_as') ?? "admin";
    });
  }

  Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Get.snackbar("Berhasil", "Anda telah logout");
    Get.offAllNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              color: const Color(0xFF1A3A6B),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Dashboard Admin",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "Aplikasi Pengelolaan Sampah",
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
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
                    icon: const Icon(Icons.logout, size: 14, color: Colors.white),
                    label: const Text(
                      "Logout",
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white54),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                  ),
                ],
              ),
            ),

            // Konten placeholder
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 12),
                    Text(
                      "Selamat datang, $nama",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Login sebagai: $role",
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        "Admin",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}