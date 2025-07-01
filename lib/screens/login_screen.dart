import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_constants.dart';
import '../config/theme_config.dart';
import '../config/app_routes.dart';
import '../services/spotify_auth_service.dart';
import '../services/secure_storage_service.dart';
import '../utils/error_handler.dart';
import '../utils/connectivity_helper.dart';
import 'billboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String _status = '';
  bool _isLoading = false;
  String? _accessToken;
  Map<String, dynamic>? _userProfile;

  @override
  void initState() {
    super.initState();

    // Only setup deep link listener for mobile platforms
    if (Platform.isAndroid || Platform.isIOS) {
      _setupDeepLinkListener();
    }

    // Check for existing login on app startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkExistingLogin();
    });
  }

  void _setupDeepLinkListener() {
    // Listen for incoming deep links (mobile only)
    const platform = MethodChannel('flutter/deeplink');
    platform.setMethodCallHandler(_handleDeepLink);
  }

  Future<dynamic> _handleDeepLink(MethodCall call) async {
    if (call.method == 'incoming_link') {
      final String? link = call.arguments;
      if (link != null &&
          link.startsWith(AppConstants.spotifyRedirectUriMobile)) {
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

      if (code != null) {
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
        _status = '❌ ${ErrorHandler.getReadableError(e)}';
        _isLoading = false;
      });
    }
  }

  Future<void> _exchangeCodeForToken(String code) async {
    try {
      final tokenData = await SpotifyAuthService.exchangeCodeForToken(code);

      if (tokenData != null) {
        _accessToken = tokenData['access_token'];

        // Save tokens to secure storage
        await SecureStorageService.saveTokens(
          accessToken: tokenData['access_token'],
          refreshToken: tokenData['refresh_token'],
          expiresIn: tokenData['expires_in'],
        );

        setState(() {
          _status = 'Getting user profile...';
        });

        await _getUserProfile();
      }
    } catch (e) {
      setState(() {
        _status = '❌ ${ErrorHandler.getReadableError(e)}';
        _isLoading = false;
      });
    }
  }

  Future<void> _getUserProfile() async {
    try {
      final profile = await SpotifyAuthService.getUserProfile(_accessToken!);
      _userProfile = profile;

      // Save profile to secure storage
      await SecureStorageService.saveUserProfile(profile);

      setState(() {
        _status =
            '✅ Login Successful!\n\nWelcome, ${profile['display_name'] ?? 'Spotify User'}!';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _status = '❌ Error getting profile: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _checkExistingLogin() async {
    setState(() {
      _isLoading = true;
      _status = 'Checking saved login...';
    });

    try {
      final sessionData = await SecureStorageService.getCompleteSession();

      if (sessionData != null) {
        // Valid session found
        _accessToken = sessionData['access_token'];
        _userProfile = sessionData['user_profile'];

        if (_userProfile != null) {
          setState(() {
            _status =
                '✅ Welcome back, ${_userProfile!['display_name'] ?? 'Spotify User'}!';
            _isLoading = false;
          });
        } else {
          // Get fresh profile data
          await _getUserProfile();
        }
      } else {
        // Try to refresh token if available
        await _tryRefreshToken();
      }
    } catch (e) {
      print('Error checking existing login: $e');
      setState(() {
        _status = '';
        _isLoading = false;
      });
    }
  }

  Future<void> _tryRefreshToken() async {
    final refreshToken = await SecureStorageService.getRefreshToken();

    if (refreshToken != null) {
      setState(() {
        _status = 'Refreshing login...';
      });

      try {
        final tokenData = await SpotifyAuthService.refreshToken(refreshToken);

        if (tokenData != null) {
          _accessToken = tokenData['access_token'];

          // Save new tokens
          await SecureStorageService.saveTokens(
            accessToken: tokenData['access_token'],
            refreshToken: tokenData['refresh_token'],
            expiresIn: tokenData['expires_in'],
          );

          // Get user profile
          await _getUserProfile();
          return;
        }
      } catch (e) {
        print('Token refresh failed: $e');
      }
    }

    // Clear expired data and show login
    await SecureStorageService.clearAllData();
    setState(() {
      _status = '';
      _isLoading = false;
    });
  }

  Future<void> _loginToSpotify() async {
    if (!await ConnectivityHelper.hasConnection()) {
      setState(() {
        _status = '📶 ${ConnectivityHelper.getOfflineMessage()}';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _status = 'Opening Spotify login...';
    });

    try {
      // Pass callback for desktop platforms
      final launched = await SpotifyAuthService.startLogin(
        onCodeReceived: (code) {
          // This will be called when the local server receives the code
          _exchangeCodeForToken(code);
        },
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
        _status = '❌ ${ErrorHandler.getReadableError(e)}';
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    await SecureStorageService.clearAllData();
    await SpotifyAuthService.clearCodeVerifier(); // Now this is async

    setState(() {
      _accessToken = null;
      _userProfile = null;
      _isLoading = false;
      _status = 'Logged out successfully';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appTitle),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: ThemeConfig.responsivePadding(context),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Icon
              _buildAppIcon(),
              const SizedBox(height: 40),

              // Login/Success Buttons
              _buildActionButtons(),

              const SizedBox(height: 40),

              // Status Message
              if (_status.isNotEmpty) _buildStatusContainer(),

              // User Profile Card
              if (_userProfile != null) _buildProfileCard(),

              // Debug Info
              if (SpotifyAuthService.codeVerifier != null) _buildDebugInfo(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppIcon() {
    return const Icon(
      Icons.music_note,
      size: AppConstants.iconSize,
      color: ThemeConfig.spotifyGreen,
    );
  }

  Widget _buildActionButtons() {
    if (_accessToken == null) {
      return _buildLoginButton();
    } else {
      return _buildLoggedInButtons();
    }
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: AppConstants.buttonHeight,
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
            : const Icon(Icons.login),
        label: Text(_isLoading ? 'Connecting...' : 'Login to Spotify'),
        style: ThemeConfig.primaryButtonStyle,
      ),
    );
  }

  Widget _buildLoggedInButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: AppConstants.buttonHeight,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.billboard);
            },
            icon: const Icon(Icons.playlist_add),
            label: const Text('Create Billboard Playlist'),
            style: ThemeConfig.secondaryButtonStyle,
          ),
        ),
        const SizedBox(height: AppConstants.defaultPadding),
        SizedBox(
          width: double.infinity,
          height: AppConstants.smallButtonHeight,
          child: OutlinedButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
            style: ThemeConfig.outlinedButtonStyle,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusContainer() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: ThemeConfig.statusContainerDecoration(_status),
      child: Text(
        _status,
        style: ThemeConfig.bodyStyle.copyWith(
          color: ThemeConfig.getStatusTextColor(_status),
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildProfileCard() {
    return Column(
      children: [
        const SizedBox(height: 20),
        ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Profile Image
                  if (_userProfile!['images'] != null &&
                      _userProfile!['images'].isNotEmpty)
                    CircleAvatar(
                      radius: AppConstants.avatarRadius,
                      backgroundImage: NetworkImage(
                        _userProfile!['images'][0]['url'],
                      ),
                    )
                  else
                    const CircleAvatar(
                      radius: AppConstants.avatarRadius,
                      backgroundColor: ThemeConfig.spotifyGreen,
                      child: Icon(Icons.person, size: 40, color: Colors.white),
                    ),
                  const SizedBox(height: AppConstants.defaultPadding),

                  // User Info
                  Flexible(
                    child: Text(
                      _userProfile!['display_name'] ?? 'Spotify User',
                      style: ThemeConfig.titleStyle,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (_userProfile!['email'] != null)
                    Flexible(
                      child: Text(
                        _userProfile!['email'],
                        style: ThemeConfig.subtitleStyle,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  const SizedBox(height: AppConstants.smallPadding),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          '${_userProfile!['followers']?['total'] ?? 0} followers',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDebugInfo() {
    return Column(
      children: [
        const SizedBox(height: 20),
        ExpansionTile(
          title: const Text('Debug Info', style: ThemeConfig.debugLabelStyle),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: ThemeConfig.debugContainerDecoration,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _debugInfoRow('Client ID', AppConstants.spotifyClientId),
                  _debugInfoRow(
                    'Redirect (Mobile)',
                    AppConstants.spotifyRedirectUriMobile,
                  ),
                  _debugInfoRow(
                    'Redirect (Desktop)',
                    AppConstants.spotifyRedirectUriDesktop,
                  ),
                  _debugInfoRow(
                    'Current Platform',
                    Platform.isAndroid
                        ? 'Android'
                        : Platform.isIOS
                        ? 'iOS'
                        : Platform.isWindows
                        ? 'Windows'
                        : Platform.isMacOS
                        ? 'macOS'
                        : 'Other',
                  ),
                  if (SpotifyAuthService.codeVerifier != null)
                    _debugInfoRow(
                      'Code Verifier',
                      '${SpotifyAuthService.codeVerifier!.substring(0, 20)}...',
                    ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _debugInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text('$label:', style: ThemeConfig.debugLabelStyle),
          ),
          Expanded(
            child: Text(
              value,
              style: ThemeConfig.debugStyle,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
}
