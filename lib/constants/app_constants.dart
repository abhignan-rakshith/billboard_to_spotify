class AppConstants {
  // App Info
  static const String appTitle = 'Billboard to Spotify';

  // Spotify OAuth Configuration
  static const String spotifyClientId = 'cf9af4f27a004bdb89e5cf506df848ee';

  // Platform-specific redirect URIs
  static const String spotifyRedirectUriMobile = 'com.abhignan.billboardspotify://callback';
  static const String spotifyRedirectUriDesktop = 'http://127.0.0.1:8080/callback';

  static const String spotifyScopes = 'playlist-modify-public playlist-modify-private user-read-private user-read-email';

  // API URLs
  static const String spotifyTokenUrl = 'https://accounts.spotify.com/api/token';
  static const String spotifyProfileUrl = 'https://api.spotify.com/v1/me';
  static const String spotifyAuthUrl = 'https://accounts.spotify.com/authorize';

  // Secure Storage Keys
  static const String accessTokenKey = 'spotify_access_token';
  static const String refreshTokenKey = 'spotify_refresh_token';
  static const String userProfileKey = 'spotify_user_profile';
  static const String tokenExpiryKey = 'spotify_token_expiry';

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double largePadding = 32.0;
  static const double smallPadding = 8.0;
  static const double buttonHeight = 56.0;
  static const double smallButtonHeight = 48.0;
  static const double iconSize = 80.0;
  static const double avatarRadius = 40.0;

  // Colors
  static const int spotifyGreenValue = 0xFF1DB954;

  // PKCE Constants
  static const String pkceChars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
  static const int codeVerifierLength = 128;
  static const int stateLength = 16;

  // Token Settings
  static const int tokenBufferSeconds = 60; // 1 minute buffer before expiry

  // Platform helper
  static String get redirectUri {
    // You'll need to import dart:io and check Platform.isWindows/Platform.isLinux/Platform.isMacOS
    // For now, we'll handle this in the auth service
    return spotifyRedirectUriMobile;
  }
}