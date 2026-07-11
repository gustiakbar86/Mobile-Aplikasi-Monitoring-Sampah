import 'dart:convert';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:url_launcher/url_launcher.dart';

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

    // Minta izin kamera dan lokasi SEBELUM WebView dibuka.
    _requestUpfrontPermissions();
  }

  Future<void> _requestUpfrontPermissions() async {
    await ph.Permission.camera.request();
    await ph.Permission.location.request();
  }

  void onWebViewCreated(InAppWebViewController controller) {
    webViewController = controller;
    controller.addJavaScriptHandler(
      handlerName: 'ambilFotoKamera',
      callback: (args) async {
        final base64Image = await _ambilFotoDenganKamera();
        return base64Image;
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

  Future<PermissionResponse> onPermissionRequest(
    InAppWebViewController controller,
    PermissionRequest request,
  ) async {
    // Izin native Android/iOS sesuai jenis resource yang diminta web.
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

  Future<bool> onCreateWindow(
    InAppWebViewController controller,
    CreateWindowAction createWindowAction,
  ) async {
    final url = createWindowAction.request.url?.toString();
    if (url != null) {
      await _openExternally(url);
    }
    return false;
  }

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