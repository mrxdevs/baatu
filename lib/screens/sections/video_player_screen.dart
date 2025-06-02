import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../../model/video_model.dart';

class VideoPlayerScreen extends StatefulWidget {
  final VideoModel video;

  const VideoPlayerScreen({
    super.key,
    required this.video,
  });

  static const String routeName = '/video_player';

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  int _currentSubtitleIndex = 0;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    _videoPlayerController =
        VideoPlayerController.network(widget.video.videoUrl);
    await _videoPlayerController.initialize();

    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController,
      autoPlay: false,
      looping: false,
      aspectRatio: 16 / 9,
      placeholder: Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );

    _videoPlayerController.addListener(_onVideoProgressChanged);

    setState(() {
      _isInitialized = true;
    });
  }

  void _onVideoProgressChanged() {
    if (!_videoPlayerController.value.isPlaying) return;

    final currentPosition = _videoPlayerController.value.position;
    final subtitle = _findCurrentSubtitle(currentPosition);

    if (subtitle != null &&
        _currentSubtitleIndex != widget.video.subtitles.indexOf(subtitle)) {
      setState(() {
        _currentSubtitleIndex = widget.video.subtitles.indexOf(subtitle);
      });
    }
  }

  SubtitleEntry? _findCurrentSubtitle(Duration position) {
    return widget.video.subtitles.firstWhere(
      (subtitle) =>
          position >= subtitle.startTime && position <= subtitle.endTime,
      orElse: () => widget.video.subtitles[_currentSubtitleIndex],
    );
  }

  Widget _buildSubtitleText(String text, List<String> highlightedWords) {
    final words = text.split(' ');
    return Wrap(
      alignment: WrapAlignment.center,
      children: words.map((word) {
        final shouldHighlight = highlightedWords.contains(word);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Text(
            word,
            style: TextStyle(
              fontSize: 18,
              color: shouldHighlight ? const Color(0xFF8E4585) : Colors.white,
              fontWeight: shouldHighlight ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.video.title),
        backgroundColor: const Color(0xFF8E4585),
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.black,
      body: _isInitialized
          ? Column(
              children: [
                Expanded(
                  child: Chewie(
                    controller: _chewieController!,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.black.withOpacity(0.8),
                  child: _currentSubtitleIndex < widget.video.subtitles.length
                      ? _buildSubtitleText(
                          widget.video.subtitles[_currentSubtitleIndex].text,
                          widget.video.subtitles[_currentSubtitleIndex]
                              .highlightedWords,
                        )
                      : const SizedBox.shrink(),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.black,
                  child: Text(
                    widget.video.description,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            )
          : const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF8E4585),
              ),
            ),
    );
  }
}
