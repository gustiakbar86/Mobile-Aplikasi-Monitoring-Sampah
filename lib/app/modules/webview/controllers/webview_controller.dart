import 'dart:convert';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:url_launcher/url_launcher.dart';

/// Argumen yang dikirim via Get.arguments saat navigasi ke halaman webview.
/// Contoh:
///   Get.toNamed('/webview', arguments: WebviewArgs(
///     url: 'https://gusti-edo.org/pengunjung-web-p-waste/',
///     title: 'Laporan Pengunjung',
///   ));
class WebviewArgs {
  final String url;
  final String title;

  const WebviewArgs({required this.url, this.title = ''});
}

class WebviewPageController extends GetxController {
  InAppWebViewController? webViewController;

  RxBool isLoading = true.obs;
  RxDouble progress = 0.0.obs;
  RxString title = ''.obs;

  late final WebviewArgs args;

  @override
  void onInit() {
    super.onInit();
    final raw = Get.arguments;
    args = raw is WebviewArgs
        ? raw
        : const WebviewArgs(url: 'about:blank', title: 'Halaman');
    title.value = args.title;

    // Minta izin kamera & lokasi SEBELUM WebView dibuka. Tanpa ini,
    // Android sering tidak menampilkan opsi "Kamera" di file chooser
    // saat halaman web memakai <input type="file" capture>, karena
    // izin runtime belum pernah disetujui user sama sekali.
    _requestUpfrontPermissions();
  }

  Future<void> _requestUpfrontPermissions() async {
    await ph.Permission.camera.request();
    await ph.Permission.location.request();
  }

  void onWebViewCreated(InAppWebViewController controller) {
    webViewController = controller;

    // Web memanggil ini lewat:
    //   window.flutter_inappwebview.callHandler('ambilFotoKamera');
    // Handler ini WAJIB didaftarkan sebelum web sempat memanggilnya,
    // kalau tidak, panggilan dari JS akan diabaikan tanpa error apapun
    // (persis gejala "tombol ambil foto tidak bereaksi").
    controller.addJavaScriptHandler(
      handlerName: 'ambilFotoKamera',
      callback: (args) async {
        final base64Image = await _ambilFotoDenganKamera();
        // Dikembalikan sebagai return value dari callHandler(...) di JS,
        // bisa ditangkap lewat:
        //   const hasil = await window.flutter_inappwebview.callHandler('ambilFotoKamera');
        return base64Image; // null kalau user membatalkan
      },
    );
  }

  Future<String?> _ambilFotoDenganKamera() async {
    final status = await ph.Permission.camera.request();
    if (!status.isGranted) return null;

    final picked = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
      maxWidth: 1600,
      maxHeight: 1600,
    );
    if (picked == null) return null;

    final bytes = await picked.readAsBytes();
    // Web mengecek `dataUrl.indexOf('data:') !== 0`, jadi HARUS berupa
    // data URL lengkap, bukan base64 mentah.
    return 'data:image/jpeg;base64,${base64Encode(bytes)}';
  }

  void onLoadStart(String? url) {
    isLoading.value = true;
  }

  void onLoadStop(String? url) {
    isLoading.value = false;
  }

  void onProgressChanged(int p) {
    progress.value = p / 100;
    if (p >= 100) isLoading.value = false;
  }

  Future<bool> canGoBack() async {
    return await webViewController?.canGoBack() ?? false;
  }

  Future<void> goBack() async {
    await webViewController?.goBack();
  }

  Future<void> reload() async {
    await webViewController?.reload();
  }

  /// Dipanggil saat halaman web meminta izin kamera/mikrofon (getUserMedia)
  /// atau lokasi. Tanpa handler ini, InAppWebView akan otomatis MENOLAK
  /// permintaan izin dari halaman web, sehingga fitur "Ambil Foto Titik
  /// Sampah" di web pengunjung tidak akan berfungsi di dalam WebView.
  Future<PermissionResponse> onPermissionRequest(
    InAppWebViewController controller,
    PermissionRequest request,
  ) async {
    // Minta izin native Android/iOS sesuai jenis resource yang diminta web.
    final wantsCamera = request.resources.contains(PermissionResourceType.CAMERA);
    final wantsMic = request.resources.contains(PermissionResourceType.MICROPHONE);

    if (wantsCamera) {
      await ph.Permission.camera.request();
    }
    if (wantsMic) {
      await ph.Permission.microphone.request();
    }

    return PermissionResponse(
      resources: request.resources,
      action: PermissionResponseAction.GRANT,
    );
  }

  Future<GeolocationPermissionShowPromptResponse> onGeolocationPermissionsShowPrompt(
    InAppWebViewController controller,
    String origin,
  ) async {
    final status = await ph.Permission.location.request();
    return GeolocationPermissionShowPromptResponse(
      origin: origin,
      allow: status.isGranted,
      retain: true,
    );
  }

  // Deteksi URL yang mengarah ke Google Maps / skema "geo:" — ini tidak
  // masuk akal dirender di dalam WebView, jadi harus dilempar ke app
  // Google Maps atau browser eksternal.
  bool _isMapsUrl(String url) {
    final u = url.toLowerCase();
    return u.startsWith('geo:') ||
        u.contains('google.com/maps') ||
        u.contains('maps.google.') ||
        u.contains('goo.gl/maps') ||
        u.contains('maps.app.goo.gl');
  }

  Future<void> _openExternally(String url) async {
    final uri = Uri.parse(url);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) {
      Get.snackbar(
        "Gagal membuka",
        "Tidak dapat membuka tautan: $url",
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Dipanggil saat halaman web coba buka tab/window baru, mis. lewat
  /// window.open(url, '_blank') atau <a target="_blank">. Tanpa handler
  /// ini, flutter_inappwebview DIAM-DIAM MENGABAIKAN permintaan tersebut
  /// -- ini penyebab utama tombol "Buka Google Maps" terlihat tidak
  /// merespons sama sekali saat ditekan.
  Future<bool> onCreateWindow(
    InAppWebViewController controller,
    CreateWindowAction createWindowAction,
  ) async {
    final url = createWindowAction.request.url?.toString();
    if (url != null) {
      await _openExternally(url);
    }
    // return false = tidak membuat window WebView baru (karena sudah
    // ditangani dengan membuka app eksternal).
    return false;
  }

  /// Jaring pengaman untuk kasus link Maps yang dinavigasi langsung
  /// (bukan window baru) di dalam WebView yang sama.
  Future<NavigationActionPolicy> shouldOverrideUrlLoading(
    InAppWebViewController controller,
    NavigationAction navigationAction,
  ) async {
    final url = navigationAction.request.url?.toString();
    if (url != null && _isMapsUrl(url)) {
      await _openExternally(url);
      return NavigationActionPolicy.CANCEL;
    }
    return NavigationActionPolicy.ALLOW;
  }
}