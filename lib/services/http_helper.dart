import 'package:http/http.dart' as http;

class HttpHelper {
  static Future<http.Response> requestWithRetry(
    Future<http.Response> Function() request, {
    int maxRetries = 3,
  }) async {
    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        final response = await request();
        if (response.statusCode == 429) {
          await Future.delayed(Duration(seconds: 2 * (attempt + 1)));
          continue;
        }
        return response;
      } catch (e) {
        if (attempt == maxRetries - 1) rethrow;
        await Future.delayed(Duration(milliseconds: 1000 * (attempt + 1)));
      }
    }
    throw Exception('Request failed after $maxRetries attempts');
  }
}
