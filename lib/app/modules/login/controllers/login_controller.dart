import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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
      // COBA LOGIN ADMIN
      // =========================
      final adminResponse = await http.post(

        Uri.parse(
          'http://127.0.0.1:8000/api/login-admin',
        ),

        headers: {
          'Content-Type': 'application/json',
        },

        body: jsonEncode({

          "email_admin": emailC.text,
          "password_admin": passwordC.text,

        }),
      );

      final adminData =
          jsonDecode(adminResponse.body);

      print(adminData);

      // =========================
      // JIKA ADMIN BERHASIL
      // =========================
      if (adminResponse.statusCode == 200 &&
          adminData['status'] == true) {

        SharedPreferences prefs =
            await SharedPreferences.getInstance();

        await prefs.setString(
            'token',
            adminData['token']);

        await prefs.setString(
            'login_as',
            'admin');

        await prefs.setString(
            'nama_admin',
            adminData['admin']['nama_admin']);

        Get.snackbar(
          "Berhasil",
          "Login Admin Berhasil",
        );

        return;
      }

      // =========================
      // COBA LOGIN USER
      // =========================
      final userResponse = await http.post(

        Uri.parse(
          'http://127.0.0.1:8000/api/login-user',
        ),

        headers: {
          'Content-Type': 'application/json',
        },

        body: jsonEncode({

          "email": emailC.text,
          "password": passwordC.text,

        }),
      );

      final userData =
          jsonDecode(userResponse.body);

      print(userData);

      // =========================
      // JIKA USER BERHASIL
      // =========================
      if (userResponse.statusCode == 200 &&
          userData['status'] == true) {

        SharedPreferences prefs =
            await SharedPreferences.getInstance();

        await prefs.setString(
            'token',
            userData['token']);

        await prefs.setString(
            'login_as',
            'user');

        await prefs.setString(
            'name',
            userData['user']['name']);

        Get.snackbar(
          "Berhasil",
          "Login User Berhasil",
        );

        // PINDAH KE HOME
        Get.offAllNamed('/home');


        return;
      }

      // =========================
      // GAGAL SEMUA
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