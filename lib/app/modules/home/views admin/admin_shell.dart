import 'package:flutter/material.dart';

import 'dashboard_page_admin.dart';
import 'kelola_petugas_page.dart';
import 'data_sampah_page.dart';
import 'kelola_master_page.dart';
import 'laporan_page.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  static const Color brand = Color(0xFF1A3A6B);
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const DashboardPageAdmin(),
      const KelolaPetugasPage(),
      const DataSampahPage(),
      const KelolaMasterPage(),
      const LaporanPage(),
    ];

    return Scaffold(
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        onTap: (i) => setState(() => index = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: brand,
        unselectedItemColor: Colors.grey,
        selectedFontSize: 10,
        unselectedFontSize: 10,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard), label: "Dashboard"),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: "Petugas"),
          BottomNavigationBarItem(
              icon: Icon(Icons.list_alt), label: "Data Sampah"),
          BottomNavigationBarItem(icon: Icon(Icons.storage), label: "Master"),
          BottomNavigationBarItem(icon: Icon(Icons.folder), label: "Laporan"),
        ],
      ),
    );
  }
}