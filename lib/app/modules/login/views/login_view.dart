import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/login_controller.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(

        child: SingleChildScrollView(

          padding: const EdgeInsets.symmetric(
            horizontal: 30,
            vertical: 60,
          ),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.center,

            children: [

              // =========================
              // LOGO
              // =========================
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,

                children: [

                  // Logo Pelindo
                  Image.asset(
                    'assets/images/pelindo.png',
                    width: 80,
                    height: 80,
                    fit: BoxFit.contain,
                  ),

                  const SizedBox(width: 10),

                  // Logo PWaste
                  Image.asset(
                    'assets/images/pwaste.png',
                    width: 180,
                    height: 80,
                    fit: BoxFit.contain,
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // =========================
              // TITLE
              // =========================
              const Text(
                "PT Pelindo Subregional Kalimantan",

                textAlign: TextAlign.center,

                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 40),

              // =========================
              // EMAIL
              // =========================
              TextField(

                controller: controller.emailC,

                keyboardType:
                    TextInputType.emailAddress,

                decoration: InputDecoration(

                  labelText: 'Email / Username',

                  prefixIcon: const Icon(
                    Icons.person,
                    color: Colors.blue,
                  ),

                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(10),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // =========================
              // PASSWORD
              // =========================
              TextField(

                controller: controller.passwordC,

                obscureText: true,

                decoration: InputDecoration(

                  labelText: 'Password',

                  prefixIcon: const Icon(
                    Icons.lock,
                    color: Colors.blue,
                  ),

                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(10),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // =========================
              // BUTTON LOGIN
              // =========================
              SizedBox(

                width: double.infinity,
                height: 50,

                child: ElevatedButton(

                  style: ElevatedButton.styleFrom(

                    backgroundColor: Colors.blue,

                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(10),
                    ),
                  ),

                  onPressed: () {

                    // validasi kosong
                    if (controller.emailC.text
                        .isEmpty) {

                      Get.snackbar(
                        "Error",
                        "Email wajib diisi",
                      );

                      return;
                    }

                    if (controller.passwordC.text
                        .isEmpty) {

                      Get.snackbar(
                        "Error",
                        "Password wajib diisi",
                      );

                      return;
                    }

                    controller.login();
                  },

                  child: Obx(() {

                    return controller.isLoading.value

                        ? const SizedBox(

                            width: 25,
                            height: 25,

                            child:
                                CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )

                        : const Text(

                            "LOGIN",

                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          );
                  }),
                ),
              ),

              const SizedBox(height: 30),

              const Divider(thickness: 1),

              const SizedBox(height: 20),

              // =========================
              // PENGUNJUNG
              // =========================
              const Text(

                "Bukan petugas? Lapor temuan sampah di sini:",

                style: TextStyle(
                  fontSize: 12,
                ),
              ),

              const SizedBox(height: 10),

              SizedBox(

                width: double.infinity,
                height: 50,

                child: OutlinedButton.icon(

                  style: OutlinedButton.styleFrom(

                    side: const BorderSide(
                      color: Colors.blue,
                    ),

                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(10),
                    ),
                  ),

                  icon: const Icon(
                    Icons.camera_alt,
                    color: Colors.blue,
                  ),

                  label: const Text(

                    "LAPOR SAMPAH (PENGUNJUNG)",

                    style: TextStyle(
                      color: Colors.blue,
                    ),
                  ),

                  onPressed: () {

                    Get.snackbar(
                      "Info",
                      "Membuka halaman laporan pengunjung...",
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}