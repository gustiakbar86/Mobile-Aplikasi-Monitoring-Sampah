import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../webview/controllers/webview_controller.dart' show WebviewArgs;

class LandingView extends StatelessWidget {
  const LandingView({super.key});

  // ==== Palet biru muda ====
  static const Color _biru = Color(0xFF039BE5); // tombol utama (light blue 600)
  static const Color _biruMuda = Color(0xFF29B6F6); // aksen ikon (light blue 400)
  static const Color _biruSoft = Color(0xFFE1F5FE); // latar chip ikon (light blue 50)

  // Sesuaikan dengan URL web pengunjung kamu.
  static const String _laporanPengunjungUrl =
      'https://gusti-edo.org/pengunjung-web-p-waste/';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // ==== Dua logo sejajar: pwaste (kiri) & pelindo (kanan) ====
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Image.asset(
                      'assets/images/pwaste.png',
                      height: 120,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.recycling,
                        size: 90,
                        color: _biruMuda,
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Image.asset(
                      'assets/images/pelindo.png',
                      height: 120,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.business,
                        size: 90,
                        color: _biru,
                      ),
                    ),
                  ),
                ],
              ),

              const Spacer(flex: 2),

              // ==== Dua kartu: kiri Login, kanan Laporan Pengunjung ====
              // IntrinsicHeight + stretch: kedua kartu mengikuti tinggi
              // kartu tertinggi (kanan yang labelnya 2 baris).
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _menuCard(
                        icon: Icons.login_rounded,
                        label: 'Login',
                        onTap: () => Get.toNamed('/login'),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _menuCard(
                        icon: Icons.location_on_outlined,
                        label: 'Laporan Pengunjung',
                        onTap: () => Get.toNamed(
                          '/webview',
                          arguments: WebviewArgs(
                            url: _laporanPengunjungUrl,
                            title: 'Laporan Pengunjung',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ==== Tombol pill penuh: About Us ====
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Get.toNamed(
                      '/webview',
                      arguments: WebviewArgs(
                        url:
                            'https://gusti-edo.org/pengunjung-web-p-waste/tentang',
                        title: 'About Us',
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _biru,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'About Us',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  /// Kartu menu putih bergaya Krom: ikon di atas, label di bawah,
  /// sudut membulat, border tipis, bayangan lembut.
  Widget _menuCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: _biruSoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 24, color: _biruMuda),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}