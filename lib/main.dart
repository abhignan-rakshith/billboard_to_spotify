// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

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
  String? _accessToken;
  Map<String, dynamic>? _userProfile;

  @override
  void initState() {
    super.initState();
    _setupDeepLinkListener();
  }

  void _setupDeepLinkListener() {
    // Listen for incoming deep links
    const platform = MethodChannel('flutter/deeplink');
    platform.setMethodCallHandler(_handleDeepLink);
  }

  Future<dynamic> _handleDeepLink(MethodCall call) async {
    if (call.method == 'incoming_link') {
      final String? link = call.arguments;
      if (link != null && link.startsWith(REDIRECT_URI)) {
        await _processSpotifyCallback(link);
      }
    }
  }

  Future<void> _processSpotifyCallback(String callbackUrl) async {
    try {
      final uri = Uri.parse(callbackUrl);
      final code = uri.queryParameters['code'];
      final error = uri.queryParameters['error'];

      if (error != null) {
        setState(() {
          _status =
              '❌ Authentication Failed!\n\nUser denied permission or cancelled login.\nPlease try again to use Spotify features.';
          _isLoading = false;
        });
        return;
      }

      if (code != null && _codeVerifier != null) {
        setState(() {
          _status = 'Exchanging code for access token...';
        });

        await _exchangeCodeForToken(code);
      } else {
        setState(() {
          _status = '❌ Error: No authorization code received';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _status = '❌ Error processing callback: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _exchangeCodeForToken(String code) async {
    try {
      print('Exchanging code for token...');
      print('Code: ${code.substring(0, 20)}...');
      print('Code verifier: ${_codeVerifier?.substring(0, 20)}...');

      final response = await http.post(
        Uri.parse('https://accounts.spotify.com/api/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'authorization_code',
          'code': code,
          'redirect_uri': REDIRECT_URI,
          'client_id': CLIENT_ID,
          'code_verifier': _codeVerifier!,
        },
      );

      print('Token response status: ${response.statusCode}');
      print('Token response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _accessToken = data['access_token'];

        print('Access token received: ${_accessToken?.substring(0, 20)}...');

        setState(() {
          _status = 'Getting user profile...';
        });

        await _getUserProfile();
      } else {
        final error = json.decode(response.body);
        setState(() {
          _status =
              '❌ Token exchange failed: ${error['error_description'] ?? error['error']}\n\nFull error: $error';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Token exchange error: $e');
      setState(() {
        _status = '❌ Error exchanging token: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _getUserProfile() async {
    try {
      print(
        'Getting user profile with token: ${_accessToken?.substring(0, 20)}...',
      );

      final response = await http.get(
        Uri.parse('https://api.spotify.com/v1/me'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
      );

      print('Profile response status: ${response.statusCode}');
      print('Profile response body: ${response.body}');

      if (response.statusCode == 200) {
        _userProfile = json.decode(response.body);
        setState(() {
          _status =
              '✅ Login Successful!\n\nWelcome, ${_userProfile!['display_name'] ?? 'Spotify User'}!';
          _isLoading = false;
        });
      } else {
        final errorBody = response.body;
        setState(() {
          _status =
              '❌ Failed to get user profile\n\nStatus: ${response.statusCode}\nError: $errorBody';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Profile error: $e');
      setState(() {
        _status = '❌ Error getting profile: $e';
        _isLoading = false;
      });
    }
  }

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
          _status =
              'Please complete login in browser...\n\nYou will be redirected back to the app automatically.';
        });
      } else {
        setState(() {
          _status = '❌ Failed to open Spotify login';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _status = '❌ Error: $e';
      });
    } finally {
      // Don't set _isLoading = false here, let the callback handle it
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

              // Login/Success Buttons
              if (_accessToken == null)
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
                )
              else ...[
                // Success buttons when logged in
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Navigate to Billboard conversion
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('🎵 Billboard conversion coming soon!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    icon: const Icon(Icons.playlist_add, color: Colors.white),
                    label: const Text(
                      'Create Billboard Playlist',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _accessToken = null;
                        _userProfile = null;
                        _codeVerifier = null;
                        _isLoading = false;
                        _status = 'Logged out successfully';
                      });
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ),
              ],

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

              // User Profile Card (if logged in)
              if (_userProfile != null) ...[
                const SizedBox(height: 20),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Profile Image
                        if (_userProfile!['images'] != null &&
                            _userProfile!['images'].isNotEmpty)
                          CircleAvatar(
                            radius: 40,
                            backgroundImage: NetworkImage(
                              _userProfile!['images'][0]['url'],
                            ),
                          )
                        else
                          const CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.green,
                            child: Icon(
                              Icons.person,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                        const SizedBox(height: 16),

                        // User Info
                        Text(
                          _userProfile!['display_name'] ?? 'Spotify User',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (_userProfile!['email'] != null)
                          Text(
                            _userProfile!['email'],
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${_userProfile!['followers']?['total'] ?? 0} followers',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],

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
