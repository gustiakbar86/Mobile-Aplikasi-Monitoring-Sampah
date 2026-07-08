// ============================================================
// lib/app/services/delegasi_notif_service.dart
//
// Notifikasi LOKAL untuk tugas delegasi (Opsi B).
// Cara kerja: selama app petugas terbuka, service ini mengecek server
// tiap X detik. Jika jumlah "tugas delegasi belum dikerjakan" bertambah
// dibanding cek sebelumnya, tampilkan notifikasi lokal.
//
// Tidak butuh Firebase. Tidak ada perubahan backend.
// Keterbatasan: notif hanya muncul saat aplikasi sedang DIBUKA.
// ============================================================
import 'dart:async';
import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/api_endpoints.dart'; // sesuaikan path bila berbeda

class DelegasiNotifService {
  DelegasiNotifService._();
  static final DelegasiNotifService instance = DelegasiNotifService._();

  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  Timer? _timer;
  bool _initialized = false;
  bool _sedangCek = false; // cegah tumpang-tindih request kalau interval pendek

  // Interval polling (detik).
  // CATATAN: diturunkan dari 30s -> 8s. Lihat penjelasan di chat soal
  // trade-off beban server & baterai sebelum menurunkan lebih jauh lagi.
  static const int _intervalDetik = 8;

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'pwaste_delegasi_lokal',
    'Tugas Delegasi',
    description: 'Pemberitahuan tugas delegasi baru dari admin',
    importance: Importance.high,
  );

  // ---------- Inisialisasi (panggil sekali, mis. di main) ----------
  Future<void> init() async {
    if (_initialized) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _local.initialize(initSettings);

    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // Android 13+ butuh izin notifikasi
    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  // ---------- Mulai polling (panggil setelah login sbg petugas) ----------
  Future<void> start() async {
    await init();
    _timer?.cancel();

    // Cek pertama kali langsung (tanpa menunggu interval), tapi TANPA
    // memunculkan notif — hanya untuk menyimpan baseline jumlah saat ini.
    await _cek(pertamaKali: true);

    _timer = Timer.periodic(
      const Duration(seconds: _intervalDetik),
      (_) => _cek(),
    );
  }

  // ---------- Stop polling (panggil saat logout) ----------
  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  // ---------- Logika cek ----------
  Future<void> _cek({bool pertamaKali = false}) async {
    // Kalau request sebelumnya belum selesai (mis. koneksi lambat) dan
    // interval sudah lewat lagi, lewati siklus ini supaya tidak menumpuk
    // request paralel ke server.
    if (_sedangCek) return;
    _sedangCek = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return; // belum login

      // Lapis pengaman: notif delegasi hanya untuk petugas, bukan admin.
      // Kalau start() terlanjur dipanggil untuk akun admin, cek ini
      // memastikan polling langsung berhenti & tidak memunculkan notif.
      final role = prefs.getString('login_as') ?? '';
      if (role != 'petugas') {
        stop();
        return;
      }

      final jumlahSekarang = await _hitungTugasDelegasi(token);
      if (jumlahSekarang == null) return; // gagal ambil, jangan ubah baseline

      final jumlahTerakhir = prefs.getInt('delegasi_terakhir') ?? 0;

      if (pertamaKali) {
        // hanya simpan baseline, tidak memunculkan notif
        await prefs.setInt('delegasi_terakhir', jumlahSekarang);
        return;
      }

      if (jumlahSekarang > jumlahTerakhir) {
        final selisih = jumlahSekarang - jumlahTerakhir;
        await _tampilkanNotif(selisih);
      }

      // update baseline (baik naik maupun turun karena sudah dikerjakan)
      await prefs.setInt('delegasi_terakhir', jumlahSekarang);
    } catch (_) {
      // diabaikan; cek berikutnya coba lagi
    } finally {
      _sedangCek = false;
    }
  }

  // Hitung total "tugas delegasi belum dikerjakan" dari kedua endpoint.
  // Kriteria belum dikerjakan: id_laporan_pengunjung terisi & lokasi/jenis kosong.
  Future<int?> _hitungTugasDelegasi(String token) async {
    try {
      final headers = {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      };

      int total = 0;

      for (final url in [
        ApiEndpoints.sampahTerkelola,
        ApiEndpoints.sampahDiserahkan,
      ]) {
        final res = await http.get(
          Uri.parse('$url?per_page=1000&page=1'),
          headers: headers,
        );
        if (res.statusCode != 200) return null;
        final body = jsonDecode(res.body);
        final List data = body['data'] ?? [];
        for (final it in data) {
          final adaDelegasi = it['id_laporan_pengunjung'] != null;
          final lokasiKosong = it['id_lokasi'] == null;
          final jenisKosong = it['id_jenis'] == null;
          if (adaDelegasi && (lokasiKosong || jenisKosong)) {
            total++;
          }
        }
      }
      return total;
    } catch (_) {
      return null;
    }
  }

  Future<void> _tampilkanNotif(int jumlahBaru) async {
    await _local.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'Tugas Delegasi Baru',
      jumlahBaru == 1
          ? 'Anda menerima 1 tugas delegasi baru dari admin. '
              'Buka menu Riwayat Inputan untuk melengkapinya.'
          : 'Anda menerima $jumlahBaru tugas delegasi baru dari admin. '
              'Buka menu Riwayat Inputan untuk melengkapinya.',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }
}