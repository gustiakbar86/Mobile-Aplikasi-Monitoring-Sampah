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

  var isLoading = false.obs;

  Future<void> login() async {

    try {

      isLoading.value = true;

      final response = await http.post(
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

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 &&
          data['status'] == true) {

        SharedPreferences prefs =
            await SharedPreferences.getInstance();

        // simpan token
        await prefs.setString(
            'token',
            data['token']);

        // simpan user
        await prefs.setString(
            'name',
            data['user']['name']);

        await prefs.setString(
            'email',
            data['user']['email']);

        Get.snackbar(
          "Berhasil",
          data['message'],
        );

        print(data);

        // pindah halaman
        // Get.offAllNamed(Routes.HOME);

      } else {

        Get.snackbar(
          "Error",
          data['message'] ??
              "Login gagal",
        );
      }

    } catch (e) {

      Get.snackbar(
        "Error",
        e.toString(),
      );

    } finally {

      isLoading.value = false;
    }
  }
}