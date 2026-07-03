import 'dart:convert';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

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
  }

  void onWebViewCreated(InAppWebViewController controller) {
    webViewController = controller;

    // Jembatan: web memanggil handler ini untuk membuka KAMERA BAWAAN Android
    // (kamera belakang / environment) via image_picker, lalu menerima foto
    // sebagai data URL base64. Ini melewati file chooser WebView yang tidak
    // andal membuka kamera (kadang malah membuka file manager).
    controller.addJavaScriptHandler(
      handlerName: 'ambilFotoKamera',
      callback: (args) async {
        try {
          // Pastikan izin kamera sudah diberikan.
          final status = await ph.Permission.camera.request();
          if (!status.isGranted) return null;

          final XFile? foto = await ImagePicker().pickImage(
            source: ImageSource.camera,
            preferredCameraDevice: CameraDevice.rear, // environment / kamera belakang
            imageQuality: 70,
            maxWidth: 1280,
          );
          if (foto == null) return null;

          final bytes = await foto.readAsBytes();
          final b64 = base64Encode(bytes);
          return 'data:image/jpeg;base64,$b64';
        } on Object catch (e) {
          return null;
        }
      },
    );
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
  /// permintaan izin dari halaman web.
  Future<PermissionResponse> onPermissionRequest(
    InAppWebViewController controller,
    PermissionRequest request,
  ) async {
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
}