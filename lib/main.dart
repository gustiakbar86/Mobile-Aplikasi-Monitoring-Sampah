import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app/routes/app_pages.dart';

void main() {
  runApp(const PWasteApp());
}

class PWasteApp extends StatelessWidget {
  const PWasteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'P-Waste Mobile',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      // 2 Baris ini sangat penting agar Controller ikut dimuat!
      initialRoute: AppPages.INITIAL, 
      getPages: AppPages.routes,      
    );
  }
}