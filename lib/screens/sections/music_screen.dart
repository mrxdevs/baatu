import 'package:flutter/material.dart';

class MusicScreen extends StatelessWidget {
  const MusicScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Music'),
        backgroundColor: const Color(0xFF8E4585),
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text('Music Screen Content'),
      ),
    );
  }
}
