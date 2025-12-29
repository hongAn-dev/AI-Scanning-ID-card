import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';

class ScreenUtils {
  static late ScreenUtils _instance;

  static MediaQueryData? _mediaQueryData;
  static double? screenWidth;
  static double? screenHeight;
  static double? bottomPadding;
  static EdgeInsets? padding;

  factory ScreenUtils() {
    return _instance;
  }

  ScreenUtils._();

  static void init(BuildContext context) {
    _instance = ScreenUtils._();

    _mediaQueryData = MediaQuery.of(context);
    screenWidth = _mediaQueryData!.size.width;
    screenHeight = _mediaQueryData!.size.height;
    padding = _mediaQueryData!.padding;
  }

  // Responsive breakpoint checks
  static bool isMobile(BuildContext context) {
    return ResponsiveBreakpoints.of(context).breakpoint.name == MOBILE;
  }

  static bool isTablet(BuildContext context) {
    return ResponsiveBreakpoints.of(context).breakpoint.name == TABLET;
  }

  static bool isDesktop(BuildContext context) {
    return ResponsiveBreakpoints.of(context).breakpoint.name == DESKTOP;
  }

  // Responsive padding
  static EdgeInsets getResponsivePadding(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.all(16.0);
    } else if (isTablet(context)) {
      return const EdgeInsets.all(24.0);
    } else {
      return const EdgeInsets.all(32.0);
    }
  }

  // Responsive margin
  static EdgeInsets getResponsiveMargin(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0);
    } else if (isTablet(context)) {
      return const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0);
    } else {
      return const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0);
    }
  }

  // Responsive font size
  static double getResponsiveFontSize(
      BuildContext context, double baseFontSize) {
    if (isMobile(context)) {
      return baseFontSize;
    } else if (isTablet(context)) {
      return baseFontSize * 1.1;
    } else {
      return baseFontSize * 1.2;
    }
  }

  // Responsive icon size
  static double getResponsiveIconSize(
      BuildContext context, double baseIconSize) {
    if (isMobile(context)) {
      return baseIconSize;
    } else if (isTablet(context)) {
      return baseIconSize * 1.2;
    } else {
      return baseIconSize * 1.4;
    }
  }

  // Responsive grid columns
  static int getResponsiveColumns(BuildContext context) {
    if (isMobile(context)) {
      return 2;
    } else if (isTablet(context)) {
      return 2;
    } else {
      return 3;
    }
  }

  // Responsive card width
  static double getResponsiveCardWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (isMobile(context)) {
      return screenWidth * 0.9;
    } else if (isTablet(context)) {
      return screenWidth * 0.45;
    } else {
      return screenWidth * 0.3;
    }
  }

  // Responsive spacing
  static double getResponsiveSpacing(BuildContext context, double baseSpacing) {
    if (isMobile(context)) {
      return baseSpacing;
    } else if (isTablet(context)) {
      return baseSpacing * 1.5;
    } else {
      return baseSpacing * 2.0;
    }
  }

  // Responsive border radius
  static double getResponsiveBorderRadius(
      BuildContext context, double baseRadius) {
    if (isMobile(context)) {
      return baseRadius;
    } else if (isTablet(context)) {
      return baseRadius * 1.2;
    } else {
      return baseRadius * 1.5;
    }
  }

  // Responsive button height
  static double getResponsiveButtonHeight(BuildContext context) {
    if (isMobile(context)) {
      return 48.0;
    } else if (isTablet(context)) {
      return 56.0;
    } else {
      return 64.0;
    }
  }

  // Responsive app bar height
  static double getResponsiveAppBarHeight(BuildContext context) {
    if (isMobile(context)) {
      return kToolbarHeight;
    } else if (isTablet(context)) {
      return kToolbarHeight * 1.2;
    } else {
      return kToolbarHeight * 1.4;
    }
  }

  // Responsive drawer width
  static double getResponsiveDrawerWidth(BuildContext context) {
    if (isMobile(context)) {
      return 280.0;
    } else if (isTablet(context)) {
      return 320.0;
    } else {
      return 360.0;
    }
  }

  // Responsive value selector
  static T responsiveValue<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isMobile(context)) {
      return mobile;
    } else if (isTablet(context)) {
      return tablet ?? mobile;
    } else {
      return desktop ?? tablet ?? mobile;
    }
  }

  // Get current breakpoint name
  static String getBreakpointName(BuildContext context) {
    return ResponsiveBreakpoints.of(context).breakpoint.name ?? 'unknown';
  }
}
