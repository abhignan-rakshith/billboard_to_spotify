import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';

class HttpHelper {
  static Future<http.Response> requestWithRetry(
    Future<http.Response> Function() request, {
    int maxRetries = AppConstants.maxRetries,
    Duration? timeout,
  }) async {
    final requestTimeout =
        timeout ?? const Duration(seconds: AppConstants.httpTimeoutSeconds);

    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        final response = await request().timeout(requestTimeout);
        if (response.statusCode == 429) {
          // Rate limited - wait before retrying
          await Future.delayed(
            Duration(
              seconds: AppConstants.rateLimitDelaySeconds * (attempt + 1),
            ),
          );
          continue;
        }
        return response;
      } catch (e) {
        if (attempt == maxRetries - 1) rethrow;
        // Exponential backoff for retries
        await Future.delayed(
          Duration(milliseconds: AppConstants.retryBaseDelayMs * (attempt + 1)),
        );
      }
    }
    throw Exception('Request failed after $maxRetries attempts');
  }

  // Convenience method for search requests with shorter timeout
  static Future<http.Response> searchWithRetry(
    Future<http.Response> Function() request, {
    int maxRetries = AppConstants.maxRetries,
  }) async {
    return requestWithRetry(
      request,
      maxRetries: maxRetries,
      timeout: const Duration(seconds: AppConstants.searchTimeoutSeconds),
    );
  }

  // Convenience method for playlist operations with longer timeout
  static Future<http.Response> playlistWithRetry(
    Future<http.Response> Function() request, {
    int maxRetries = AppConstants.maxRetries,
  }) async {
    return requestWithRetry(
      request,
      maxRetries: maxRetries,
      timeout: const Duration(seconds: AppConstants.playlistTimeoutSeconds),
    );
  }
}
