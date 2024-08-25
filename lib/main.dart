import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

// You can use dart-define to pass the API Key.
// For example:
// flutter run --dart-define apiKey=YOUR_API_KEY
const String _apiKey = String.fromEnvironment('apiKey');

void main() {
  runApp(const SummaryIt());
}

class SummaryIt extends StatelessWidget {
  const SummaryIt({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SummaryIt',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          brightness: Brightness.light,
          seedColor: Colors.blue,
        ),
        useMaterial3: true,
      ),
      home: const SummaryScreen(title: 'SummaryIt'),
    );
  }
}

class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key, required this.title});
  final String title;

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  late final GenerativeModel _model;
  late final ChatSession _chat;
  final TextEditingController _textController = TextEditingController();
  final List<Map<String, String>> _summaries = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _model = GenerativeModel(model: 'gemini-1.5-flash-latest', apiKey: _apiKey);
    _chat = _model.startChat();
  }

  Future<void> _generateSummary(String text) async {
    setState(() => _loading = true);
    try {
      final response =
          await _chat.sendMessage(Content.text("Summarize: $text"));
      if (response.text != null) {
        setState(() {
          _summaries.add({"type": "original", "text": text});
          _summaries.add({"type": "summary", "text": response.text!});
        });
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _loading = false);
      _textController.clear();
    }
  }

  void _showError(String message) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: SelectableText(message),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(
          bottom: 25,
          left: 15,
          right: 15,
          top: 10,
        ),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 100,
                child: TextField(
                  controller: _textController,
                  maxLines: 10,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.all(15),
                    hintText: 'Enter text to summarize...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.secondary),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.secondary),
                    ),
                  ),
                  onSubmitted: (text) => _generateSummary(text),
                ),
              ),
            ),
            const SizedBox.square(dimension: 15),
            if (!_loading)
              IconButton(
                onPressed: () => _generateSummary(_textController.text),
                icon: Icon(
                  Icons.send,
                  color: Theme.of(context).colorScheme.primary,
                ),
              )
            else
              const CircularProgressIndicator(),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: _summaries.map((summary) {
                    bool isOriginal = summary["type"] == "original";
                    return Align(
                      alignment: isOriginal
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.all(15),
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        constraints: BoxConstraints(
                            maxWidth: MediaQuery.sizeOf(context).width / 2),
                        decoration: BoxDecoration(
                          color: isOriginal
                              ? Colors.grey.shade300
                              : Colors.blue.shade200,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Text(
                          summary['text'] ?? '',
                          textAlign:
                              isOriginal ? TextAlign.right : TextAlign.left,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
