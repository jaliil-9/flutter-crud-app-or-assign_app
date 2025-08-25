import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'app/theme/app_theme.dart';
import 'app/routes/app_routes.dart';
import 'app/widgets/app_wrapper.dart';
import 'bindings/initial_binding.dart';
import 'controllers/theme_controller.dart';
import 'utils/error_handler.dart';
import 'utils/connectivity_helper.dart';
import 'services/logging_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize GetStorage
  await GetStorage.init();

  // Initialize other services
  await LoggingService.initialize();
  ErrorHandler.initialize();
  ConnectivityHelper.initialize();

  // Initialize theme controller
  Get.put(ThemeController());

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Log app startup
  LoggingService.info('Application started');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Assign App',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: Get.find<ThemeController>().themeMode,
      initialRoute: AppRoutes.splash,
      getPages: AppRoutes.routes,
      initialBinding: InitialBinding(),
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return AppWrapper(child: child ?? const SizedBox.shrink());
      },
      // Handle unknown routes
      unknownRoute: GetPage(
        name: '/not-found',
        page: () => const Scaffold(body: Center(child: Text('Page not found'))),
      ),
    );
  }
}
