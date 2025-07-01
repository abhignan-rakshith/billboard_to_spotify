import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../config/theme_config.dart';
import '../services/spotify_playlist_service.dart';

class ManagePlaylistsScreen extends StatefulWidget {
  const ManagePlaylistsScreen({super.key});

  @override
  State<ManagePlaylistsScreen> createState() => _ManagePlaylistsScreenState();
}

class _ManagePlaylistsScreenState extends State<ManagePlaylistsScreen> {
  // State variables
  bool _isLoading = true;
  bool _isDeleting = false;
  List<Map<String, dynamic>> _playlists = [];
  Set<String> _selectedPlaylistIds = {};
  String _deleteProgress = '';
  int _deleteProgressCount = 0;
  int _deleteTotalCount = 0;

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Playlists'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (_selectedPlaylistIds.isNotEmpty && !_isDeleting)
            TextButton.icon(
              onPressed: _showDeleteConfirmation,
              icon: const Icon(Icons.delete, color: Colors.red),
              label: Text(
                '${_selectedPlaylistIds.length}',
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(child: _buildBody()),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: AppConstants.defaultPadding),
            Text('Loading your playlists...'),
          ],
        ),
      );
    }

    if (_isDeleting) {
      return _buildDeletingProgress();
    }

    if (_playlists.isEmpty) {
      return _buildEmptyState();
    }

    return _buildPlaylistList();
  }

  Widget _buildDeletingProgress() {
    final progress = _deleteTotalCount > 0
        ? _deleteProgressCount / _deleteTotalCount
        : 0.0;

    return Padding(
      padding: ThemeConfig.responsivePadding(context),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppConstants.largePadding),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.delete_forever, size: 48, color: Colors.red),
                  const SizedBox(height: AppConstants.defaultPadding),
                  const Text(
                    'Deleting Playlists',
                    style: ThemeConfig.titleStyle,
                  ),
                  const SizedBox(height: AppConstants.smallPadding),
                  Text(
                    _deleteProgress,
                    style: ThemeConfig.bodyStyle,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppConstants.defaultPadding),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey[300],
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.red),
                  ),
                  const SizedBox(height: AppConstants.smallPadding),
                  Text(
                    '$_deleteProgressCount / $_deleteTotalCount playlists',
                    style: ThemeConfig.subtitleStyle,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: ThemeConfig.responsivePadding(context),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.playlist_remove, size: 64, color: Colors.grey[400]),
            const SizedBox(height: AppConstants.defaultPadding),
            Text(
              'No Playlists Found',
              style: ThemeConfig.titleStyle.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: AppConstants.smallPadding),
            Text(
              'You don\'t have any playlists in your Spotify account yet.',
              style: ThemeConfig.bodyStyle.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaylistList() {
    return Column(
      children: [
        // Header with select all option
        _buildListHeader(),

        // Playlist list
        Expanded(
          child: ListView.builder(
            padding: ThemeConfig.responsivePadding(context),
            itemCount: _playlists.length,
            itemBuilder: (context, index) {
              final playlist = _playlists[index];
              return _buildPlaylistItem(playlist);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildListHeader() {
    final allSelected = _selectedPlaylistIds.length == _playlists.length;
    final someSelected = _selectedPlaylistIds.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          Checkbox(
            value: allSelected,
            tristate: true,
            onChanged: _toggleSelectAll,
            activeColor: Colors.red,
          ),
          const SizedBox(width: AppConstants.smallPadding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  someSelected
                      ? '${_selectedPlaylistIds.length} of ${_playlists.length} selected'
                      : '${_playlists.length} playlists found',
                  style: ThemeConfig.bodyStyle.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (someSelected)
                  Text(
                    'Tap delete button in top right to remove selected',
                    style: ThemeConfig.subtitleStyle.copyWith(fontSize: 12),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaylistItem(Map<String, dynamic> playlist) {
    final isSelected = _selectedPlaylistIds.contains(playlist['id']);
    final trackCount = playlist['trackCount'] ?? 0;
    final images = playlist['images'] as List?;
    final hasImage = images != null && images.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.smallPadding),
      child: CheckboxListTile(
        value: isSelected,
        onChanged: (bool? value) => _togglePlaylistSelection(playlist['id']),
        activeColor: Colors.red,
        secondary: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey[200],
          ),
          child: hasImage
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    images[0]['url'],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Icon(Icons.playlist_play, color: Colors.grey[400]),
                  ),
                )
              : Icon(Icons.playlist_play, color: Colors.grey[400]),
        ),
        title: Text(
          playlist['name'],
          style: ThemeConfig.bodyStyle.copyWith(fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (playlist['description'].isNotEmpty)
              Text(
                playlist['description'],
                style: ThemeConfig.subtitleStyle.copyWith(fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            Text(
              '$trackCount tracks • ${playlist['public'] ? 'Public' : 'Private'}',
              style: ThemeConfig.subtitleStyle.copyWith(fontSize: 11),
            ),
          ],
        ),
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }

  Widget _buildBottomBar() {
    if (_selectedPlaylistIds.isEmpty || _isDeleting) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_selectedPlaylistIds.length} playlists selected',
                  style: ThemeConfig.bodyStyle.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'This action cannot be undone',
                  style: ThemeConfig.subtitleStyle.copyWith(
                    fontSize: 12,
                    color: Colors.red[600],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppConstants.defaultPadding),
          ElevatedButton.icon(
            onPressed: _showDeleteConfirmation,
            icon: const Icon(Icons.delete_forever),
            label: const Text('Delete'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _loadPlaylists() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final playlists = await SpotifyPlaylistService.getAllUserPlaylists();

      setState(() {
        _playlists = playlists;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to load playlists: $e'),
            backgroundColor: ThemeConfig.errorRed,
          ),
        );
      }
    }
  }

  void _toggleSelectAll(bool? value) {
    setState(() {
      if (value == true) {
        // Select all
        _selectedPlaylistIds = _playlists.map((p) => p['id'] as String).toSet();
      } else {
        // Deselect all
        _selectedPlaylistIds.clear();
      }
    });
  }

  void _togglePlaylistSelection(String playlistId) {
    setState(() {
      if (_selectedPlaylistIds.contains(playlistId)) {
        _selectedPlaylistIds.remove(playlistId);
      } else {
        _selectedPlaylistIds.add(playlistId);
      }
    });
  }

  void _showDeleteConfirmation() {
    final selectedPlaylists = _playlists
        .where((p) => _selectedPlaylistIds.contains(p['id']))
        .toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Playlists?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete ${_selectedPlaylistIds.length} playlist${_selectedPlaylistIds.length == 1 ? '' : 's'}?',
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            const Text(
              'This action cannot be undone.',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            Container(
              constraints: const BoxConstraints(maxHeight: 150),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: selectedPlaylists.map((playlist) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        '• ${playlist['name']}',
                        style: ThemeConfig.subtitleStyle.copyWith(fontSize: 12),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteSelectedPlaylists();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _deleteSelectedPlaylists() async {
    setState(() {
      _isDeleting = true;
      _deleteProgressCount = 0;
      _deleteTotalCount = _selectedPlaylistIds.length;
      _deleteProgress = 'Starting deletion...';
    });

    try {
      final result = await SpotifyPlaylistService.deleteMultiplePlaylists(
        playlistIds: _selectedPlaylistIds.toList(),
        onProgress: (completed, total, currentName) {
          if (mounted) {
            setState(() {
              _deleteProgressCount = completed;
              _deleteProgress = currentName ?? 'Processing...';
            });
          }
        },
      );

      final successful = result['successful'] as int;
      final failed = result['failed'] as int;

      if (mounted) {
        setState(() {
          _isDeleting = false;
          _selectedPlaylistIds.clear();
        });

        // Show result
        String message;
        Color backgroundColor;

        if (failed == 0) {
          message =
              '🎉 Successfully deleted $successful playlist${successful == 1 ? '' : 's'}!';
          backgroundColor = ThemeConfig.successGreen;
        } else if (successful == 0) {
          message = '❌ Failed to delete all playlists. Check your connection.';
          backgroundColor = ThemeConfig.errorRed;
        } else {
          message =
              '⚠️ Deleted $successful, failed $failed playlist${failed == 1 ? '' : 's'}';
          backgroundColor = Colors.orange;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: backgroundColor,
            duration: const Duration(seconds: 4),
          ),
        );

        // Refresh the playlist list
        _loadPlaylists();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error during deletion: $e'),
            backgroundColor: ThemeConfig.errorRed,
          ),
        );
      }
    }
  }
}
