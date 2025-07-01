import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../config/theme_config.dart';
import '../services/spotify_playlist_service.dart';

class ManualSongSearchScreen extends StatefulWidget {
  final List<Map<String, dynamic>> missingSongs;
  final int totalSongsCount;

  const ManualSongSearchScreen({
    super.key,
    required this.missingSongs,
    required this.totalSongsCount,
  });

  @override
  State<ManualSongSearchScreen> createState() => _ManualSongSearchScreenState();
}

class _ManualSongSearchScreenState extends State<ManualSongSearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  // State variables
  int _currentSongIndex = 0;
  bool _isSearching = false;
  List<Map<String, dynamic>> _searchResults = [];
  List<String> _manuallyFoundUris = [];
  List<int> _foundPositions = [];

  // Current song data
  Map<String, dynamic> get _currentSong =>
      widget.missingSongs[_currentSongIndex];
  bool get _isLastSong => _currentSongIndex >= widget.missingSongs.length - 1;

  @override
  void initState() {
    super.initState();
    _initializeSearch();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _initializeSearch() {
    // Pre-fill search with current song and artist
    _searchController.text =
        '${_currentSong['song']} ${_currentSong['artist']}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Missing Songs'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _showExitConfirmation,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: ThemeConfig.responsivePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress indicator
              _buildProgressHeader(),
              const SizedBox(height: AppConstants.defaultPadding),

              // Current song info
              _buildCurrentSongCard(),
              const SizedBox(height: AppConstants.defaultPadding),

              // Search section
              _buildSearchSection(),
              const SizedBox(height: AppConstants.defaultPadding),

              // Search results
              Expanded(child: _buildSearchResults()),

              // Bottom actions
              _buildBottomActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressHeader() {
    final progress = (_currentSongIndex + 1) / widget.missingSongs.length;

    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: ThemeConfig.spotifyGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ThemeConfig.spotifyGreen.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Song ${_currentSongIndex + 1} of ${widget.missingSongs.length}',
                style: ThemeConfig.titleStyle.copyWith(fontSize: 18),
              ),
              Text(
                '${_manuallyFoundUris.length} found',
                style: ThemeConfig.bodyStyle.copyWith(
                  color: ThemeConfig.spotifyGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.smallPadding),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[300],
            valueColor: const AlwaysStoppedAnimation<Color>(
              ThemeConfig.spotifyGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentSongCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    '#${_currentSong['position']}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppConstants.defaultPadding),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentSong['song'],
                      style: ThemeConfig.bodyStyle.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'by ${_currentSong['artist']}',
                      style: ThemeConfig.subtitleStyle.copyWith(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Search for this song on Spotify:',
          style: ThemeConfig.titleStyle,
        ),
        const SizedBox(height: AppConstants.smallPadding),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Enter song or artist name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.search),
                ),
                onSubmitted: (_) => _searchSpotify(),
              ),
            ),
            const SizedBox(width: AppConstants.smallPadding),
            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isSearching ? null : _searchSpotify,
                icon: _isSearching
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.search, size: 20),
                label: const Text('Search'),
                style: ThemeConfig.primaryButtonStyle,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: AppConstants.defaultPadding),
            Text('Searching Spotify...'),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: AppConstants.defaultPadding),
            Text(
              'Search for the song above to see results',
              style: ThemeConfig.bodyStyle.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Top ${_searchResults.length} Results:',
          style: ThemeConfig.titleStyle.copyWith(fontSize: 16),
        ),
        const SizedBox(height: AppConstants.smallPadding),
        Expanded(
          child: ListView.builder(
            itemCount: _searchResults.length,
            itemBuilder: (context, index) {
              final track = _searchResults[index];
              return _buildSearchResultItem(track, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResultItem(Map<String, dynamic> track, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.smallPadding),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey[200],
          ),
          child: track['album']['images'].isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    track['album']['images'][0]['url'],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Icon(Icons.music_note, color: Colors.grey[400]),
                  ),
                )
              : Icon(Icons.music_note, color: Colors.grey[400]),
        ),
        title: Text(
          track['name'],
          style: ThemeConfig.bodyStyle.copyWith(fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              track['artists'].map((artist) => artist['name']).join(', '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              track['album']['name'],
              style: ThemeConfig.subtitleStyle.copyWith(fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: () => _selectSong(track),
          style: ElevatedButton.styleFrom(
            backgroundColor: ThemeConfig.spotifyGreen,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          child: const Text('Select'),
        ),
        onTap: () => _selectSong(track),
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppConstants.defaultPadding,
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _skipSong,
              icon: const Icon(Icons.skip_next),
              label: const Text('Skip This Song'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey[600],
                side: BorderSide(color: Colors.grey[400]!),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: AppConstants.defaultPadding),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _manuallyFoundUris.isNotEmpty
                  ? _finishManualSearch
                  : null,
              icon: const Icon(Icons.check),
              label: Text(_isLastSong ? 'Finish' : 'Finish Early'),
              style: ThemeConfig.primaryButtonStyle.copyWith(
                padding: const WidgetStatePropertyAll(
                  EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _searchSpotify() async {
    if (_searchController.text.trim().isEmpty) return;

    setState(() {
      _isSearching = true;
      _searchResults = [];
    });

    try {
      final results = await SpotifyPlaylistService.searchMultipleSongs(
        query: _searchController.text.trim(),
        limit: 5,
      );

      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Search failed: $e'),
            backgroundColor: ThemeConfig.errorRed,
          ),
        );
      }
    }
  }

  void _selectSong(Map<String, dynamic> track) {
    // Add to manually found URIs with position tracking
    _manuallyFoundUris.add(track['uri']);
    _foundPositions.add(
      _currentSong['position'] - 1,
    ); // Convert to 0-based index

    _moveToNextSong();
  }

  void _skipSong() {
    _moveToNextSong();
  }

  void _moveToNextSong() {
    if (_isLastSong) {
      _finishManualSearch();
      return;
    }

    setState(() {
      _currentSongIndex++;
      _searchResults = [];
      _isSearching = false;
    });

    _initializeSearch();
  }

  void _finishManualSearch() {
    Navigator.pop(context, {
      'manuallyFoundUris': _manuallyFoundUris,
      'updatedPositions': _foundPositions,
    });
  }

  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Manual Search?'),
        content: Text(
          _manuallyFoundUris.isNotEmpty
              ? 'You have found ${_manuallyFoundUris.length} songs. Do you want to save your progress and exit?'
              : 'Are you sure you want to exit without finding any songs?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              if (_manuallyFoundUris.isNotEmpty) {
                _finishManualSearch();
              } else {
                Navigator.pop(context); // Close search screen
              }
            },
            child: Text(_manuallyFoundUris.isNotEmpty ? 'Save & Exit' : 'Exit'),
          ),
        ],
      ),
    );
  }
}
