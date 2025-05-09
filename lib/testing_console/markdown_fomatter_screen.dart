import 'package:flutter/material.dart';
// import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

class MarkdownFormatterScreen extends StatefulWidget {
  static const String routeName = '/markdown_formatter_screen';

  const MarkdownFormatterScreen({super.key});

  @override
  State<MarkdownFormatterScreen> createState() => _MarkdownFormatterScreenState();
}

class _MarkdownFormatterScreenState extends State<MarkdownFormatterScreen> {
  final TextEditingController _markdownInputController = TextEditingController();
  String _renderedMarkdown = '';

  void _convertMarkdown() {
    setState(() {
      _renderedMarkdown = _markdownInputController.text;
    });
  }

  @override
  void dispose() {
    _markdownInputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Markdown Formatter'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextField(
              controller: _markdownInputController,
              decoration: const InputDecoration(
                labelText: 'Enter Markdown String',
                hintText: 'e.g., # Hello\\n**Bold Text**',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
              textInputAction: TextInputAction.newline,
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _convertMarkdown,
              child: const Text('Convert & Display'),
            ),
            const SizedBox(height: 24.0),
            const Text(
              'Rendered Output:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            const SizedBox(height: 8.0),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: SingleChildScrollView(
                  // child: Markdown(
                  //   data: _renderedMarkdown,
                  //   styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)), // Add this line
                  //   // Any other parameters for Markdown widget would go here
                  // ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}