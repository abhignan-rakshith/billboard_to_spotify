import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityHelper {
  static Future<bool> hasConnection() async {
    try {
      // First check connectivity status
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        return false;
      }

      // Still do the actual internet test as fallback
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    } catch (e) {
      // Handle any connectivity_plus exceptions
      print('Connectivity check error: $e');
      // Fallback to basic internet check
      try {
        final result = await InternetAddress.lookup('google.com');
        return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      } on SocketException catch (_) {
        return false;
      }
    }
  }

  static String getOfflineMessage() {
    return 'No internet connection. Please check your network and try again.';
  }
}
