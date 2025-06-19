import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../config/theme_config.dart';
import '../services/spotify_playlist_service.dart';

class PlaylistCreationScreen extends StatefulWidget {
  final String selectedDate;
  final List<String> songs;
  final List<String> artists;

  const PlaylistCreationScreen({
    super.key,
    required this.selectedDate,
    required this.songs,
    required this.artists,
  });

  @override
  State<PlaylistCreationScreen> createState() => _PlaylistCreationScreenState();
}

class _PlaylistCreationScreenState extends State<PlaylistCreationScreen> {
  final TextEditingController _playlistNameController = TextEditingController();

  // State variables
  bool _isSearching = false;
  bool _searchCompleted = false;
  bool _isCreatingPlaylist = false;
  List<Map<String, dynamic>> _notFoundSongs = [];
  List<String> _foundUris = [];
  int _totalSongsFound = 0;
  int _searchProgress = 0;
  int _totalSongs = 0;

  // Cancellation token for current search
  String? _currentSearchId;

  @override
  void initState() {
    super.initState();
    // Set default playlist name
    _playlistNameController.text = 'BTS Hot 100: ${widget.selectedDate}';
  }

  @override
  void dispose() {
    _playlistNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Playlist'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      resizeToAvoidBottomInset: true, // Handle keyboard properly
      body: SafeArea(
        child: SingleChildScrollView(
          padding: ThemeConfig.responsivePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Step 1: Playlist Name Setup
              const Text(
                'Playlist Name',
                style: ThemeConfig.titleStyle,
              ),
              const SizedBox(height: AppConstants.smallPadding),
              Text(
                'We\'ll create a Spotify playlist with the following name:',
                style: ThemeConfig.bodyStyle,
              ),
              const SizedBox(height: AppConstants.defaultPadding),

              // Playlist Name Text Field
              TextField(
                controller: _playlistNameController,
                enabled: !_isSearching && !_isCreatingPlaylist,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  hintText: 'Enter playlist name',
                  prefixIcon: const Icon(Icons.playlist_play),
                ),
                style: ThemeConfig.bodyStyle,
              ),
              const SizedBox(height: AppConstants.largePadding),

              // Step 2: Search Button / Searching Status
              if (!_isSearching && !_searchCompleted)
                SizedBox(
                  width: double.infinity,
                  height: AppConstants.buttonHeight,
                  child: ElevatedButton.icon(
                    onPressed: _searchForSongs,
                    icon: const Icon(Icons.search),
                    label: const Text('Search for Songs'),
                    style: ThemeConfig.primaryButtonStyle,
                  ),
                ),

              // Step 3: Searching Progress
              if (_isSearching) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppConstants.defaultPadding),
                  decoration: BoxDecoration(
                    color: ThemeConfig.spotifyGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: ThemeConfig.spotifyGreen.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Searching for songs on Spotify...',
                        style: ThemeConfig.bodyStyle,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppConstants.defaultPadding),

                      // Progress Bar
                      LinearProgressIndicator(
                        value: _totalSongs > 0 ? _searchProgress / _totalSongs : 0,
                        backgroundColor: Colors.grey[300],
                        valueColor: const AlwaysStoppedAnimation<Color>(ThemeConfig.spotifyGreen),
                      ),
                      const SizedBox(height: AppConstants.smallPadding),

                      // Progress Text
                      Text(
                        '$_searchProgress / $_totalSongs songs processed',
                        style: ThemeConfig.subtitleStyle,
                      ),
                      const SizedBox(height: AppConstants.defaultPadding),

                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _abortSearch,
                          icon: const Icon(Icons.cancel, color: Colors.red),
                          label: const Text('Abort Search', style: TextStyle(color: Colors.red)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Step 4: Search Results
              if (_searchCompleted) ...[
                const SizedBox(height: AppConstants.defaultPadding),
                _buildSearchResults(),
              ],

              // Add extra padding at bottom to ensure button is above keyboard
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom + AppConstants.largePadding),
            ],
          ),
        ),
      ),
    );
  }

  void _searchForSongs() async {
    // Generate unique search ID for this search session
    final searchId = DateTime.now().millisecondsSinceEpoch.toString();
    _currentSearchId = searchId;

    setState(() {
      _isSearching = true;
      _searchCompleted = false;
      _searchProgress = 0;
      _totalSongs = widget.songs.length;
      _notFoundSongs = [];
      _foundUris = [];
      _totalSongsFound = 0;
    });

    try {
      // Search for all songs with progress tracking
      final searchResults = await SpotifyPlaylistService.searchSongs(
        songNames: widget.songs,
        artistNames: widget.artists,
        onProgress: (completed, total) {
          // Only update progress if this search is still active
          if (mounted && _currentSearchId == searchId) {
            setState(() {
              _searchProgress = completed;
            });
          }
        },
      );

      // Final check if cancelled after search
      if (_currentSearchId != searchId) return;

      // Only update state if this search is still active
      if (mounted && _currentSearchId == searchId) {
        final foundUris = List<String>.from(searchResults['foundUris']);
        final notFoundSongs = List<Map<String, dynamic>>.from(searchResults['notFoundSongs']);
        final totalFound = searchResults['totalFound'];

        setState(() {
          _foundUris = foundUris;
          _notFoundSongs = notFoundSongs;
          _totalSongsFound = totalFound;
          _isSearching = false;
          _searchCompleted = true;
        });

        print('Found $totalFound out of ${widget.songs.length} songs');
      }
    } catch (e) {
      // Only show error if this search is still active
      if (mounted && _currentSearchId == searchId) {
        setState(() {
          _isSearching = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: ThemeConfig.errorRed,
          ),
        );
      }
    }
  }

  void _abortSearch() {
    // Cancel current search by clearing the search ID
    _currentSearchId = null;

    // Immediately reset UI state
    setState(() {
      _isSearching = false;
      _searchCompleted = false;
      _searchProgress = 0;
      _totalSongs = 0;
      _notFoundSongs = [];
      _foundUris = [];
      _totalSongsFound = 0;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Search aborted'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Widget _buildSearchResults() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.withOpacity(0.05),
            Colors.green.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ThemeConfig.spotifyGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.search_rounded,
                  color: ThemeConfig.spotifyGreen,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppConstants.defaultPadding),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Search Results',
                      style: ThemeConfig.titleStyle,
                    ),
                    Text(
                      'Found $_totalSongsFound out of ${widget.songs.length} songs on Spotify',
                      style: ThemeConfig.bodyStyle.copyWith(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppConstants.defaultPadding),

          // Statistics Cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Found',
                  _totalSongsFound.toString(),
                  Colors.green,
                  Icons.check_circle_rounded,
                ),
              ),
              const SizedBox(width: AppConstants.smallPadding),
              Expanded(
                child: _buildStatCard(
                  'Missing',
                  _notFoundSongs.length.toString(),
                  Colors.orange,
                  Icons.info_rounded,
                ),
              ),
            ],
          ),

          if (_notFoundSongs.isNotEmpty) ...[
            const SizedBox(height: AppConstants.defaultPadding),

            // Expandable missing songs section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: Colors.orange[700],
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Missing Songs (${_notFoundSongs.length})',
                        style: ThemeConfig.bodyStyle.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.orange[700],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Show first 3 missing songs
                  ..._notFoundSongs.take(3).map((songData) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 1),
                    child: Text(
                      '• #${songData['position']}: ${songData['song']} by ${songData['artist']}',
                      style: ThemeConfig.bodyStyle.copyWith(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  )),

                  if (_notFoundSongs.length > 3)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '... and ${_notFoundSongs.length - 3} more',
                        style: ThemeConfig.subtitleStyle.copyWith(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],

          const SizedBox(height: AppConstants.largePadding),

          // Create Playlist Button with improved design
          Container(
            width: double.infinity,
            height: AppConstants.buttonHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  ThemeConfig.spotifyGreen,
                  ThemeConfig.spotifyGreen.withOpacity(0.8),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: ThemeConfig.spotifyGreen.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: _isCreatingPlaylist ? null : _createPlaylistOnSpotify,
              icon: _isCreatingPlaylist
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : const Icon(
                Icons.playlist_add_rounded,
                color: Colors.white,
              ),
              label: Text(
                _isCreatingPlaylist ? 'Creating Playlist...' : 'Create Playlist on Spotify',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
            ),
          ),

          const SizedBox(height: AppConstants.smallPadding),

          // Description text
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  'Playlist: "${_playlistNameController.text}"',
                  style: ThemeConfig.bodyStyle.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Will add $_totalSongsFound songs • ${widget.selectedDate}',
                  style: ThemeConfig.subtitleStyle.copyWith(
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: ThemeConfig.titleStyle.copyWith(
              color: color,
              fontSize: 18,
            ),
          ),
          Text(
            label,
            style: ThemeConfig.subtitleStyle.copyWith(
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  void _createPlaylistOnSpotify() async {
    if (_foundUris.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ No songs found to add to playlist'),
          backgroundColor: ThemeConfig.errorRed,
        ),
      );
      return;
    }

    setState(() {
      _isCreatingPlaylist = true;
    });

    try {
      // Step 1: Check if playlist already exists
      final playlistExists = await SpotifyPlaylistService.playlistExists(_playlistNameController.text);

      if (playlistExists) {
        if (mounted) {
          setState(() {
            _isCreatingPlaylist = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ A playlist named "${_playlistNameController.text}" already exists'),
              backgroundColor: ThemeConfig.errorRed,
            ),
          );
        }
        return;
      }

      // Step 2: Create the playlist
      final playlistId = await SpotifyPlaylistService.createPlaylist(
        name: _playlistNameController.text,
        description: 'Billboard Hot 100 chart from ${widget.selectedDate}',
      );

      print('Created playlist with ID: $playlistId');

      // Step 3: Add songs to playlist
      final success = await SpotifyPlaylistService.addSongsToPlaylist(
        playlistId: playlistId,
        uris: _foundUris,
      );

      if (mounted) {
        setState(() {
          _isCreatingPlaylist = false;
        });

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🎉 Successfully created playlist "${_playlistNameController.text}" with $_totalSongsFound songs!'),
              backgroundColor: ThemeConfig.successGreen,
              duration: const Duration(seconds: 4),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Playlist created but failed to add songs'),
              backgroundColor: ThemeConfig.errorRed,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCreatingPlaylist = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error creating playlist: $e'),
            backgroundColor: ThemeConfig.errorRed,
          ),
        );
      }
    }
  }
}