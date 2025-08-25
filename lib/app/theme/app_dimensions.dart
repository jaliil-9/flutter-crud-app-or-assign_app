
import 'package:flutter/material.dart';

class AppDimensions {
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 840;
  static const double desktopBreakpoint = 1200;

  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;

  static const double spacingSmall = 8.0;
  static const double spacingMedium = 16.0;
  static const double spacingLarge = 24.0;

  static const double iconSmall = 20.0;
  static const double iconMedium = 24.0;
  static const double iconLarge = 32.0;

  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusMedium = 12.0;
  static const double borderRadiusLarge = 16.0;

  static const double gridSpacing = 16.0;
  static const double dialogMaxWidth = 600.0;

  static EdgeInsets paddingAllSmall = const EdgeInsets.all(paddingSmall);
  static EdgeInsets paddingAllMedium = const EdgeInsets.all(paddingMedium);
  static EdgeInsets paddingAllLarge = const EdgeInsets.all(paddingLarge);

  static double getScreenPadding(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth >= desktopBreakpoint) {
      return paddingLarge;
    } else if (screenWidth >= tabletBreakpoint) {
      return paddingMedium;
    } else {
      return paddingSmall;
    }
  }

  static int getGridColumns(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth >= desktopBreakpoint) {
      return 4;
    } else if (screenWidth >= tabletBreakpoint) {
      return 3;
    } else {
      return 2;
    }
  }

  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileBreakpoint;
  }

  static bool isTablet(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return screenWidth >= mobileBreakpoint && screenWidth < tabletBreakpoint;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= tabletBreakpoint;
  }
}
