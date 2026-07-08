import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/routes/app_pages.dart';
import 'app/services/delegasi_notif_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await DelegasiNotifService.instance.init();

  // Inisialisasi format tanggal lokal Indonesia (dipakai dashboard admin)
  await initializeDateFormatting('id', null);

  // Cek session
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('token');
  String? role = prefs.getString('login_as');

  // Tentukan halaman awal:
  // - Belum ada token -> landing (pintu masuk: login / laporan pengunjung)
  // - Sudah ada token  -> langsung ke home/admin sesuai role
  String initial = '/landing';
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
