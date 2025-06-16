// lib/main.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Billboard to Spotify',
      theme: ThemeData(primarySwatch: Colors.green, useMaterial3: true),
      home: const LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Your Spotify app details
  static const String CLIENT_ID = 'cf9af4f27a004bdb89e5cf506df848ee';
  static const String REDIRECT_URI = 'com.abhignan.billboardspotify://callback';
  static const String SCOPES =
      'playlist-modify-public playlist-modify-private user-read-private user-read-email';

  String _status = '';
  bool _isLoading = false;
  String? _codeVerifier;

  Future<void> _loginToSpotify() async {
    setState(() {
      _isLoading = true;
      _status = 'Opening Spotify login...';
    });

    try {
      // Generate PKCE codes
      _codeVerifier = _generateRandomString(128);
      final codeChallenge = _generateCodeChallenge(_codeVerifier!);

      // Build Spotify authorization URL
      final authUrl = _buildSpotifyAuthUrl(codeChallenge);

      print('Opening Spotify URL: $authUrl');

      // Launch Spotify login
      final launched = await launchUrl(
        Uri.parse(authUrl),
        mode: LaunchMode.externalApplication,
      );

      if (launched) {
        setState(() {
          _status = 'Please complete login in browser and return to app';
        });

        // Note: In a real app, you'd handle the callback through deep links
        // For now, we'll just show success when the browser opens
        await Future.delayed(const Duration(seconds: 2));
        setState(() {
          _status =
              '✅ Spotify login URL opened successfully!\n\nNext: Handle the callback when user returns';
        });
      } else {
        setState(() {
          _status = '❌ Failed to open Spotify login';
        });
      }
    } catch (e) {
      setState(() {
        _status = '❌ Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _buildSpotifyAuthUrl(String codeChallenge) {
    final params = {
      'response_type': 'code',
      'client_id': CLIENT_ID,
      'scope': SCOPES,
      'code_challenge_method': 'S256',
      'code_challenge': codeChallenge,
      'redirect_uri': REDIRECT_URI,
      'state': _generateRandomString(16),
    };

    final query = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    return 'https://accounts.spotify.com/authorize?$query';
  }

  String _generateRandomString(int length) {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final random = Random.secure();
    return List.generate(
      length,
      (i) => chars[random.nextInt(chars.length)],
    ).join();
  }

  String _generateCodeChallenge(String verifier) {
    final bytes = utf8.encode(verifier);
    final digest = sha256.convert(bytes);
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Billboard to Spotify'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Icon
              const Icon(Icons.music_note, size: 80, color: Colors.green),
              const SizedBox(height: 40),

              // Login Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _loginToSpotify,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.login, color: Colors.white),
                  label: Text(
                    _isLoading ? 'Opening Spotify...' : 'Login to Spotify',
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1DB954), // Spotify Green
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Status Message
              if (_status.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _status.startsWith('✅')
                        ? Colors.green[50]
                        : _status.startsWith('❌')
                        ? Colors.red[50]
                        : Colors.blue[50],
                    border: Border.all(
                      color: _status.startsWith('✅')
                          ? Colors.green
                          : _status.startsWith('❌')
                          ? Colors.red
                          : Colors.blue,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _status,
                    style: TextStyle(
                      fontSize: 14,
                      color: _status.startsWith('✅')
                          ? Colors.green[800]
                          : _status.startsWith('❌')
                          ? Colors.red[800]
                          : Colors.blue[800],
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

              const SizedBox(height: 20),

              // Debug Info
              if (_codeVerifier != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Debug Info:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Client ID: $CLIENT_ID',
                        style: const TextStyle(
                          fontSize: 10,
                          fontFamily: 'monospace',
                        ),
                      ),
                      Text(
                        'Redirect: $REDIRECT_URI',
                        style: const TextStyle(
                          fontSize: 10,
                          fontFamily: 'monospace',
                        ),
                      ),
                      Text(
                        'Code Verifier: ${_codeVerifier!.substring(0, 20)}...',
                        style: const TextStyle(
                          fontSize: 10,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
