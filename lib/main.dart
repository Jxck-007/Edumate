import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

void main() {
  runApp(const EdumateApp());
}

class EdumateApp extends StatelessWidget {
  const EdumateApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Edumate - College Assistant',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  
  // Services
  late FlutterTts _flutterTts;
  late SpeechToText _speech;
  
  // Animation Controllers
  late AnimationController _speakingController;
  
  // State
  bool _isLoading = false;
  bool _isListening = false;
  bool _isSpeaking = false;
  bool _backendConnected = false;
  String _selectedLanguage = 'en';
  bool _speechEnabled = false;
  String _lastWords = '';
  Timer? _connectionTimer;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _setupAnimations();
    _startConnectionMonitoring();
    _addWelcomeMessage();
  }

  void _setupAnimations() {
    _speakingController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
  }

  void _initializeServices() async {
    _flutterTts = FlutterTts();
    await _flutterTts.setLanguage(_selectedLanguage);
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setPitch(1.0);
    
    // Set TTS callbacks - NO auto-activation
    _flutterTts.setStartHandler(() {
      if (mounted) {
        setState(() {
          _isSpeaking = true;
        });
        _speakingController.repeat();
      }
    });
    
    _flutterTts.setCompletionHandler(() {
      if (mounted) {
        setState(() {
          _isSpeaking = false;
        });
        _speakingController.stop();
        _speakingController.reset();
      }
    });
    
    _speech = SpeechToText();
    _speechEnabled = await _speech.initialize();
    await Permission.microphone.request();
  }

  void _addWelcomeMessage() {
    final welcomeMessage = ChatMessage(
      id: 'welcome',
      text: "Hello! I'm Edumate, your college assistant. How can I help you today?",
      isUser: false,
      timestamp: DateTime.now(),
    );
    
    setState(() {
      _messages.add(welcomeMessage);
    });
  }

  void _startConnectionMonitoring() {
    _checkBackendConnection();
    _connectionTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkBackendConnection();
    });
  }

  Future<void> _checkBackendConnection() async {
    try {
      // Check backend health which includes Rasa status
      final response = await http.get(
        Uri.parse('http://localhost:5000/api/health'),
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _backendConnected = data['rasa_connected'] ?? false;
        });
      } else {
        setState(() {
          _backendConnected = false;
        });
      }
    } catch (e) {
      setState(() {
        _backendConnected = false;
      });
    }
  }

  void _sendMessage({String? messageText}) async {
    final text = messageText ?? _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();

    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
    });

    _scrollToBottom();

    try {
      // Send to backend which forwards to Rasa
      final response = await http.post(
        Uri.parse('http://localhost:5000/api/chat/message'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message': text,
          'session_id': 'user_session',
          'language': _selectedLanguage,
          'input_type': messageText != null ? 'voice' : 'text',
        }),
      ).timeout(const Duration(seconds: 15));

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true) {
          final botMessage = ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            text: data['message'] ?? 'Sorry, I didn\'t understand that.',
            isUser: false,
            timestamp: DateTime.now(),
          );

          setState(() {
            _messages.add(botMessage);
          });

          // Auto-speak response ONLY if message was from voice
          if (messageText != null && botMessage.text.isNotEmpty) {
            _speak(botMessage.text);
          }
        } else {
          _addErrorMessage(data['message'] ?? 'Failed to get response from AI');
        }
      } else {
        _addErrorMessage('Server error. Please try again.');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _addErrorMessage('Connection failed. Please make sure Rasa server is running.');
    }

    _scrollToBottom();
  }

  void _addErrorMessage(String error) {
    final errorMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: error,
      isUser: false,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(errorMessage);
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _startListening() async {
    if (!_speechEnabled) return;

    setState(() {
      _isListening = true;
      _lastWords = '';
    });

    await _speech.listen(
      onResult: (result) {
        setState(() {
          _lastWords = result.recognizedWords;
        });
        
        if (result.finalResult) {
          setState(() {
            _isListening = false;
          });
          if (_lastWords.isNotEmpty) {
            _sendMessage(messageText: _lastWords);
          }
        }
      },
      listenFor: const Duration(seconds: 10),
      partialResults: true,
      localeId: _selectedLanguage,
    );
  }

  void _stopListening() async {
    await _speech.stop();
    setState(() {
      _isListening = false;
    });
  }

  void _speak(String text) async {
    if (text.isNotEmpty) {
      await _flutterTts.speak(text);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _speakingController.dispose();
    _connectionTimer?.cancel();
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade600, Colors.blue.shade700],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Logo
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.school,
                        color: Colors.blue,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Title
                    const Expanded(
                      child: Text(
                        'Edumate',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    
                    // Status - Shows Rasa Connection
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _backendConnected ? Colors.green : Colors.red,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _backendConnected ? 'Online' : 'Offline',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                        if (!_backendConnected) ...[
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: _checkBackendConnection,
                            child: const Icon(
                              Icons.refresh,
                              color: Colors.white70,
                              size: 16,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isLoading) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.school,
                            color: Colors.blue,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Text(
                            'Thinking...',
                            style: TextStyle(
                              color: Colors.grey,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final message = _messages[index];
                return MessageBubble(message: message);
              },
            ),
          ),

          // Input Area
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              children: [
                // Text Input
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: _isListening 
                            ? 'Listening: ${_lastWords.isEmpty ? "Speak now..." : _lastWords}'
                            : 'Ask about college...',
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                      enabled: !_isListening && !_isLoading,
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Voice Button with Perplexity Animation
                GestureDetector(
                  onTap: _isListening ? _stopListening : _startListening,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _isListening ? Colors.red : Colors.orange,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          _isListening ? Icons.stop : Icons.mic,
                          color: Colors.white,
                          size: 24,
                        ),
                        // Perplexity-style animation when speaking
                        if (_isSpeaking)
                          AnimatedBuilder(
                            animation: _speakingController,
                            builder: (context, child) {
                              return Container(
                                width: 48 + (12 * _speakingController.value),
                                height: 48 + (12 * _speakingController.value),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(
                                    0.3 * (1 - _speakingController.value),
                                  ),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(width: 8),
                
                // Send Button
                GestureDetector(
                  onTap: _isLoading || _isListening ? null : () => _sendMessage(),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _isLoading || _isListening 
                          ? Colors.grey.shade400 
                          : Colors.green,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(
                      Icons.send,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const MessageBubble({
    Key? key,
    required this.message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.school,
                color: Colors.blue,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
          ],
          
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: isUser 
                    ? LinearGradient(
                        colors: [Colors.blue.shade500, Colors.blue.shade600],
                      )
                    : null,
                color: isUser ? null : Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: isUser ? Colors.white : Colors.black87,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ),
          ),
          
          if (isUser) ...[
            const SizedBox(width: 12),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.person,
                color: Colors.blue.shade600,
                size: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}