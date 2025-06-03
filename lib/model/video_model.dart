class VideoModel {
  final String id;
  final String title;
  final String description;
  final String thumbnailUrl;
  final String videoUrl;
  final Duration duration;
  final List<SubtitleEntry> subtitles;

  VideoModel({
    required this.id,
    required this.title,
    required this.description,
    required this.thumbnailUrl,
    required this.videoUrl,
    required this.duration,
    required this.subtitles,
  });
}

class SubtitleEntry {
  final Duration startTime;
  final Duration endTime;
  final String text;
  final List<String> highlightedWords;

  SubtitleEntry({
    required this.startTime,
    required this.endTime,
    required this.text,
    required this.highlightedWords,
  });
}
