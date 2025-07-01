import 'dart:convert';
import 'package:http/http.dart' as http;
import 'secure_storage_service.dart';
import 'http_helper.dart';

class SpotifyPlaylistService {
  // Get user profile to get user ID
  static Future<String> getUserId() async {
    final profile = await SecureStorageService.getUserProfile();
    if (profile != null && profile['id'] != null) {
      return profile['id'];
    }
    throw Exception('User profile not found');
  }

  // Create a playlist
  static Future<String> createPlaylist({
    required String name,
    required String description,
  }) async {
    try {
      final accessToken = await SecureStorageService.getAccessToken();
      final userId = await getUserId();

      if (accessToken == null) {
        throw Exception('Access token not found');
      }

      final response = await HttpHelper.playlistWithRetry(
        () => http.post(
          Uri.parse('https://api.spotify.com/v1/users/$userId/playlists'),
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
          body: json.encode({
            'name': name,
            'description': description,
            'public': true,
          }),
        ),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['id']; // Return playlist ID
      } else {
        throw Exception(
          'Failed to create playlist: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error creating playlist: $e');
      rethrow;
    }
  }

  // Search for a single song
  static Future<String?> searchSong({
    required String songName,
    required String artistName,
  }) async {
    try {
      final accessToken = await SecureStorageService.getAccessToken();

      if (accessToken == null) {
        throw Exception('Access token not found');
      }

      // Create search query with both song and artist
      final query = Uri.encodeComponent(
        'track:"$songName" artist:"$artistName"',
      );

      final response = await HttpHelper.searchWithRetry(
        () => http.get(
          Uri.parse(
            'https://api.spotify.com/v1/search?q=$query&type=track&limit=1',
          ),
          headers: {'Authorization': 'Bearer $accessToken'},
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final tracks = data['tracks']['items'] as List;

        if (tracks.isNotEmpty) {
          return tracks[0]['uri']; // Return Spotify URI
        }
        return null; // Song not found
      } else {
        throw Exception('Search failed: ${response.statusCode}');
      }
    } catch (e) {
      print('Error searching for song "$songName" by "$artistName": $e');
      return null;
    }
  }

  // Check if playlist with same name already exists
  static Future<bool> playlistExists(String playlistName) async {
    try {
      final accessToken = await SecureStorageService.getAccessToken();
      final userId = await getUserId();

      if (accessToken == null) {
        throw Exception('Access token not found');
      }

      final response = await HttpHelper.requestWithRetry(
        () => http.get(
          Uri.parse(
            'https://api.spotify.com/v1/users/$userId/playlists?limit=50',
          ),
          headers: {'Authorization': 'Bearer $accessToken'},
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final playlists = data['items'] as List;

        // Check if any playlist has the same name
        return playlists.any(
          (playlist) =>
              playlist['name'].toString().toLowerCase() ==
              playlistName.toLowerCase(),
        );
      }
      return false;
    } catch (e) {
      print('Error checking playlist existence: $e');
      return false;
    }
  }

  // Search for multiple songs with optimized simultaneous requests
  static Future<Map<String, dynamic>> searchSongs({
    required List<String> songNames,
    required List<String> artistNames,
    Function(int completed, int total)? onProgress,
  }) async {
    List<String> foundUris = [];
    List<Map<String, dynamic>> notFoundSongs = [];
    int completed = 0;

    // Create all search futures simultaneously (like the original approach)
    // But with proper error handling for rate limits
    List<Future<Map<String, dynamic>>> searchFutures = [];

    for (int i = 0; i < songNames.length; i++) {
      searchFutures.add(
        _searchWithIndexAndRetry(
          songName: songNames[i],
          artistName: i < artistNames.length ? artistNames[i] : 'Unknown',
          index: i,
        ),
      );
    }

    // Process results as they complete to show progress
    for (final future in searchFutures) {
      try {
        final result = await future;

        if (result['uri'] != null) {
          foundUris.add(result['uri']);
        } else {
          notFoundSongs.add({
            'position': result['index'] + 1,
            'song': result['song'],
            'artist': result['artist'],
          });
        }
        completed++;
        onProgress?.call(completed, songNames.length);
      } catch (e) {
        print('Error processing search result: $e');
        completed++;
        onProgress?.call(completed, songNames.length);
      }
    }

    return {
      'foundUris': foundUris,
      'notFoundSongs': notFoundSongs,
      'totalFound': foundUris.length,
      'totalNotFound': notFoundSongs.length,
    };
  }

  // Enhanced search with retry mechanism for rate limits
  static Future<Map<String, dynamic>> _searchWithIndexAndRetry({
    required String songName,
    required String artistName,
    required int index,
    int maxRetries = 3,
  }) async {
    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        final uri = await searchSong(
          songName: songName,
          artistName: artistName,
        );

        return {
          'index': index,
          'song': songName,
          'artist': artistName,
          'uri': uri,
        };
      } catch (e) {
        // If it's a rate limit error and we have retries left, wait and retry
        if (e.toString().contains('429') && attempt < maxRetries - 1) {
          await Future.delayed(
            Duration(milliseconds: 1000 * (attempt + 1)),
          ); // Exponential backoff
          continue;
        }

        // For other errors or if we've exhausted retries, return null URI
        return {
          'index': index,
          'song': songName,
          'artist': artistName,
          'uri': null,
        };
      }
    }

    // Fallback (should not reach here)
    return {
      'index': index,
      'song': songName,
      'artist': artistName,
      'uri': null,
    };
  }

  // Add songs to playlist
  static Future<bool> addSongsToPlaylist({
    required String playlistId,
    required List<String> uris,
  }) async {
    try {
      final accessToken = await SecureStorageService.getAccessToken();

      if (accessToken == null) {
        throw Exception('Access token not found');
      }

      final response = await HttpHelper.playlistWithRetry(
        () => http.post(
          Uri.parse('https://api.spotify.com/v1/playlists/$playlistId/tracks'),
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
          body: json.encode({'uris': uris}),
        ),
      );

      return response.statusCode == 201;
    } catch (e) {
      print('Error adding songs to playlist: $e');
      return false;
    }
  }

  // Delete a playlist
  static Future<bool> deletePlaylist(String playlistId) async {
    try {
      final accessToken = await SecureStorageService.getAccessToken();

      if (accessToken == null) {
        throw Exception('Access token not found');
      }

      // Note: Spotify doesn't have a delete playlist endpoint
      // We can only unfollow it, which removes it from the user's library
      final response = await HttpHelper.requestWithRetry(
        () => http.delete(
          Uri.parse(
            'https://api.spotify.com/v1/playlists/$playlistId/followers',
          ),
          headers: {'Authorization': 'Bearer $accessToken'},
        ),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting playlist: $e');
      return false;
    }
  }
}
