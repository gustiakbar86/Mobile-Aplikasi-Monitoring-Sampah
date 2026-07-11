import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../app/utils/api_endpoints.dart';
import '../../../services/delegasi_notif_service.dart';

class LoginController extends GetxController {

  final TextEditingController emailC = TextEditingController();
  final TextEditingController passwordC = TextEditingController();

  RxBool isLoading = false.obs;

  Future<void> login() async {
    try {
      isLoading.value = true;

      final userResponse = await http.post(
        Uri.parse(ApiEndpoints.loginUser),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "email": emailC.text.trim(),
          "password": passwordC.text,
        }),
      );

      final userData = jsonDecode(userResponse.body);
      print(userData);

      if (userResponse.statusCode == 200 && userData['success'] == true) {

        final String role = (userData['data']['role'] ?? '').toString();

        // Simpan session
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', userData['data']['access_token']);
        await prefs.setString('login_as', role);
        await prefs.setString('name', userData['data']['user']['name']);
        await prefs.setString('id_user', userData['data']['user']['id'].toString());
        await prefs.reload();

        Get.snackbar("Berhasil", "Login Berhasil");

        // Arahkan sesuai role
        if (role == 'petugas') {
           await DelegasiNotifService.instance.start();  // Mulai notif
          Get.offAllNamed('/home');
        } else if (role == 'admin') {
          Get.offAllNamed('/admin');
        } else {
          // tolak role lain
          await prefs.clear();
          Get.snackbar(
            "Akses Ditolak",
            "Saat ini hanya petugas dan admin yang dapat masuk.",
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
        return;
      }

      Get.snackbar("Error", "Email atau Password salah");

    } catch (e) {
      print(e);
      Get.snackbar("Error", e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    DelegasiNotifService.instance.stop(); // Penghentian Notif
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Get.snackbar("Berhasil", "Anda telah logout");
    Get.offAllNamed('/landing');
  }

  @override
  void onClose() {
    emailC.dispose();
    passwordC.dispose();
    super.onClose();
  }
}