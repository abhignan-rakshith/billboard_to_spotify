import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class ThemeConfig {
  // Main App Theme
  static ThemeData get appTheme {
    return ThemeData(
      primarySwatch: Colors.green,
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(AppConstants.spotifyGreenValue),
        brightness: Brightness.light,
      ),
    );
  }

  // Color Palette
  static const Color spotifyGreen = Color(AppConstants.spotifyGreenValue);
  static const Color primaryBlue = Colors.blue;
  static const Color errorRed = Colors.red;
  static const Color successGreen = Colors.green;

  // Status Colors
  static Color? successBackground = Colors.green[50];
  static Color? errorBackground = Colors.red[50];
  static Color? infoBackground = Colors.blue[50];

  static Color? successBorder = Colors.green;
  static Color? errorBorder = Colors.red;
  static Color? infoBorder = Colors.blue;

  static Color? successText = Colors.green[800];
  static Color? errorText = Colors.red[800];
  static Color? infoText = Colors.blue[800];

  // Button Styles
  static ButtonStyle get primaryButtonStyle {
    return ElevatedButton.styleFrom(
      backgroundColor: spotifyGreen,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      textStyle: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  static ButtonStyle get secondaryButtonStyle {
    return ElevatedButton.styleFrom(
      backgroundColor: primaryBlue,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      textStyle: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  static ButtonStyle get outlinedButtonStyle {
    return OutlinedButton.styleFrom(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
    );
  }

  // Text Styles
  static const TextStyle titleStyle = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle subtitleStyle = TextStyle(
    fontSize: 14,
    color: Colors.grey,
  );

  static const TextStyle bodyStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle debugStyle = TextStyle(
    fontSize: 10,
    fontFamily: 'monospace',
  );

  static const TextStyle debugLabelStyle = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.bold,
  );

  // Container Decorations
  static BoxDecoration statusContainerDecoration(String status) {
    Color? backgroundColor;
    Color? borderColor;

    if (status.startsWith('✅')) {
      backgroundColor = successBackground;
      borderColor = successBorder;
    } else if (status.startsWith('❌')) {
      backgroundColor = errorBackground;
      borderColor = errorBorder;
    } else {
      backgroundColor = infoBackground;
      borderColor = infoBorder;
    }

    return BoxDecoration(
      color: backgroundColor,
      border: Border.all(color: borderColor!),
      borderRadius: BorderRadius.circular(8),
    );
  }

  static BoxDecoration get debugContainerDecoration {
    return BoxDecoration(
      color: Colors.grey[100],
      borderRadius: BorderRadius.circular(8),
    );
  }

  static BoxDecoration get cardDecoration {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  // Helper Methods
  static Color getStatusTextColor(String status) {
    if (status.startsWith('✅')) {
      return successText!;
    } else if (status.startsWith('❌')) {
      return errorText!;
    } else {
      return infoText!;
    }
  }

  // Responsive Padding
  static EdgeInsets responsivePadding(BuildContext context) {
    return EdgeInsets.symmetric(
      horizontal: MediaQuery.of(context).size.width * 0.08,
      vertical: AppConstants.defaultPadding,
    );
  }
}