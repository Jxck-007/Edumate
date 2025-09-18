import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:translator/translator.dart';
import 'package:google_mlkit_language_id/google_mlkit_language_id.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:image_picker/image_picker.dart';
import 'package:edumate/voice_chat_overlay.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Edumate',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const ChatScreen(),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final String languageCode;
  ChatMessage({required this.text, required this.isUser, required this.languageCode});
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final FlutterTts _flutterTts = FlutterTts();
  final translator = GoogleTranslator();
  final stt.SpeechToText _speech = stt.SpeechToText();
  final LanguageIdentifier _languageIdentifier = LanguageIdentifier(confidenceThreshold: 0.5);
  bool _isListening = false;
  bool _hasText = false;
  Color _backgroundColor = Colors.indigo.shade50;
  File? _backgroundImage;

  @override
  void initState() {
    super.initState();
    _addBotMessage(
      "Hello, I’m Edumate! How can I help you with college-related information today?",
      'en',
    );
  }

  Future<void> _addBotMessage(String text, String lang) async {
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: false, languageCode: lang));
    });
    await _speak(text, lang);
  }

  Future<void> _speak(String text, String lang) async {
    await _flutterTts.setLanguage(lang);
    await _flutterTts.speak(text);
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    String detectedLang = await _detectLanguage(text);
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true, languageCode: detectedLang));
      _hasText = false;
    });
    _controller.clear();

    var translatedInput = await translator.translate(text, to: 'en');
    String rasaResponse = await _queryRasa(translatedInput.text);

    if (rasaResponse == 'restricted') {
      String restrictedMsg = "Sorry, I can only help with college-related information.";
      var translatedRestricted = await translator.translate(restrictedMsg, to: detectedLang);
      await _addBotMessage(translatedRestricted.text, detectedLang);
    } else {
      var translatedOutput = await translator.translate(rasaResponse, to: detectedLang);
      await _addBotMessage(translatedOutput.text, detectedLang);
    }
  }

  Future<String> _detectLanguage(String text) async {
    try {
      final lang = await _languageIdentifier.identifyLanguage(text);
      return lang == 'und' ? 'en' : lang;
    } catch (e) {
      return 'en';
    }
  }

  // Press and hold voice input
  Future<void> _startListening() async {
    bool available = await _speech.initialize();
    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (result) async {
          if (result.finalResult) {
            setState(() => _isListening = false);
            await _sendMessage(result.recognizedWords);
          }
        },
        listenFor: const Duration(seconds: 30),
        localeId: 'en_US',
      );
    }
  }

  Future<void> _stopListening() async {
    setState(() => _isListening = false);
    await _speech.stop();
  }

  // Pick background image from gallery
  Future<void> _pickBackgroundImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _backgroundImage = File(pickedFile.path);
      });
    }
  }

  // Placeholder for Rasa backend API call
  Future<String> _queryRasa(String message) async {
    // Replace with your Rasa endpoint
    final rasaUrl = Uri.parse('http://172.16.4.159:5005/webhooks/rest/webhook');
    try {
      final response = await http.post(
        rasaUrl,
        headers: {'Content-Type': 'application/json'},
        body: '{"sender":"user","message":"$message"}',
      );
      if (response.statusCode == 200) {
        final responseBody = response.body;
        if (!_isCollegeOrTechnical(message)) {
          return 'restricted';
        }
        final text = RegExp(r'"text"\s*:\s*"([^"]+)"').firstMatch(responseBody)?.group(1) ?? '';
        return text.isNotEmpty ? text : "Sorry, I couldn't understand.";
      } else {
        return "Sorry, I couldn't connect to the server.";
      }
    } catch (e) {
      return "Sorry, I couldn't connect to the server.";
    }
  }

  // Simulate topic restriction (replace with actual logic)
  bool _isCollegeOrTechnical(String message) {
    final keywords = [
      'college', 'course', 'department', 'admission', 'exam', 'syllabus',
      'professor', 'hostel', 'placement', 'technical', 'engineering', 'science'
    ];
    return keywords.any((kw) => message.toLowerCase().contains(kw));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            // Logo placeholder
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: Colors.indigo.shade200),
              ),
              child: const Icon(Icons.school, color: Colors.indigo), // Replace with logo later
            ),
            const Text(
              'Edumate',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.image),
            tooltip: 'Set background image',
            onPressed: _pickBackgroundImage,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          color: _backgroundImage == null ? _backgroundColor : null,
          image: _backgroundImage != null
              ? DecorationImage(
                  image: FileImage(_backgroundImage!),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: Stack(
          children: [
            Column(
              children: [
                const Divider(height: 1),
                // Chat area
                Expanded(
                  child: ListView.builder(
                    reverse: false,
                    padding: const EdgeInsets.all(8),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      return Align(
                        alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          constraints: const BoxConstraints(maxWidth: 320),
                          decoration: BoxDecoration(
                            color: msg.isUser
                                ? Colors.lightBlue[200]?.withOpacity(0.85)
                                : Colors.grey[100]?.withOpacity(0.85),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(msg.isUser ? 16 : 4),
                              topRight: Radius.circular(msg.isUser ? 4 : 16),
                              bottomLeft: const Radius.circular(16),
                              bottomRight: const Radius.circular(16),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            msg.text,
                            style: TextStyle(
                              color: msg.isUser ? Colors.indigo.shade900 : Colors.black87,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Input area
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  color: Colors.white.withOpacity(0.8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          decoration: const InputDecoration(
                            hintText: 'Type your message...',
                            border: OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          onChanged: (val) {
                            setState(() => _hasText = val.trim().isNotEmpty);
                          },
                          onSubmitted: _sendMessage,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Send button only if text is present
                      if (_hasText)
                        IconButton(
                          icon: const Icon(Icons.send, color: Colors.deepPurpleAccent),
                          onPressed: () => _sendMessage(_controller.text),
                        ),
                      // Press and hold mic button for voice
                      GestureDetector(
                        onLongPress: _startListening,
                        onLongPressUp: _stopListening,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isListening ? Colors.indigo.shade100 : Colors.grey.shade200,
                          ),
                          padding: const EdgeInsets.all(8),
                          child: Icon(
                            _isListening ? Icons.mic : Icons.mic_none,
                            color: Colors.deepPurpleAccent,
                            size: 28,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: VoiceChatOverlay(isListening: _isListening),
            ),
          ],
        ),
      ),
    );
  }
}
