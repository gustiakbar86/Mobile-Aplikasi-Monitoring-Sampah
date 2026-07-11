import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';

import '../controllers/webview_controller.dart';

class WebviewView extends GetView<WebviewPageController> {
  const WebviewView({super.key});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // Tombol back Android
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
                  // Wajib agar getUserMedia (kamera) dan geolocation dari
                  // halaman web bisa jalan di dalam WebView.
                  mediaPlaybackRequiresUserGesture: false,
                  allowsInlineMediaPlayback: true,
                  geolocationEnabled: true,
                  useOnDownloadStart: true,
                  javaScriptEnabled: true,
                  domStorageEnabled: true,
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
                // Google Maps
                onCreateWindow: controller.onCreateWindow,
                shouldOverrideUrlLoading: controller.shouldOverrideUrlLoading,
                onReceivedError: (c, request, error) {                  
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}