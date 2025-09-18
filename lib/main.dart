// import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:translator/translator.dart';
import 'package:google_mlkit_language_id/google_mlkit_language_id.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
// import 'package:image_picker/image_picker.dart';
import 'waveform_modal.dart';

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
  final String? text;
  final bool isUser;
  final String languageCode;
  final String? audioPath; // Local file path for audio message
  ChatMessage({this.text, required this.isUser, required this.languageCode, this.audioPath});
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
  // String? _recordedAudioPath;
  bool _showWaveformModal = false;
  String? _modalAudioPath;
  final Set<int> _playedBotVoiceIndices = {};

  @override
  void initState() {
    super.initState();
    _addBotMessage(
      "Hello, I’m Edumate! How can I help you with college-related information today?",
      'en',
    );
  }

  Future<void> _addBotMessage(String text, String lang, {String? audioPath}) async {
    setState(() {
      // If audioPath is present, always show text alongside audio
      _messages.add(ChatMessage(text: text, isUser: false, languageCode: lang, audioPath: audioPath));
    });
    if (audioPath == null) {
      await _speak(text, lang);
    }
  }

  Future<void> _speak(String text, String lang) async {
    await _flutterTts.setLanguage(lang);
    await _flutterTts.speak(text);
  }

  Future<void> _sendMessage({String? text, String? audioPath}) async {
    if ((text == null || text.trim().isEmpty) && audioPath == null) return;
    String detectedLang = text != null ? await _detectLanguage(text) : 'en';
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true, languageCode: detectedLang, audioPath: audioPath));
      _hasText = false;
    });
    _controller.clear();

    var translatedInput = text != null ? await translator.translate(text, to: 'en') : null;
    String rasaResponse = text != null ? await _queryRasa(translatedInput!.text) : "";

    if (rasaResponse == 'restricted') {
      String restrictedMsg = "Sorry, I can only help with college-related information.";
      var translatedRestricted = await translator.translate(restrictedMsg, to: detectedLang);
      await _addBotMessage(translatedRestricted.text, detectedLang);
    } else if (rasaResponse == "Sorry, I couldn't connect to the server.") {
      // Synthesize bot voice message and add as audio, always show text
      String botText = "Sorry, I couldn’t connect to the server.";
      String botAudioPath = await _synthesizeBotAudio(botText, detectedLang);
      await _addBotMessage(botText, detectedLang, audioPath: botAudioPath);
    } else {
      var translatedOutput = await translator.translate(rasaResponse, to: detectedLang);
      await _addBotMessage(translatedOutput.text, detectedLang);
    }
  }

  Future<String> _synthesizeBotAudio(String text, String lang) async {
    // Synthesize TTS and save to file
    // This is a placeholder. You need to implement saving TTS output to a file.
    // For now, just speak it.
    await _flutterTts.setLanguage(lang);
    await _flutterTts.speak(text);
    return ""; // Return path to audio file if implemented
  }

  Future<String> _detectLanguage(String text) async {
    try {
      final lang = await _languageIdentifier.identifyLanguage(text);
      return lang == 'und' ? 'en' : lang;
    } catch (e) {
      return 'en';
    }
  }

  // Press and hold voice input (record audio)
  Future<void> _startListening() async {
    // TODO: Implement audio recording and save to file
    // For now, fallback to speech-to-text
    bool available = await _speech.initialize();
    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (result) async {
          if (result.finalResult) {
            setState(() => _isListening = false);
            await _sendMessage(text: result.recognizedWords);
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

  // Background image logic removed

  // Placeholder for Rasa backend API call
  Future<String> _queryRasa(String message) async {
    // Replace with your Rasa endpoint
    final rasaUrl = Uri.parse('http://localhost:5005/webhooks/rest/webhook');
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
            // App logo image (logo.jpeg)
            Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: Colors.indigo.shade200),
                image: DecorationImage(
                  image: AssetImage('assets/images/logo.jpeg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ],
        ),
  backgroundColor: const Color(0xFF19202a),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Colors.indigo.shade50,
          image: DecorationImage(
            image: AssetImage('assets/images/background.jpg'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.18), BlendMode.dstATop),
          ),
        ),
        child: Column(
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
                    child: Row(
                      mainAxisAlignment: msg.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!msg.isUser)
                          Container(
                            width: 32,
                            height: 32,
                            margin: const EdgeInsets.only(right: 8, top: 2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              border: Border.all(color: Colors.indigo.shade200),
                              image: DecorationImage(
                                image: AssetImage('assets/images/logo.jpeg'),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        Flexible(
                          child: GestureDetector(
                            onTap: msg.audioPath != null
                                ? () {
                                    setState(() {
                                      _showWaveformModal = true;
                                      _modalAudioPath = msg.audioPath;
                                    });
                                  }
                                : null,
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
                              child: msg.audioPath != null
                                  ? Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (msg.isUser || !_playedBotVoiceIndices.contains(index))
                                              GestureDetector(
                                                onTap: msg.isUser
                                                    ? () {
                                                        // User voice message playback logic (unchanged)
                                                      }
                                                    : () async {
                                                        // Bot voice message: play only once
                                                        // TODO: Replace with actual audio playback logic
                                                        setState(() {
                                                          _playedBotVoiceIndices.add(index);
                                                        });
                                                      },
                                                child: Icon(
                                                  Icons.play_arrow,
                                                  color: Colors.deepPurpleAccent,
                                                ),
                                              )
                                            else
                                              Icon(
                                                Icons.play_arrow,
                                                color: Colors.grey,
                                              ),
                                            const SizedBox(width: 8),
                                            Text(
                                              msg.isUser ? "You (voice)" : "Bot (voice)",
                                              style: TextStyle(
                                                color: msg.isUser ? Colors.indigo.shade900 : Colors.black87,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (msg.text != null && msg.text!.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 6.0),
                                            child: Text(
                                              msg.text!,
                                              style: TextStyle(
                                                color: Colors.black87,
                                                fontSize: 15,
                                              ),
                                            ),
                                          ),
                                      ],
                                    )
                                  : Text(
                                      msg.text ?? "",
                                      style: TextStyle(
                                        color: msg.isUser ? Colors.indigo.shade900 : Colors.black87,
                                        fontSize: 16,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
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
                      onSubmitted: (val) => _sendMessage(text: val),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Send button only if text is present
                  if (_hasText)
                    IconButton(
                      icon: const Icon(Icons.send, color: Colors.deepPurpleAccent),
                      onPressed: () => _sendMessage(text: _controller.text),
                    ),
                  // Press and hold mic button for voice
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      GestureDetector(
                        onLongPress: () {
                          setState(() {
                            _isListening = true;
                          });
                          _startListening();
                        },
                        onLongPressUp: () {
                          setState(() {
                            _isListening = false;
                          });
                          _stopListening();
                        },
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
                      if (_isListening)
                        Positioned(
                          top: 56,
                          child: SizedBox(
                            width: 220,
                            height: 80,
                            child: WaveformModal(
                              audioPath: '',
                              onClose: () {},
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
