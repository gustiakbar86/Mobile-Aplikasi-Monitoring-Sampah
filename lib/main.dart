import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/routes/app_pages.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // ✅ wajib karena pakai async

  // Cek token session
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('token');

  runApp(PWasteApp(initialRoute: token != null ? '/home' : '/login'));
}

// ❌ class MyApp dihapus karena tidak dipakai

class PWasteApp extends StatelessWidget {
  final String initialRoute; // ✅ terima initialRoute dari main

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
      initialRoute: initialRoute, // ✅ dinamis berdasarkan session
      getPages: AppPages.routes,
    );
  }
}