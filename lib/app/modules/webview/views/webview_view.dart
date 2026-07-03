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
                  //useOnGeolocationPermissionsShowPrompt: true,
                  useOnDownloadStart: true,
                  javaScriptEnabled: true,
                  domStorageEnabled: true,
                  // Penanda agar web pengunjung tahu halaman dibuka dari dalam
                  // aplikasi (WebView). Web akan memakai jalur kamera live
                  // (getUserMedia) alih-alih <input type="file"> yang di WebView
                  // malah membuka file manager.
                  userAgent:
                      "Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 "
                      "(KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36 PWasteApp/1.0",
                  useHybridComposition: true,
                  allowFileAccess: true,
                ),
                onWebViewCreated: controller.onWebViewCreated,
                onLoadStart: (c, url) => controller.onLoadStart(url?.toString()),
                onLoadStop: (c, url) => controller.onLoadStop(url?.toString()),
                onProgressChanged: (c, p) => controller.onProgressChanged(p),
                onPermissionRequest: controller.onPermissionRequest,
                onGeolocationPermissionsShowPrompt:
                    controller.onGeolocationPermissionsShowPrompt,
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