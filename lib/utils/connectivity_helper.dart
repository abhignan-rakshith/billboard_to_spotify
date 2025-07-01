import 'dart:io';

class ConnectivityHelper {
  static Future<bool> hasConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  static String getOfflineMessage() {
    return 'No internet connection. Please check your network and try again.';
  }
}
