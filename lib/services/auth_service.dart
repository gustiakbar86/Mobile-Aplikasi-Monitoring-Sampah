import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {

  // GANTI sesuai IP laptop/komputer kamu
  final String baseUrl = "http://192.168.1.5:8000/api";

  Future<bool> login(String email, String password) async {

    final response = await http.post(
      Uri.parse('$baseUrl/login-user'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "email": email,
        "password": password,
      }),
    );

    print(response.body);

    if (response.statusCode == 200) {

      final data = jsonDecode(response.body);

      SharedPreferences prefs =
          await SharedPreferences.getInstance();

      // simpan token
      await prefs.setString('token', data['token']);

      // simpan data user
      await prefs.setInt('id', data['user']['id']);
      await prefs.setString('name', data['user']['name']);
      await prefs.setString('email', data['user']['email']);

      return true;
    }

    return false;
  }
}