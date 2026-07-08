import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';

import '../controllers/webview_controller.dart';

class WebviewView extends GetView<WebviewPageController> {
  const WebviewView({super.key});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // Tombol back Android: mundur di history web dulu, baru keluar halaman.
      onWillPop: () async {
        if (await controller.canGoBack()) {
          await controller.goBack();
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: const Color(0xFF1A3A6B),
          foregroundColor: Colors.white,
          title: Obx(() => Text(controller.title.value)),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: controller.reload,
            ),
          ],
        ),
        body: Column(
          children: [
            Obx(() => controller.isLoading.value
                ? LinearProgressIndicator(
                    value: controller.progress.value == 0
                        ? null
                        : controller.progress.value,
                    minHeight: 3,
                    color: const Color(0xFF1A3A6B),
                    backgroundColor: Colors.grey.shade200,
                  )
                : const SizedBox(height: 3)),
            Expanded(
              child: InAppWebView(
                initialUrlRequest: URLRequest(url: WebUri(controller.args.url)),
                initialSettings: InAppWebViewSettings(
                  // Wajib true agar getUserMedia (kamera) & geolocation dari
                  // halaman web bisa jalan di dalam WebView.
                  mediaPlaybackRequiresUserGesture: false,
                  allowsInlineMediaPlayback: true,
                  geolocationEnabled: true,
                  useOnDownloadStart: true,
                  javaScriptEnabled: true,
                  domStorageEnabled: true,
                  // Wajib true agar window.open()/target="_blank" di halaman
                  // web (tombol "Buka Google Maps") terdeteksi lewat
                  // onCreateWindow, bukan langsung diabaikan WebView.
                  supportMultipleWindows: true,
                  javaScriptCanOpenWindowsAutomatically: true,
                ),
                onWebViewCreated: controller.onWebViewCreated,
                onLoadStart: (c, url) => controller.onLoadStart(url?.toString()),
                onLoadStop: (c, url) => controller.onLoadStop(url?.toString()),
                onProgressChanged: (c, p) => controller.onProgressChanged(p),
                onPermissionRequest: controller.onPermissionRequest,
                onGeolocationPermissionsShowPrompt:
                    controller.onGeolocationPermissionsShowPrompt,
                // Dipanggil saat halaman web coba buka tab/window baru
                // (window.open(...) atau <a target="_blank">), termasuk
                // tombol "Buka Google Maps". Kita lempar URL-nya ke app
                // Google Maps / browser eksternal lewat url_launcher.
                onCreateWindow: controller.onCreateWindow,
                // Jaga-jaga untuk link yang navigasi langsung (bukan window
                // baru) tapi mengarah ke maps.google.com / geo: scheme.
                shouldOverrideUrlLoading: controller.shouldOverrideUrlLoading,
                onReceivedError: (c, request, error) {
                  // Bisa ditampilkan halaman error kustom di sini bila perlu.
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}