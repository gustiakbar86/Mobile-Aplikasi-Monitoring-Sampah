import 'dart:convert';

import 'package:http/http.dart' as http;

class AuthAdminService {

  static Future<http.Response> loginAdmin(
      String email,
      String password,
      ) async {

    return await http.post(

      Uri.parse(
        'http://127.0.0.1:8000/api/login-admin',
      ),

      headers: {
        'Content-Type': 'application/json',
      },

      body: jsonEncode({

        "email_admin": email,
        "password_admin": password,

      }),
    );
  }
}