import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_constants.dart';

class SpotifyAuthService {
  static String? _codeVerifier;

  // Generate PKCE Code Verifier
  static String _generateRandomString(int length) {
    final random = Random.secure();
    return List.generate(
      length,
          (i) => AppConstants.pkceChars[random.nextInt(AppConstants.pkceChars.length)],
    ).join();
  }

  // Generate PKCE Code Challenge
  static String _generateCodeChallenge(String verifier) {
    final bytes = utf8.encode(verifier);
    final digest = sha256.convert(bytes);
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }

  // Build Spotify Authorization URL
  static String _buildSpotifyAuthUrl(String codeChallenge) {
    final params = {
      'response_type': 'code',
      'client_id': AppConstants.spotifyClientId,
      'scope': AppConstants.spotifyScopes,
      'code_challenge_method': 'S256',
      'code_challenge': codeChallenge,
      'redirect_uri': AppConstants.spotifyRedirectUri,
      'state': _generateRandomString(AppConstants.stateLength),
    };

    final query = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    return '${AppConstants.spotifyAuthUrl}?$query';
  }

  // Start Spotify Login Flow
  static Future<bool> startLogin() async {
    try {
      // Generate PKCE codes
      _codeVerifier = _generateRandomString(AppConstants.codeVerifierLength);
      final codeChallenge = _generateCodeChallenge(_codeVerifier!);

      // Build authorization URL
      final authUrl = _buildSpotifyAuthUrl(codeChallenge);

      print('Opening Spotify URL: $authUrl');

      // Launch Spotify login
      final launched = await launchUrl(
        Uri.parse(authUrl),
        mode: LaunchMode.externalApplication,
      );

      return launched;
    } catch (e) {
      print('Error starting Spotify login: $e');
      return false;
    }
  }

  // Exchange Authorization Code for Access Token
  static Future<Map<String, dynamic>?> exchangeCodeForToken(String code) async {
    if (_codeVerifier == null) {
      throw Exception('Code verifier not found. Start login flow first.');
    }

    try {
      print('Exchanging code for token...');
      print('Code: ${code.substring(0, 20)}...');
      print('Code verifier: ${_codeVerifier?.substring(0, 20)}...');

      final response = await http.post(
        Uri.parse(AppConstants.spotifyTokenUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'authorization_code',
          'code': code,
          'redirect_uri': AppConstants.spotifyRedirectUri,
          'client_id': AppConstants.spotifyClientId,
          'code_verifier': _codeVerifier!,
        },
      );

      print('Token response status: ${response.statusCode}');
      print('Token response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'access_token': data['access_token'],
          'refresh_token': data['refresh_token'],
          'expires_in': data['expires_in'] ?? 3600,
        };
      } else {
        final error = json.decode(response.body);
        throw Exception('Token exchange failed: ${error['error_description'] ?? error['error']}');
      }
    } catch (e) {
      print('Token exchange error: $e');
      rethrow;
    }
  }

  // Get User Profile
  static Future<Map<String, dynamic>> getUserProfile(String accessToken) async {
    try {
      print('Getting user profile with token: ${accessToken.substring(0, 20)}...');

      final response = await http.get(
        Uri.parse(AppConstants.spotifyProfileUrl),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      print('Profile response status: ${response.statusCode}');
      print('Profile response body: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get user profile: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Profile error: $e');
      rethrow;
    }
  }

  // Refresh Access Token (placeholder for future implementation)
  static Future<Map<String, dynamic>?> refreshToken(String refreshToken) async {
    try {
      final response = await http.post(
        Uri.parse(AppConstants.spotifyTokenUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'refresh_token',
          'refresh_token': refreshToken,
          'client_id': AppConstants.spotifyClientId,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'access_token': data['access_token'],
          'refresh_token': data['refresh_token'] ?? refreshToken, // Keep old if not provided
          'expires_in': data['expires_in'] ?? 3600,
        };
      } else {
        print('Refresh token failed: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Refresh token error: $e');
      return null;
    }
  }

  // Clear stored code verifier
  static void clearCodeVerifier() {
    _codeVerifier = null;
  }

  // Get current code verifier (for debugging)
  static String? get codeVerifier => _codeVerifier;
}