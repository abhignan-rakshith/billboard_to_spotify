import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_constants.dart';
import '../config/theme_config.dart';
import '../services/billboard_scraper.dart';
import 'results_screen.dart';

class BillboardScreen extends StatefulWidget {
  const BillboardScreen({super.key});

  @override
  State<BillboardScreen> createState() => _BillboardScreenState();
}

class _BillboardScreenState extends State<BillboardScreen> {
  DateTime _selectedDate = DateTime.now();
  bool _openWebsite = false;
  bool _isLoading = false;

  Future<void> _scanBillboardChart() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Format the date for Billboard URL
      final formattedDate = '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
      final billboardUrl = 'https://www.billboard.com/charts/hot-100/$formattedDate/';

      print('Scanning Billboard chart for date: $formattedDate');
      print('Billboard URL: $billboardUrl');

      // Open website if checkbox is selected
      if (_openWebsite) {
        try {
          await launchUrl(
            Uri.parse(billboardUrl),
            mode: LaunchMode.externalApplication,
          );
        } catch (e) {
          print('Error opening website: $e');
        }
      }

      // Scrape the Billboard data
      final scrapedData = await BillboardScraperService.scrapeHot100(
        customUrl: billboardUrl,
      );

      final songCount = scrapedData['songs']?.length ?? 0;
      print('Scraped $songCount songs');

      // Handle empty results
      if (songCount == 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('⚠️ No chart data found for $formattedDate.\n\nThe Billboard Hot 100 is updated on Tuesdays. This date may not have a published chart yet, or the chart may not be available for historical dates.'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      } else {
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Found $songCount songs from Billboard Hot 100!'),
              backgroundColor: ThemeConfig.successGreen,
            ),
          );

          // Navigate to results screen after 2 seconds
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ResultsScreen(
                    selectedDate: '${_selectedDate.day.toString().padLeft(2, '0')}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.year}',
                    songs: scrapedData['songs'] ?? [],
                    artists: scrapedData['artists'] ?? [],
                  ),
                ),
              );
            }
          });
        }
      }

    } catch (e) {
      print('Error scanning chart: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error scanning chart: $e'),
            backgroundColor: ThemeConfig.errorRed,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Billboard Hot 100'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SafeArea(
        child: Padding(
          padding: ThemeConfig.responsivePadding(context),
          child: Column(
            children: [
              // Title
              const Text(
                'Select Billboard Chart Date',
                style: ThemeConfig.titleStyle,
              ),
              const SizedBox(height: AppConstants.defaultPadding),

              // Date Picker Container
              Container(
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: _selectedDate,
                  minimumDate: DateTime(1958, 8, 4), // First Billboard Hot 100
                  maximumDate: DateTime.now(),
                  onDateTimeChanged: (DateTime newDate) {
                    setState(() {
                      _selectedDate = newDate;
                    });
                  },
                ),
              ),
              const SizedBox(height: AppConstants.defaultPadding),

              // Selected Date Display
              Text(
                'Selected: ${_selectedDate.day.toString().padLeft(2, '0')}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.year}',
                style: ThemeConfig.bodyStyle,
              ),
              const SizedBox(height: AppConstants.largePadding),

              // Open Website Checkbox
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Checkbox(
                    value: _openWebsite,
                    onChanged: (bool? value) {
                      setState(() {
                        _openWebsite = value ?? false;
                      });
                    },
                    activeColor: ThemeConfig.spotifyGreen,
                  ),
                  const Text(
                    'Open website',
                    style: ThemeConfig.bodyStyle,
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.largePadding),

              // Scan Button
              SizedBox(
                width: double.infinity,
                height: AppConstants.buttonHeight,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _scanBillboardChart,
                  icon: _isLoading
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Icon(Icons.search),
                  label: Text(_isLoading ? 'Scanning...' : 'Scan Billboard Chart'),
                  style: ThemeConfig.primaryButtonStyle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}