import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'http_helper.dart';

class BillboardScraperService {
  static const String BILLBOARD_URL =
      'https://www.billboard.com/charts/hot-100/';

  static Future<Map<String, List<String>>> scrapeHot100({
    String? customUrl,
  }) async {
    List<String> songNames = [];
    List<String> artistNames = [];

    final url = customUrl ?? BILLBOARD_URL;

    try {
      final response = await HttpHelper.requestWithRetry(
        () => http.get(
          Uri.parse(url),
          headers: {
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
            'Accept':
                'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
            'Accept-Language': 'en-US,en;q=0.5',
            'Connection': 'keep-alive',
          },
        ),
      );

      if (response.statusCode == 200) {
        final document = parser.parse(response.body);
        final chartContainers = document.querySelectorAll(
          '.o-chart-results-list-row-container',
        );

        print('Found ${chartContainers.length} chart entries');

        for (int i = 0; i < chartContainers.length; i++) {
          final container = chartContainers[i];

          try {
            // Get song name
            final songElement = container.querySelector('h3.c-title');
            final songName = songElement?.text.trim() ?? '';

            // Get artist name from spans, skipping chart indicators
            final allSpans = container.querySelectorAll('span.c-label');
            String artistName = '';

            for (final span in allSpans) {
              final spanText = span.text.trim();

              // Skip chart positions, indicators, and empty strings
              final isPureNumber = RegExp(r'^\d+$').hasMatch(spanText);
              final isChartIndicator =
                  spanText == 'NEW' ||
                  spanText == 'RE-ENTRY' ||
                  spanText.contains('RE-\nENTRY') ||
                  spanText == '-';

              if (!isPureNumber && !isChartIndicator && spanText.isNotEmpty) {
                artistName = spanText;
                break;
              }
            }

            final firstArtist = _extractFirstArtist(artistName);

            if (songName.isNotEmpty && firstArtist.isNotEmpty) {
              songNames.add(songName);
              artistNames.add(firstArtist);
            }
          } catch (e) {
            print('Error parsing entry ${i + 1}: $e');
          }
        }

        print('Successfully extracted ${songNames.length} songs');
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('Scraping error: $e');
      rethrow;
    }

    return <String, List<String>>{'songs': songNames, 'artists': artistNames};
  }

  static String _extractFirstArtist(String fullArtistString) {
    if (fullArtistString.isEmpty) return '';

    final separators = [
      ' & ',
      ' Featuring ',
      ' featuring ',
      ' Feat. ',
      ' feat. ',
      ' Ft. ',
      ' ft. ',
      ' X ',
      ' x ',
      ' and ',
      ' And ',
      ' with ',
      ' With ',
      ' Duet ',
      ',',
    ];

    String result = fullArtistString;
    int earliestIndex = result.length;

    for (final separator in separators) {
      final index = result.indexOf(separator);
      if (index != -1 && index < earliestIndex) {
        earliestIndex = index;
      }
    }

    if (earliestIndex < result.length) {
      result = result.substring(0, earliestIndex);
    }

    return result.trim();
  }
}
