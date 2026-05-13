import 'package:flutter/material.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Text(
              "Dashboard",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              "Selamat datang, Petugas",
            ),

            const SizedBox(height: 20),

            Row(
              children: [

                Expanded(
                  child: DropdownButtonFormField(
                    items: const [
                      DropdownMenuItem(
                        value: "semua",
                        child: Text("Semua Sampah"),
                      ),
                    ],
                    onChanged: (value) {},
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: DropdownButtonFormField(
                    items: const [
                      DropdownMenuItem(
                        value: "minggu",
                        child: Text("Minggu Ini"),
                      ),
                    ],
                    onChanged: (value) {},
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            buildCard("Distribusi Jenis Sampah"),

            const SizedBox(height: 16),

            buildCard("Distribusi Berat Sampah"),
          ],
        ),
      ),
    );
  }

  Widget buildCard(String title) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),

      child: Container(
        width: double.infinity,
        height: 250,
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            const Expanded(
              child: Center(
                child: Text("Grafik"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}