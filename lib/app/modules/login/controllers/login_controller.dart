import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../app/utils/api_endpoints.dart';

class LoginController extends GetxController {

  TextEditingController emailC =
      TextEditingController();

  TextEditingController passwordC =
      TextEditingController();

  RxBool isLoading = false.obs;

  Future<void> login() async {

    try {

      isLoading.value = true;

      // =========================
      // COBA LOGIN USER
      // =========================
      final userResponse = await http.post(

        Uri.parse(ApiEndpoints.loginUser), // ✅ pakai endpoint hosting

        headers: {
          'Content-Type': 'application/json',
        },

        body: jsonEncode({
          "email": emailC.text,
          "password": passwordC.text,
        }),
      );

      final userData = jsonDecode(userResponse.body);

      print(userData);

     // =========================
     // JIKA USER BERHASIL
     // =========================
        if (userResponse.statusCode == 200 &&
            userData['success'] == true) { // ✅ ganti 'status' → 'success'

          SharedPreferences prefs =
          await SharedPreferences.getInstance();

          await prefs.setString('token', userData['data']['access_token']); // ✅ ganti
          await prefs.setString('login_as', userData['data']['role']);       // ✅ ambil role
          await prefs.setString('name', userData['data']['user']['name']);   // ✅ ganti

          Get.snackbar("Berhasil", "Login Berhasil");
          Get.offAllNamed('/home');
          return;
        }

      // =========================
      // LOGOUT
      // =========================
          Future<void> logout() async {
            SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.clear(); // hapus semua data session

            Get.snackbar("Berhasil", "Anda telah logout");

            // Kembali ke halaman login
            Get.offAllNamed('/login');
          }

      // =========================
      // GAGAL
      // =========================
      Get.snackbar(
        "Error",
        "Email atau Password salah",
      );

    } catch (e) {

      print(e);

      Get.snackbar(
        "Error",
        e.toString(),
      );

    } finally {

      isLoading.value = false;
    }
  }
}