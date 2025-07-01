import 'dart:io';
import 'dart:math';
import '../constants/app_constants.dart';

class LocalServerService {
  static HttpServer? _server;
  static Function(String)? _onCodeReceived;
  static int? _currentPort;

  static Future<Map<String, dynamic>?> startServer({
    required Function(String) onCodeReceived,
  }) async {
    try {
      _onCodeReceived = onCodeReceived;

      // Stop existing server if running
      await stopServer();

      // Try to bind to a random available port
      final random = Random();
      for (
        int attempt = 0;
        attempt < AppConstants.serverBindAttempts;
        attempt++
      ) {
        try {
          _currentPort =
              AppConstants.serverPortRangeStart +
              random.nextInt(
                AppConstants.serverPortRangeEnd -
                    AppConstants.serverPortRangeStart,
              );
          _server = await HttpServer.bind(
            InternetAddress.loopbackIPv4,
            _currentPort!,
          );
          break;
        } catch (e) {
          if (attempt == AppConstants.serverBindAttempts - 1) rethrow;
          continue;
        }
      }

      final redirectUri = 'http://127.0.0.1:$_currentPort/callback';
      print('Local server started on $redirectUri');

      _server!.listen((HttpRequest request) async {
        final uri = request.uri;
        print('Received request: ${uri.toString()}');

        if (uri.path == '/callback') {
          final code = uri.queryParameters['code'];
          final error = uri.queryParameters['error'];

          // Send response to browser
          request.response.headers.contentType = ContentType.html;

          if (error != null) {
            request.response.write('''
              <!DOCTYPE html>
              <html>
              <head>
                  <title>Authorization Failed</title>
                  <style>
                      body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Arial, sans-serif; 
                             text-align: center; padding: 50px; background: #f5f5f5; }
                      .container { background: white; padding: 40px; border-radius: 8px; 
                                  box-shadow: 0 2px 10px rgba(0,0,0,0.1); max-width: 400px; 
                                  margin: 0 auto; }
                      .error { color: #d32f2f; }
                      .icon { font-size: 48px; margin-bottom: 20px; }
                  </style>
              </head>
              <body>
                  <div class="container">
                      <div class="icon">❌</div>
                      <h1 class="error">Authorization Failed</h1>
                      <p>Error: $error</p>
                      <p>You can close this window and try again in the app.</p>
                  </div>
              </body>
              </html>
            ''');
          } else if (code != null) {
            request.response.write('''
              <!DOCTYPE html>
              <html>
              <head>
                  <title>Authorization Successful</title>
                  <style>
                      body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Arial, sans-serif; 
                             text-align: center; padding: 50px; background: #f5f5f5; }
                      .container { background: white; padding: 40px; border-radius: 8px; 
                                  box-shadow: 0 2px 10px rgba(0,0,0,0.1); max-width: 400px; 
                                  margin: 0 auto; }
                      .success { color: #1db954; }
                      .icon { font-size: 48px; margin-bottom: 20px; }
                  </style>
              </head>
              <body>
                  <div class="container">
                      <div class="icon">✅</div>
                      <h1 class="success">Authorization Successful!</h1>
                      <p>You can now close this window and return to the Billboard to Spotify app.</p>
                  </div>
                  <script>
                      setTimeout(() => window.close(), 3000);
                  </script>
              </body>
              </html>
            ''');

            // Notify the app
            _onCodeReceived?.call(code);
          } else {
            request.response.write('''
              <!DOCTYPE html>
              <html>
              <head>
                  <title>Invalid Request</title>
                  <style>
                      body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Arial, sans-serif; 
                             text-align: center; padding: 50px; background: #f5f5f5; }
                      .container { background: white; padding: 40px; border-radius: 8px; 
                                  box-shadow: 0 2px 10px rgba(0,0,0,0.1); max-width: 400px; 
                                  margin: 0 auto; }
                      .error { color: #d32f2f; }
                      .icon { font-size: 48px; margin-bottom: 20px; }
                  </style>
              </head>
              <body>
                  <div class="container">
                      <div class="icon">⚠️</div>
                      <h1 class="error">Invalid Request</h1>
                      <p>No authorization code received.</p>
                      <p>You can close this window and try again in the app.</p>
                  </div>
              </body>
              </html>
            ''');
          }

          await request.response.close();
        } else {
          // Handle other paths
          request.response.statusCode = 404;
          request.response.write('Not Found');
          await request.response.close();
        }
      });

      return {'port': _currentPort, 'redirectUri': redirectUri};
    } catch (e) {
      print('Error starting local server: $e');
      return null;
    }
  }

  static Future<void> stopServer() async {
    if (_server != null) {
      await _server!.close();
      _server = null;
      _onCodeReceived = null;
      print('Local server stopped');
    }
  }

  static bool get isRunning => _server != null;
}
