import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/routes/app_pages.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Cek session
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('token');
  String? role = prefs.getString('login_as');

  // Tentukan halaman awal berdasarkan token + role
  String initial = '/login';
  if (token != null) {
    initial = (role == 'petugas') ? '/home' : '/admin';
  }

  runApp(PWasteApp(initialRoute: initial));
}

class PWasteApp extends StatelessWidget {
  final String initialRoute;

  const PWasteApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'P-Waste Mobile',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      initialRoute: initialRoute,
      getPages: AppPages.routes,
    );
  }
}