import 'package:flutter/material.dart';

import 'dashboard_page_admin.dart';
import 'kelola_petugas_page.dart';
import 'data_sampah_page.dart';
import 'kelola_master_page.dart';

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
      const _ComingSoon(title: "Laporan", icon: Icons.folder),
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

class _ComingSoon extends StatelessWidget {
  final String title;
  final IconData icon;
  const _ComingSoon({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A3A6B),
        foregroundColor: Colors.white,
        title: Text(title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(title,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text("Halaman ini masih dalam pengembangan",
                style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}