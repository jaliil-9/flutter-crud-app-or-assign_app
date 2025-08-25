import 'package:flutter/material.dart';
import '../app/theme/app_dimensions.dart';

class ResponsiveHelper {
  /// Get responsive value based on screen size
  static T responsive<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth >= AppDimensions.tabletBreakpoint) {
      return desktop ?? tablet ?? mobile;
    } else if (screenWidth >= AppDimensions.mobileBreakpoint) {
      return tablet ?? mobile;
    } else {
      return mobile;
    }
  }

  /// Get responsive padding based on screen size
  static EdgeInsets getScreenPadding(BuildContext context) {
    return EdgeInsets.all(AppDimensions.getScreenPadding(context));
  }

  /// Get responsive horizontal padding
  static EdgeInsets getHorizontalPadding(BuildContext context) {
    return EdgeInsets.symmetric(
      horizontal: AppDimensions.getScreenPadding(context),
    );
  }

  /// Get responsive vertical padding
  static EdgeInsets getVerticalPadding(BuildContext context) {
    return EdgeInsets.symmetric(
      vertical: AppDimensions.getScreenPadding(context),
    );
  }

  /// Get responsive font size
  static double getFontSize(
    BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    return responsive<double>(
      context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
  }

  /// Get responsive icon size
  static double getIconSize(
    BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    return responsive<double>(
      context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
  }

  /// Get responsive spacing
  static double getSpacing(
    BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    return responsive<double>(
      context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
  }

  /// Get responsive width
  static double getWidth(
    BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    return responsive<double>(
      context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
  }

  /// Get responsive height
  static double getHeight(
    BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    return responsive<double>(
      context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
  }

  /// Get responsive grid columns
  static int getGridColumns(BuildContext context) {
    return AppDimensions.getGridColumns(context);
  }

  /// Get responsive card width
  static double getCardWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final padding = AppDimensions.getScreenPadding(context) * 2;
    final availableWidth = screenWidth - padding;

    if (AppDimensions.isDesktop(context)) {
      final columns = getGridColumns(context);
      final spacing = AppDimensions.gridSpacing * (columns - 1);
      return (availableWidth - spacing) / columns;
    } else if (AppDimensions.isTablet(context)) {
      return availableWidth / 2 - AppDimensions.gridSpacing / 2;
    } else {
      return availableWidth;
    }
  }

  /// Get responsive dialog width
  static double getDialogWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (AppDimensions.isDesktop(context)) {
      return AppDimensions.dialogMaxWidth;
    } else if (AppDimensions.isTablet(context)) {
      return screenWidth * 0.7;
    } else {
      return screenWidth - (AppDimensions.paddingLarge * 2);
    }
  }

  /// Check if screen is mobile size
  static bool isMobile(BuildContext context) {
    return AppDimensions.isMobile(context);
  }

  /// Check if screen is tablet size
  static bool isTablet(BuildContext context) {
    return AppDimensions.isTablet(context);
  }

  /// Check if screen is desktop size
  static bool isDesktop(BuildContext context) {
    return AppDimensions.isDesktop(context);
  }

  /// Get responsive layout based on screen size
  static Widget responsiveLayout(
    BuildContext context, {
    required Widget mobile,
    Widget? tablet,
    Widget? desktop,
  }) {
    if (isDesktop(context)) {
      return desktop ?? tablet ?? mobile;
    } else if (isTablet(context)) {
      return tablet ?? mobile;
    } else {
      return mobile;
    }
  }

  /// Get responsive cross axis count for grids
  static int getCrossAxisCount(BuildContext context) {
    if (isDesktop(context)) {
      return 4;
    } else if (isTablet(context)) {
      return 2;
    } else {
      return 1;
    }
  }

  /// Get responsive aspect ratio
  static double getAspectRatio(BuildContext context) {
    if (isDesktop(context)) {
      return 16 / 9;
    } else if (isTablet(context)) {
      return 4 / 3;
    } else {
      return 16 / 9;
    }
  }
}
