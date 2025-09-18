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

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final List<ChatMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final FlutterTts _flutterTts = FlutterTts();
  final translator = GoogleTranslator();
  final stt.SpeechToText _speech = stt.SpeechToText();
  final LanguageIdentifier _languageIdentifier = LanguageIdentifier(confidenceThreshold: 0.5);
  
  bool _isListening = false;
  bool _hasText = false;
  bool _isSpeaking = false; // Track when TTS is active
  bool _showWaveformModal = false;
  String? _modalAudioPath;
  final Set<int> _playedBotVoiceIndices = {};
  
  // Animation controllers for voice chat
  late AnimationController _micAnimationController;
  late AnimationController _voiceAnimationController;
  late Animation<double> _micAnimation;
  late Animation<double> _voiceAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controllers
    _micAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _voiceAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _micAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _micAnimationController, curve: Curves.easeInOut),
    );
    _voiceAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _voiceAnimationController, curve: Curves.easeInOut),
    );
    
    // Set up TTS completion handler
    _flutterTts.setCompletionHandler(() {
      setState(() {
        _isSpeaking = false;
      });
      _voiceAnimationController.stop();
    });
    
    // Add welcome message but DON'T speak it automatically
    _addBotMessage(
      "Hello, I'm Edumate! How can I help you with college-related information today?",
      'en',
      autoSpeak: false, // Don't auto-speak on init
    );
  }

  @override
  void dispose() {
    _micAnimationController.dispose();
    _voiceAnimationController.dispose();
    super.dispose();
  }

  Future<void> _addBotMessage(String text, String lang, {String? audioPath, bool autoSpeak = true}) async {
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: false, languageCode: lang, audioPath: audioPath));
    });
    
    // Only auto-speak if explicitly requested (not on app init)
    if (audioPath == null && autoSpeak) {
      await _speak(text, lang);
    }
  }

  Future<void> _speak(String text, String lang) async {
    setState(() {
      _isSpeaking = true;
    });
    
    // Start voice animation
    _voiceAnimationController.repeat(reverse: true);
    
    await _flutterTts.setLanguage(lang);
    await _flutterTts.speak(text);
  }

  // Method to manually trigger TTS for any message
  Future<void> _speakMessage(String text, String lang) async {
    if (_isSpeaking) {
      await _flutterTts.stop();
    }
    await _speak(text, lang);
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
      String botText = "Sorry, I couldn't connect to the server.";
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
    bool available = await _speech.initialize();
    if (available) {
      setState(() => _isListening = true);
      
      // Start mic animation
      _micAnimationController.repeat(reverse: true);
      
      _speech.listen(
        onResult: (result) async {
          if (result.finalResult) {
            setState(() => _isListening = false);
            _micAnimationController.stop();
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
    _micAnimationController.stop();
    await _speech.stop();
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
            // App logo image (logo.jpeg)
            Container(
              width: 140,
              height: 40,
              margin: const EdgeInsets.only(right: 8),
              decoration: const BoxDecoration(
                shape: BoxShape.rectangle,
                color: Colors.white,
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
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.indigo.shade50,
              image: const DecorationImage(
                image: AssetImage('assets/images/background.jpg'),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(Colors.black26, BlendMode.dstATop),
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
                                  image: const DecorationImage(
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
                                                            // User voice message playback logic
                                                          }
                                                        : () async {
                                                            // Bot voice message: play only once
                                                            setState(() {
                                                              _playedBotVoiceIndices.add(index);
                                                            });
                                                          },
                                                    child: const Icon(
                                                      Icons.play_arrow,
                                                      color: Colors.deepPurpleAccent,
                                                    ),
                                                  )
                                                else
                                                  const Icon(
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
                                                  style: const TextStyle(
                                                    color: Colors.black87,
                                                    fontSize: 15,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        )
                                      : Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Flexible(
                                              child: Text(
                                                msg.text ?? "",
                                                style: TextStyle(
                                                  color: msg.isUser ? Colors.indigo.shade900 : Colors.black87,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ),
                                            // Add voice button for bot messages
                                            if (!msg.isUser && msg.text != null && msg.text!.isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets.only(left: 8.0),
                                                child: GestureDetector(
                                                  onTap: () => _speakMessage(msg.text!, msg.languageCode),
                                                  child: AnimatedBuilder(
                                                    animation: _voiceAnimation,
                                                    builder: (context, child) {
                                                      return Transform.scale(
                                                        scale: _isSpeaking ? _voiceAnimation.value : 1.0,
                                                        child: Icon(
                                                          _isSpeaking ? Icons.volume_up : Icons.volume_up_outlined,
                                                          color: Colors.indigo,
                                                          size: 20,
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ),
                                              ),
                                          ],
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
                      GestureDetector(
                        onLongPress: _startListening,
                        onLongPressUp: _stopListening,
                        child: AnimatedBuilder(
                          animation: _micAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _isListening ? _micAnimation.value : 1.0,
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
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Waveform modal overlay
          if (_showWaveformModal)
            WaveformModal(
              audioPath: _modalAudioPath ?? '',
              onClose: () {
                setState(() {
                  _showWaveformModal = false;
                  _modalAudioPath = null;
                });
              },
            ),
        ],
      ),
    );
  }
}