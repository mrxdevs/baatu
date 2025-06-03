import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../model/word_models.dart';

class WordListScreen extends StatefulWidget {
  final WordCategory category;
  final List<Word> words;

  const WordListScreen({
    super.key,
    required this.category,
    required this.words,
  });

  @override
  State<WordListScreen> createState() => _WordListScreenState();
}

class _WordListScreenState extends State<WordListScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  int? _expandedIndex;

  Future<void> _playAudio(String audioUrl) async {
    try {
      await _audioPlayer.play(UrlSource(audioUrl));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error playing audio: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category.name),
        backgroundColor: const Color(0xFF8E4585),
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        itemCount: widget.words.length,
        itemBuilder: (context, index) {
          final word = widget.words[index];
          final isExpanded = _expandedIndex == index;

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ExpansionTile(
              onExpansionChanged: (expanded) {
                setState(() {
                  _expandedIndex = expanded ? index : null;
                });
              },
              initiallyExpanded: isExpanded,
              title: Row(
                children: [
                  Text(
                    word.word,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    word.pronunciation,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
              trailing: IconButton(
                icon: const Icon(Icons.volume_up),
                color: const Color(0xFF8E4585),
                onPressed: () => _playAudio(word.audioUrl),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        word.meaning,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Example: ${word.example}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      if (word.synonyms.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Synonyms: ${word.synonyms.join(", ")}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                      if (word.antonyms.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Antonyms: ${word.antonyms.join(", ")}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
