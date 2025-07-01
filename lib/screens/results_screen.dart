import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../config/theme_config.dart';
import '../config/app_routes.dart';
import 'playlist_creation_screen.dart';

class ResultsScreen extends StatefulWidget {
  final String selectedDate;
  final List<String> songs;
  final List<String> artists;

  const ResultsScreen({
    super.key,
    required this.selectedDate,
    required this.songs,
    required this.artists,
  });

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  final Set<int> _expandedCards = <int>{};

  void _toggleCard(int index) {
    setState(() {
      if (_expandedCards.contains(index)) {
        _expandedCards.remove(index);
      } else {
        _expandedCards.add(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Billboard Results'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SafeArea(
        child: Padding(
          padding: ThemeConfig.responsivePadding(context),
          child: Column(
            children: [
              // Date Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                decoration: BoxDecoration(
                  color: ThemeConfig.spotifyGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: ThemeConfig.spotifyGreen.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Billboard Hot 100',
                      style: ThemeConfig.titleStyle,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.selectedDate,
                      style: ThemeConfig.subtitleStyle.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.songs.length} Songs Found',
                      style: ThemeConfig.bodyStyle,
                    ),
                    const SizedBox(height: AppConstants.defaultPadding),

                    // Create Playlist Button
                    SizedBox(
                      width: double.infinity,
                      height: AppConstants.smallButtonHeight,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.playlistCreation,
                            arguments: {
                              'selectedDate': widget.selectedDate,
                              'songs': widget.songs,
                              'artists': widget.artists,
                            },
                          );
                        },
                        icon: const Icon(Icons.playlist_add),
                        label: const Text('Create Spotify Playlist'),
                        style: ThemeConfig.primaryButtonStyle,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppConstants.defaultPadding),

              // Song Cards List
              Expanded(
                child: ListView.builder(
                  itemCount: widget.songs.length,
                  itemBuilder: (context, index) {
                    // Song cards
                    final isExpanded = _expandedCards.contains(index);
                    final songName = widget.songs[index];
                    final artistName = index < widget.artists.length
                        ? widget.artists[index]
                        : 'Unknown Artist';

                    return Padding(
                      padding: const EdgeInsets.only(
                        bottom: AppConstants.smallPadding,
                      ),
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _toggleCard(index),
                          child: Padding(
                            padding: const EdgeInsets.all(
                              AppConstants.defaultPadding,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    // Chart position
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: ThemeConfig.spotifyGreen,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${index + 1}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(
                                      width: AppConstants.defaultPadding,
                                    ),

                                    // Song name and expand icon
                                    Expanded(
                                      child: Text(
                                        songName,
                                        style: ThemeConfig.bodyStyle.copyWith(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Icon(
                                      isExpanded
                                          ? Icons.expand_less
                                          : Icons.expand_more,
                                      color: ThemeConfig.spotifyGreen,
                                    ),
                                  ],
                                ),

                                // Artist name (shown when expanded)
                                if (isExpanded) ...[
                                  const SizedBox(
                                    height: AppConstants.smallPadding,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 48.0),
                                    child: Text(
                                      'Artist: $artistName',
                                      style: ThemeConfig.subtitleStyle.copyWith(
                                        fontSize: 14,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
