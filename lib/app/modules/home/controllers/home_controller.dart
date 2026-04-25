import 'package:flutter/material.dart';
import 'package:get/get.dart';

// 3 BARIS INI YANG SEBELUMNYA KELUPAAN (WAJIB DITAMBAHKAN)
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class HomeController extends GetxController {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // URL API Laravel Anda di hosting
  final String apiUrl = "https://p-waste.org/api/login"; 

  // Fungsi Login Asli
  Future<void> loginInternal() async {
    String email = emailController.text;
    String password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      Get.snackbar("Gagal", "Email dan Password tidak boleh kosong!", 
          backgroundColor: Colors.redAccent, colorText: Colors.white);
      return;
    }

    try {
      // 1. Menembak API
      var response = await http.post(
        Uri.parse(apiUrl),
        body: {
          'email': email,
          'password': password,
        },
      );

      // 2. Mengecek Jawaban dari Server
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        
        String token = data['token'];
        String role = data['role']; 

        // 3. Simpan Token ke Penyimpanan Lokal HP
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        await prefs.setString('role', role);

        Get.snackbar("Berhasil", "Login Sukses!", 
            backgroundColor: Colors.green, colorText: Colors.white);

        // 4. Arahkan ke Dashboard sesuai Role
        if (role == 'admin') {
          // Get.offAllNamed('/admin-dashboard'); 
        } else if (role == 'petugas') {
          // Get.offAllNamed('/petugas-dashboard');
        }

      } else {
        Get.snackbar("Gagal", "Email atau Password salah!", 
            backgroundColor: Colors.redAccent, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar("Error", "Tidak dapat terhubung ke server.", 
          backgroundColor: Colors.redAccent, colorText: Colors.white);
    }
  }

  void goToPengunjung() {
    // Get.toNamed('/pengunjung');
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}