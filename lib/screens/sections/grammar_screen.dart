import 'package:flutter/material.dart';

class GrammarScreen extends StatelessWidget {
  const GrammarScreen({super.key});
  static const String routeName = '/grammar_screen';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Grammar'),
        backgroundColor: const Color(0xFF8E4585),
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text('Grammar Screen Content'),
      ),
    );
  }
}
