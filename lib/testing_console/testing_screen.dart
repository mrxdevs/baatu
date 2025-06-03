import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:baatu/testing_console/audio_call/audio_call_screen.dart';
import 'package:baatu/testing_console/markdown_fomatter_screen.dart';
import 'package:baatu/testing_console/notification_test_screen.dart';
import 'package:baatu/testing_console/video_call/index.dart';
import 'package:baatu/testing_console/video_call/video_call_screen.dart';
import 'package:flutter/material.dart';

import 'audio_call/audio_index_screen.dart';

class TestingScreen extends StatefulWidget {
  const TestingScreen({super.key});

  @override
  State<TestingScreen> createState() => _TestingScreenState();
  static const String routeName = '/testing_screen';
}

class _TestingScreenState extends State<TestingScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> testingOptions = [
    {
      'title': 'Markdown Formatter',
      'icon': Icons.text_fields,
      'screen': const MarkdownFormatterScreen(),
    },
    {
      'title': 'Video Call',
      'icon': Icons.video_call_outlined,
      'screen': const VideoCallScreen(),
    },
    {
      'title': 'Video Call Indexing',
      'icon': Icons.video_chat_outlined,
      'screen': const IndexPage()
    },
    {
      'title': 'Audio Call',
      'icon': Icons.call_outlined,
      'screen': const AudioCallScreen(
          channelName: "baatu", role: ClientRoleType.clientRoleBroadcaster),
    },
    {
      'title': 'Audio Call Indexing',
      'icon': Icons.spatial_audio_off_outlined,
      'screen': const AudioIndexScreen()
    },
    {
      'title': 'Notification Testing',
      'icon': Icons.notifications_outlined,
      'screen': const NotificationTestScreen(),
    },
  ];

  List<Map<String, dynamic>> filteredOptions = [];

  @override
  void initState() {
    super.initState();
    filteredOptions = testingOptions;
  }

  void _filterOptions(String query) {
    setState(() {
      filteredOptions = testingOptions
          .where((option) =>
              option['title'].toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Testing Studio',
          style: theme.textTheme.headlineMedium?.copyWith(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: theme.primaryColor,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: _filterOptions,
              decoration: InputDecoration(
                hintText: 'Search testing options...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
              ),
              itemCount: filteredOptions.length,
              itemBuilder: (context, index) {
                final option = filteredOptions[index];
                return Card(
                  elevation: 4,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => option['screen'],
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          option['icon'],
                          size: 48,
                          color: theme.primaryColor,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          option['title'],
                          style: theme.textTheme.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
