import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/home_controller.dart';
import 'dashboard_page.dart';
import 'input_sampah_page.dart';
import 'riwayat_page.dart';

class HomeView extends GetView<HomeController> {
  HomeView({super.key});

  final List<Widget> pages = const [
    DashboardPage(),
    InputSampahPage(),
    RiwayatPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(

        body: pages[controller.selectedIndex.value],

        bottomNavigationBar: BottomNavigationBar(
          currentIndex: controller.selectedIndex.value,
          onTap: controller.changeIndex,

          type: BottomNavigationBarType.fixed,

          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey,

          items: const [

            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),

            BottomNavigationBarItem(
              icon: Icon(Icons.add_box),
              label: 'Input Data Sampah',
            ),

            BottomNavigationBarItem(
              icon: Icon(Icons.history),
              label: 'Riwayat Input',
            ),
          ],
        ),
      ),
    );
  }
}