import '../services/billboard_scraper.dart';

void main() async {
  try {
    final chartData = await BillboardScraperService.scrapeHot100();

    final songs = chartData['songs']!;
    final artists = chartData['artists']!;

    for (int i = 0; i < songs.length && i < artists.length; i++) {
      print('${i + 1}. "${songs[i]}" by ${artists[i]}');
    }
  } catch (e) {
    print('Error: $e');
  }
}
