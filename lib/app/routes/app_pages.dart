import 'package:get/get.dart';
import 'package:flutter/material.dart';
import './app_routes.dart';

// This is a placeholder for your splash screen.
// You should replace it with your actual splash screen widget.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Splash Screen')));
  }
}

class AppPages {
  static final List<GetPage> routes = [
    GetPage(name: AppRoutes.splash, page: () => const SplashScreen()),
    // Add your other GetPage routes here
  ];
}
