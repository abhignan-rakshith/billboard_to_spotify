import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import '../constants/app_constants.dart';
import '../config/theme_config.dart';
import '../config/app_routes.dart';

class CuratedPlaylistScreen extends StatefulWidget {
  const CuratedPlaylistScreen({super.key});

  @override
  State<CuratedPlaylistScreen> createState() => _CuratedPlaylistScreenState();
}

class _CuratedPlaylistScreenState extends State<CuratedPlaylistScreen> {
  final TextEditingController _jsonController = TextEditingController();
  final String _curatorUrl =
      'https://claude.ai/public/artifacts/94cd4340-6ae5-4d06-b788-89beb65b91a3';

  bool _isValidJson = false;
  Map<String, dynamic>? _parsedData;
  String? _validationError;

  @override
  void dispose() {
    _jsonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Curated Playlist'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: ThemeConfig.responsivePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCuratorSection(),
              const SizedBox(height: AppConstants.largePadding),
              _buildInputSection(),
              const SizedBox(height: AppConstants.defaultPadding),
              _buildValidationSection(),
              const SizedBox(height: AppConstants.largePadding),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCuratorSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.purple.withOpacity(0.1),
            Colors.blue.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purple.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.purple,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppConstants.defaultPadding),
              const Expanded(
                child: Text(
                  'AI Playlist Curator',
                  style: ThemeConfig.titleStyle,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.defaultPadding),
          const Text(
            'Need a custom playlist? Use our AI curator to generate playlists based on your preferences, mood, or occasion.',
            style: ThemeConfig.bodyStyle,
          ),
          const SizedBox(height: AppConstants.defaultPadding),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _openCurator,
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open AI Playlist Curator'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppConstants.smallPadding),
          Text(
            'Copy the generated JSON and paste it below, or save it as a file to upload.',
            style: ThemeConfig.subtitleStyle.copyWith(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInputSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text('Playlist JSON', style: ThemeConfig.titleStyle),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: _uploadFile,
                  icon: const Icon(Icons.upload_file),
                  tooltip: 'Upload JSON file',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.blue.withOpacity(0.1),
                  ),
                ),
                const SizedBox(width: AppConstants.smallPadding),
                IconButton(
                  onPressed: _pasteFromClipboard,
                  icon: const Icon(Icons.content_paste),
                  tooltip: 'Paste from clipboard',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.green.withOpacity(0.1),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppConstants.smallPadding),
        const Text(
          'Paste your playlist JSON here or upload a JSON file:',
          style: ThemeConfig.bodyStyle,
        ),
        const SizedBox(height: AppConstants.defaultPadding),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isValidJson
                  ? Colors.green
                  : _validationError != null
                  ? Colors.red
                  : Colors.grey,
            ),
          ),
          child: TextField(
            controller: _jsonController,
            maxLines: 12,
            onChanged: _validateJson,
            decoration: InputDecoration(
              hintText: _getJsonHintText(),
              hintStyle: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
                fontFamily: 'monospace',
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(AppConstants.defaultPadding),
            ),
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildValidationSection() {
    if (_validationError == null && !_isValidJson) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: _isValidJson
            ? Colors.green.withOpacity(0.1)
            : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _isValidJson ? Colors.green : Colors.red),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _isValidJson ? Icons.check_circle : Icons.error,
                color: _isValidJson ? Colors.green : Colors.red,
                size: 20,
              ),
              const SizedBox(width: AppConstants.smallPadding),
              Text(
                _isValidJson ? 'Valid Playlist JSON' : 'JSON Validation Error',
                style: ThemeConfig.bodyStyle.copyWith(
                  fontWeight: FontWeight.w600,
                  color: _isValidJson ? Colors.green[700] : Colors.red[700],
                ),
              ),
            ],
          ),
          if (_isValidJson && _parsedData != null) ...[
            const SizedBox(height: AppConstants.smallPadding),
            _buildPlaylistPreview(),
          ],
          if (_validationError != null) ...[
            const SizedBox(height: AppConstants.smallPadding),
            Text(
              _validationError!,
              style: ThemeConfig.bodyStyle.copyWith(
                color: Colors.red[700],
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlaylistPreview() {
    if (_parsedData == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Playlist: ${_parsedData!['playlist_name']}',
          style: ThemeConfig.bodyStyle.copyWith(fontWeight: FontWeight.w600),
        ),
        if (_parsedData!['description'] != null)
          Text(
            _parsedData!['description'],
            style: ThemeConfig.subtitleStyle.copyWith(fontSize: 12),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        const SizedBox(height: 4),
        Text(
          '${_parsedData!['songs']?.length ?? 0} songs',
          style: ThemeConfig.subtitleStyle.copyWith(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: AppConstants.buttonHeight,
          child: ElevatedButton.icon(
            onPressed: _isValidJson ? _createPlaylist : null,
            icon: const Icon(Icons.playlist_add),
            label: const Text('Create Playlist'),
            style: ThemeConfig.primaryButtonStyle,
          ),
        ),
        const SizedBox(height: AppConstants.defaultPadding),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _clearInput,
            icon: const Icon(Icons.clear),
            label: const Text('Clear Input'),
          ),
        ),
      ],
    );
  }

  String _getJsonHintText() {
    return '''{
  "playlist_name": "My Custom Playlist",
  "description": "A great playlist for any occasion",
  "total_songs": 3,
  "songs": [
    {
      "song_name": "Song Title",
      "artist_name": "Artist Name"
    },
    {
      "song_name": "Another Song",
      "artist_name": "Another Artist"
    }
  ]
}''';
  }

  void _openCurator() async {
    try {
      final launched = await launchUrl(
        Uri.parse(_curatorUrl),
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Could not open AI Playlist Curator'),
              backgroundColor: ThemeConfig.errorRed,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error opening curator: $e'),
            backgroundColor: ThemeConfig.errorRed,
          ),
        );
      }
    }
  }

  void _uploadFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null) {
        final file = File(result.files.single.path!);
        final contents = await file.readAsString();

        setState(() {
          _jsonController.text = contents;
        });

        _validateJson(contents);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ File uploaded successfully'),
              backgroundColor: ThemeConfig.successGreen,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error uploading file: $e'),
            backgroundColor: ThemeConfig.errorRed,
          ),
        );
      }
    }
  }

  void _pasteFromClipboard() async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);

      if (clipboardData?.text != null && clipboardData!.text!.isNotEmpty) {
        setState(() {
          _jsonController.text = clipboardData.text!;
        });

        _validateJson(clipboardData.text!);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Pasted from clipboard'),
              backgroundColor: ThemeConfig.successGreen,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ Clipboard is empty'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error pasting from clipboard: $e'),
            backgroundColor: ThemeConfig.errorRed,
          ),
        );
      }
    }
  }

  void _validateJson(String jsonText) {
    if (jsonText.trim().isEmpty) {
      setState(() {
        _isValidJson = false;
        _parsedData = null;
        _validationError = null;
      });
      return;
    }

    try {
      final parsed = json.decode(jsonText);

      // Validate required fields
      final validation = _validatePlaylistStructure(parsed);

      setState(() {
        if (validation['isValid']) {
          _isValidJson = true;
          _parsedData = parsed;
          _validationError = null;
        } else {
          _isValidJson = false;
          _parsedData = null;
          _validationError = validation['error'];
        }
      });
    } catch (e) {
      setState(() {
        _isValidJson = false;
        _parsedData = null;
        _validationError = 'Invalid JSON format: ${e.toString()}';
      });
    }
  }

  Map<String, dynamic> _validatePlaylistStructure(dynamic parsed) {
    if (parsed is! Map<String, dynamic>) {
      return {'isValid': false, 'error': 'JSON must be an object'};
    }

    // Check required fields
    if (!parsed.containsKey('playlist_name') ||
        parsed['playlist_name'] == null ||
        parsed['playlist_name'].toString().trim().isEmpty) {
      return {
        'isValid': false,
        'error': 'Missing or empty "playlist_name" field',
      };
    }

    if (!parsed.containsKey('songs') || parsed['songs'] is! List) {
      return {'isValid': false, 'error': 'Missing or invalid "songs" array'};
    }

    final songs = parsed['songs'] as List;
    if (songs.isEmpty) {
      return {'isValid': false, 'error': 'Songs array cannot be empty'};
    }

    // Validate each song
    for (int i = 0; i < songs.length; i++) {
      final song = songs[i];
      if (song is! Map<String, dynamic>) {
        return {
          'isValid': false,
          'error': 'Song at index $i must be an object',
        };
      }

      if (!song.containsKey('song_name') ||
          song['song_name'] == null ||
          song['song_name'].toString().trim().isEmpty) {
        return {
          'isValid': false,
          'error': 'Song at index $i missing "song_name"',
        };
      }

      if (!song.containsKey('artist_name') ||
          song['artist_name'] == null ||
          song['artist_name'].toString().trim().isEmpty) {
        return {
          'isValid': false,
          'error': 'Song at index $i missing "artist_name"',
        };
      }
    }

    return {'isValid': true};
  }

  void _clearInput() {
    setState(() {
      _jsonController.clear();
      _isValidJson = false;
      _parsedData = null;
      _validationError = null;
    });
  }

  void _createPlaylist() {
    if (!_isValidJson || _parsedData == null) return;

    // Extract data for playlist creation
    final playlistName = _parsedData!['playlist_name'];
    final description = _parsedData!['description'] ?? '';
    final songs = _parsedData!['songs'] as List;

    // Convert to the format expected by existing playlist creation flow
    final songNames = songs
        .map((song) => song['song_name'].toString())
        .toList();
    final artistNames = songs
        .map((song) => song['artist_name'].toString())
        .toList();

    // Navigate to playlist creation screen using existing infrastructure
    Navigator.pushNamed(
      context,
      AppRoutes.playlistCreation,
      arguments: {
        'selectedDate': 'Custom Curated Playlist',
        'songs': songNames,
        'artists': artistNames,
        'customPlaylistName': playlistName,
        'customDescription': description,
      },
    );
  }
}
