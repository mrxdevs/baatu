import 'package:flutter/material.dart';
import '../../model/video_model.dart';
import 'video_player_screen.dart';

class VideosScreen extends StatelessWidget {
  const VideosScreen({super.key});
  static const String routeName = '/videos_screen';

  // Example video data - replace with actual data from your backend
  static final List<VideoModel> _videos = [
    VideoModel(
      id: '1',
      title: 'Basic English Conversation',
      description:
          'Learn common English phrases and expressions used in everyday conversations.',
      thumbnailUrl: 'https://example.com/thumbnail1.jpg',
      videoUrl:
          'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4',
      duration: const Duration(minutes: 5, seconds: 30),
      subtitles: [
        SubtitleEntry(
          startTime: const Duration(seconds: 0),
          endTime: const Duration(seconds: 3),
          text: "Welcome to English Learning",
          highlightedWords: ["Welcome", "English"],
        ),
        SubtitleEntry(
          startTime: const Duration(seconds: 3),
          endTime: const Duration(seconds: 6),
          text: "Let's practice pronunciation together",
          highlightedWords: ["pronunciation", "practice"],
        ),
      ],
    ),
    VideoModel(
      id: '2',
      title: 'Advanced Grammar Tips',
      description: 'Master complex grammar rules with practical examples.',
      thumbnailUrl: 'https://example.com/thumbnail2.jpg',
      videoUrl: 'https://example.com/video2.mp4',
      duration: const Duration(minutes: 8, seconds: 45),
      subtitles: [],
    ),
    VideoModel(
      id: '1',
      title: 'Video from te grammer',
      description:
          'Learn common English phrases and expressions used in everyday conversations.',
      thumbnailUrl: 'https://example.com/thumbnail1.jpg',
      videoUrl:
          'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4',
      duration: const Duration(minutes: 5, seconds: 30),
      subtitles: [
        SubtitleEntry(
          startTime: const Duration(seconds: 0),
          endTime: const Duration(seconds: 3),
          text: "Welcome to English Learning",
          highlightedWords: ["Welcome", "English"],
        ),
        SubtitleEntry(
          startTime: const Duration(seconds: 3),
          endTime: const Duration(seconds: 6),
          text: "Let's practice pronunciation together",
          highlightedWords: ["pronunciation", "practice"],
        ),
      ],
    ),
    VideoModel(
      id: '1',
      title: 'Basic Second',
      description:
          'Learn common English phrases and expressions used in everyday conversations.',
      thumbnailUrl: 'https://example.com/thumbnail1.jpg',
      videoUrl:
          'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4',
      duration: const Duration(minutes: 5, seconds: 30),
      subtitles: [
        SubtitleEntry(
          startTime: const Duration(seconds: 0),
          endTime: const Duration(seconds: 3),
          text: "Welcome to English Learning",
          highlightedWords: ["Welcome", "English"],
        ),
        SubtitleEntry(
          startTime: const Duration(seconds: 3),
          endTime: const Duration(seconds: 6),
          text: "Let's practice pronunciation together",
          highlightedWords: ["pronunciation", "practice"],
        ),
      ],
    ),
    // Add more videos as needed
  ];

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Videos'),
        backgroundColor: const Color(0xFF8E4585),
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        itemCount: _videos.length,
        itemBuilder: (context, index) {
          final video = _videos[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VideoPlayerScreen(video: video),
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            image: DecorationImage(
                              image: NetworkImage(video.thumbnailUrl),
                              fit: BoxFit.cover,
                              onError: (error, stackTrace) {},
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.play_circle_outline,
                              size: 48,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.all(8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _formatDuration(video.duration),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          video.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          video.description,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
