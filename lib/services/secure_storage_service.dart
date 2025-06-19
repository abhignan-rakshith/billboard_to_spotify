import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

class SecureStorageService {
  // Secure Storage Instance
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // Token Management
  static Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
    required int expiresIn,
  }) async {
    try {
      // Calculate expiry time with buffer
      final expiryTime = DateTime.now().add(
        Duration(seconds: expiresIn - AppConstants.tokenBufferSeconds),
      );

      // Save access token and expiry
      await _storage.write(
        key: AppConstants.accessTokenKey,
        value: accessToken,
      );
      await _storage.write(
        key: AppConstants.tokenExpiryKey,
        value: expiryTime.millisecondsSinceEpoch.toString(),
      );

      // Save refresh token if provided
      if (refreshToken != null) {
        await _storage.write(
          key: AppConstants.refreshTokenKey,
          value: refreshToken,
        );
      }

      print('Tokens saved to secure storage');
    } catch (e) {
      print('Error saving tokens: $e');
      rethrow;
    }
  }

  static Future<String?> getAccessToken() async {
    try {
      return await _storage.read(key: AppConstants.accessTokenKey);
    } catch (e) {
      print('Error getting access token: $e');
      return null;
    }
  }

  static Future<String?> getRefreshToken() async {
    try {
      return await _storage.read(key: AppConstants.refreshTokenKey);
    } catch (e) {
      print('Error getting refresh token: $e');
      return null;
    }
  }

  static Future<DateTime?> getTokenExpiry() async {
    try {
      final expiryString = await _storage.read(key: AppConstants.tokenExpiryKey);
      if (expiryString != null) {
        return DateTime.fromMillisecondsSinceEpoch(int.parse(expiryString));
      }
      return null;
    } catch (e) {
      print('Error getting token expiry: $e');
      return null;
    }
  }

  static Future<bool> isTokenValid() async {
    try {
      final accessToken = await getAccessToken();
      final expiry = await getTokenExpiry();

      if (accessToken == null || expiry == null) {
        return false;
      }

      return DateTime.now().isBefore(expiry);
    } catch (e) {
      print('Error checking token validity: $e');
      return false;
    }
  }

  // Profile Management
  static Future<void> saveUserProfile(Map<String, dynamic> profile) async {
    try {
      final profileJson = json.encode(profile);
      await _storage.write(
        key: AppConstants.userProfileKey,
        value: profileJson,
      );
      print('Profile saved to secure storage');
    } catch (e) {
      print('Error saving profile: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final profileJson = await _storage.read(key: AppConstants.userProfileKey);
      if (profileJson != null) {
        return json.decode(profileJson);
      }
      return null;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  // Session Management
  static Future<bool> hasValidSession() async {
    try {
      final hasToken = await getAccessToken() != null;
      final isValid = await isTokenValid();
      return hasToken && isValid;
    } catch (e) {
      print('Error checking session validity: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getCompleteSession() async {
    try {
      final accessToken = await getAccessToken();
      final refreshToken = await getRefreshToken();
      final profile = await getUserProfile();
      final expiry = await getTokenExpiry();

      if (accessToken != null && await isTokenValid()) {
        return {
          'access_token': accessToken,
          'refresh_token': refreshToken,
          'user_profile': profile,
          'expiry': expiry,
        };
      }
      return null;
    } catch (e) {
      print('Error getting complete session: $e');
      return null;
    }
  }

  // Clear Data
  static Future<void> clearAllData() async {
    try {
      await _storage.delete(key: AppConstants.accessTokenKey);
      await _storage.delete(key: AppConstants.refreshTokenKey);
      await _storage.delete(key: AppConstants.userProfileKey);
      await _storage.delete(key: AppConstants.tokenExpiryKey);
      print('All secure storage data cleared');
    } catch (e) {
      print('Error clearing storage data: $e');
      rethrow;
    }
  }

  static Future<void> clearTokens() async {
    try {
      await _storage.delete(key: AppConstants.accessTokenKey);
      await _storage.delete(key: AppConstants.refreshTokenKey);
      await _storage.delete(key: AppConstants.tokenExpiryKey);
      print('Tokens cleared from secure storage');
    } catch (e) {
      print('Error clearing tokens: $e');
      rethrow;
    }
  }

  // Debug Methods
  static Future<void> debugPrintStoredData() async {
    try {
      final token = await getAccessToken();
      final profile = await getUserProfile();
      final expiry = await getTokenExpiry();
      final refreshToken = await getRefreshToken();

      print('=== STORED DATA DEBUG ===');
      print('Access Token: ${token != null ? 'EXISTS (${token.substring(0, 10)}...)' : 'NULL'}');
      print('Refresh Token: ${refreshToken != null ? 'EXISTS' : 'NULL'}');
      print('Profile: ${profile != null ? 'EXISTS' : 'NULL'}');
      print('Expiry: ${expiry != null ? 'EXISTS ($expiry)' : 'NULL'}');
      print('Token Valid: ${await isTokenValid()}');
      print('========================');
    } catch (e) {
      print('Error debugging stored data: $e');
    }
  }

  // Storage Health Check
  static Future<bool> isStorageHealthy() async {
    try {
      // Test write and read
      const testKey = 'health_check_test';
      const testValue = 'test_data';

      await _storage.write(key: testKey, value: testValue);
      final readValue = await _storage.read(key: testKey);
      await _storage.delete(key: testKey);

      return readValue == testValue;
    } catch (e) {
      print('Storage health check failed: $e');
      return false;
    }
  }
}