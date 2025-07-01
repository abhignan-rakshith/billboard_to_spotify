import 'package:flutter/material.dart';
import 'constants/app_constants.dart';
import 'config/theme_config.dart';
import 'config/app_routes.dart';
import 'screens/login_screen.dart';
import 'screens/billboard_screen.dart';
import 'screens/results_screen.dart';
import 'screens/playlist_creation_screen.dart';

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
      initialRoute: AppRoutes.login,
      debugShowCheckedModeBanner: false,
      routes: {
        AppRoutes.login: (context) => const LoginScreen(),
        AppRoutes.billboard: (context) => const BillboardScreen(),
      },
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case AppRoutes.results:
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (context) => ResultsScreen(
                selectedDate: args['selectedDate'],
                songs: args['songs'],
                artists: args['artists'],
              ),
            );
          case AppRoutes.playlistCreation:
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (context) => PlaylistCreationScreen(
                selectedDate: args['selectedDate'],
                songs: args['songs'],
                artists: args['artists'],
              ),
            );
          default:
            return null;
        }
      },
    );
  }
}
