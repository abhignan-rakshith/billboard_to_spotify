import 'package:flutter/material.dart';
import 'constants/app_constants.dart';
import 'config/theme_config.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appTitle,
      theme: ThemeConfig.appTheme,
      home: const LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}