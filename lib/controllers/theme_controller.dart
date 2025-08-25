import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../bindings/controller_binding.dart';

class ThemeController extends BaseController {
  static const String _themeKey = 'theme_mode';
  final GetStorage _storage = GetStorage();

  // Reactive theme mode
  final Rx<ThemeMode> _themeMode = ThemeMode.system.obs;
  ThemeMode get themeMode => _themeMode.value;

  // Getters for current theme state
  bool get isDarkMode {
    if (_themeMode.value == ThemeMode.system) {
      return Get.isPlatformDarkMode;
    }
    return _themeMode.value == ThemeMode.dark;
  }

  bool get isLightMode {
    if (_themeMode.value == ThemeMode.system) {
      return !Get.isPlatformDarkMode;
    }
    return _themeMode.value == ThemeMode.light;
  }

  bool get isSystemMode => _themeMode.value == ThemeMode.system;

  @override
  void onInit() {
    super.onInit();
    _loadThemeFromStorage();
  }

  /// Load theme preference from storage
  void _loadThemeFromStorage() {
    final savedTheme = _storage.read(_themeKey);
    if (savedTheme != null) {
      _themeMode.value = _getThemeModeFromString(savedTheme);
    }
  }

  /// Save theme preference to storage
  void _saveThemeToStorage(ThemeMode mode) {
    _storage.write(_themeKey, mode.toString());
  }

  /// Convert string to ThemeMode
  ThemeMode _getThemeModeFromString(String themeString) {
    switch (themeString) {
      case 'ThemeMode.light':
        return ThemeMode.light;
      case 'ThemeMode.dark':
        return ThemeMode.dark;
      case 'ThemeMode.system':
      default:
        return ThemeMode.system;
    }
  }

  /// Switch to light theme
  void setLightMode() {
    _themeMode.value = ThemeMode.light;
    _saveThemeToStorage(ThemeMode.light);
    Get.changeThemeMode(ThemeMode.light);
  }

  /// Switch to dark theme
  void setDarkMode() {
    _themeMode.value = ThemeMode.dark;
    _saveThemeToStorage(ThemeMode.dark);
    Get.changeThemeMode(ThemeMode.dark);
  }

  /// Switch to system theme
  void setSystemMode() {
    _themeMode.value = ThemeMode.system;
    _saveThemeToStorage(ThemeMode.system);
    Get.changeThemeMode(ThemeMode.system);
  }

  /// Toggle between light and dark theme
  void toggleTheme() {
    if (isDarkMode) {
      setLightMode();
    } else {
      setDarkMode();
    }
  }

  /// Cycle through all theme modes (light -> dark -> system -> light...)
  void cycleTheme() {
    switch (_themeMode.value) {
      case ThemeMode.light:
        setDarkMode();
        break;
      case ThemeMode.dark:
        setSystemMode();
        break;
      case ThemeMode.system:
        setLightMode();
        break;
    }
  }

  /// Get theme mode display name
  String get themeModeDisplayName {
    switch (_themeMode.value) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }

  /// Get theme mode icon
  IconData get themeModeIcon {
    switch (_themeMode.value) {
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
      case ThemeMode.system:
        return Icons.brightness_auto;
    }
  }
}
