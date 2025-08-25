import 'package:assign_app/views/auth/login_screen.dart';
import 'package:assign_app/views/auth/otp_verification_screen.dart';
import 'package:assign_app/views/common/splash_screen.dart';
import 'package:assign_app/views/objects/object_detail_screen.dart';
import 'package:assign_app/views/objects/object_form_screen.dart';
import 'package:assign_app/views/objects/object_list_screen.dart';
import 'package:get/get.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String otpVerification = '/otp';
  static const String objectList = '/objectList';
  // route patterns that expect an id parameter
  static const String objectDetail = '/objectDetail/:id';
  static const String objectEdit = '/objectEdit/:id';
  static const String objectForm = '/objectForm';

  /// Helpers to build concrete route strings with ids
  static String objectDetailWithId(String id) => '/objectDetail/$id';
  static String objectEditWithId(String id) => '/objectEdit/$id';

  static final routes = [
    GetPage(name: splash, page: () => SplashScreen()),
    GetPage(name: login, page: () => LoginScreen()),
    GetPage(name: otpVerification, page: () => OTPVerificationScreen()),
    GetPage(name: objectList, page: () => ObjectListScreen()),
    // objectDetail uses ObjectDetailScreen and expects an `id` param
    GetPage(name: objectDetail, page: () => ObjectDetailScreen()),
    // objectEdit should show the form in edit mode
    GetPage(name: objectEdit, page: () => ObjectFormScreen()),
    GetPage(name: objectForm, page: () => ObjectFormScreen()),
  ];
}
