import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/chat_message.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/connection_status.dart';
import '../widgets/quick_actions.dart';
import '../widgets/voice_waveform.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final FlutterTts _flutterTts = FlutterTts();
  final ApiService _apiService = ApiService();
  late stt.SpeechToText _speech;
  
  String? _currentSessionId;
  String? _currentSpeakingMessageId;
  ConnectivityResult? _connectivityResult;
  bool _isListening = false;
  bool _hasText = false;
  bool _isConnectedToBackend = false;
  bool _showVoiceInput = false;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _checkConnectivity();
    _addWelcomeMessage();
  }

  Future<void> _initializeServices() async {
    _speech = stt.SpeechToText();
    
    // Initialize TTS
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
    
    // TTS completion handler
    _flutterTts.setCompletionHandler(() {
      setState(() {
        _currentSpeakingMessageId = null;
      });
    });
    
    // Request microphone permission
    await Permission.microphone.request();
    
    // Create initial chat session
    await _createChatSession();
  }

  Future<void> _checkConnectivity() async {
    final connectivity = Connectivity();
    _connectivityResult = await connectivity.checkConnectivity();
    
    // Listen for connectivity changes
    connectivity.onConnectivityChanged.listen((result) {
      setState(() {
        _connectivityResult = result;
        if (result != ConnectivityResult.none) {
          _createChatSession();
        }
      });
    });
  }

  Future<void> _createChatSession() async {
    try {
      final session = await _apiService.createChatSession();
      setState(() {
        _currentSessionId = session['session']['id'];
        _isConnectedToBackend = true;
      });
    } catch (e) {
      print('Failed to create chat session: $e');
      setState(() {
        _isConnectedToBackend = false;
      });
    }
  }

  void _addWelcomeMessage() {
    setState(() {
      _messages.add(ChatMessage(
        id: 'welcome_${DateTime.now().millisecondsSinceEpoch}',
        text: 'Hello! I\'m Edumate, your college assistant. How can I help you today?',
        isUser: false,
        languageCode: 'en',
        inputType: 'text',
        timestamp: DateTime.now(),
      ));
    });
  }

  void _handleTextInput() {
    if (_textController.text.trim().isEmpty) return;
    
    final userMessage = _textController.text.trim();
    _sendMessage(userMessage, 'text');
    _textController.clear();
    setState(() {
      _hasText = false;
    });
  }

  Future<void> _handleVoiceInput() async {
    if (!_isListening) {
      setState(() {
        _showVoiceInput = true;
      });
      await _startListening();
    } else {
      await _stopListening();
      setState(() {
        _showVoiceInput = false;
      });
    }
  }

  Future<void> _startListening() async {
    bool available = await _speech.initialize(
      onStatus: (status) {
        print('Speech status: $status');
        if (status == 'done' || status == 'notListening') {
          _stopListening();
        }
      },
      onError: (error) {
        print('Speech error: $error');
        _stopListening();
      },
    );
    
    if (available) {
      setState(() {
        _isListening = true;
      });
      
      await _speech.listen(
        onResult: (result) {
          if (result.finalResult) {
            _handleVoiceResult(result.recognizedWords);
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
      );
    }
  }

  Future<void> _stopListening() async {
    await _speech.stop();
    setState(() {
      _isListening = false;
    });
  }

  void _handleVoiceResult(String recognizedWords) {
    if (recognizedWords.trim().isEmpty) return;
    _sendMessage(recognizedWords, 'voice');
  }

  Future<void> _sendMessage(String message, String inputType) async {
    // Add user message immediately
    final userMessage = ChatMessage(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      text: message,
      isUser: true,
      languageCode: 'auto',
      inputType: inputType,
      timestamp: DateTime.now(),
    );
    
    setState(() {
      _messages.add(userMessage);
      _showVoiceInput = false;
    });

    try {
      final response = await _apiService.sendMessage(
        message: message,
        sessionId: _currentSessionId,
        inputType: inputType,
        language: 'auto',
      );

      if (response['success'] == true) {
        final botMessage = ChatMessage(
          id: 'bot_${DateTime.now().millisecondsSinceEpoch}',
          text: response['message'],
          isUser: false,
          languageCode: response['language'] ?? 'en',
          inputType: 'text',
          timestamp: DateTime.now(),
          intent: response['intent'],
          confidence: response['confidence']?.toDouble(),
        );

        setState(() {
          _messages.add(botMessage);
          _isConnectedToBackend = true;
        });

        if (inputType == 'voice') {
          _speakMessage(response['message'], response['language'] ?? 'en', botMessage.id);
        }
      } else {
        _addErrorMessage(response['message'] ?? 'Something went wrong');
      }
    } catch (e) {
      print('Error sending message: $e');
      _addErrorMessage('Failed to send message. Please check your connection and try again.');
      setState(() {
        _isConnectedToBackend = false;
      });
    }
  }

  void _addErrorMessage(String errorText) {
    final errorMessage = ChatMessage(
      id: 'error_${DateTime.now().millisecondsSinceEpoch}',
      text: errorText,
      isUser: false,
      languageCode: 'en',
      inputType: 'text',
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(errorMessage);
    });
  }

  Future<void> _speakMessage(String text, String language, String messageId) async {
    await _flutterTts.stop();
    
    setState(() {
      _currentSpeakingMessageId = messageId;
    });
    
    await _flutterTts.setLanguage(language);
    await _flutterTts.speak(text);
  }

  Future<void> _stopSpeaking() async {
    await _flutterTts.stop();
    setState(() {
      _currentSpeakingMessageId = null;
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _flutterTts.stop();
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // App Bar with gradient background
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: AppTheme.backgroundGradient,
            ),
          ),
        ),
        title: Row(
          children: [
            Hero(
              tag: 'edumate_logo',
              child: Container(
                width: 32,
                height: 32,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Image.asset('assets/images/logo.jpeg'),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Edumate Chat',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _createChatSession,
            tooltip: 'New Chat Session',
          ),
        ],
      ),
      
      // Main body
      body: Stack(
        children: [
          // Background image with gradient overlay
          Image.asset(
            'assets/images/background.jpg',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withOpacity(0.9),
                  Colors.white.withOpacity(0.8),
                  Colors.white.withOpacity(0.7),
                ],
              ),
            ),
          ),
          
          // Chat interface
          Column(
            children: [
              // Connection status
              ConnectionStatus(
                connectivityResult: _connectivityResult,
                isConnectedToBackend: _isConnectedToBackend,
                onRetry: _createChatSession,
              ),
              
              // Quick actions
              if (_messages.length <= 3) ...[
                QuickActions(
                  onActionSelected: (query) => _sendMessage(query, 'text'),
                ),
              ],
              
              // Chat messages
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    return ChatBubble(
                      message: message,
                      isSpeaking: _currentSpeakingMessageId == message.id,
                      onPlay: () {
                        if (_currentSpeakingMessageId == message.id) {
                          _stopSpeaking();
                        } else {
                          _speakMessage(
                            message.text!,
                            message.languageCode,
                            message.id,
                          );
                        }
                      },
                    );
                  },
                ),
              ),
              
              // Voice input overlay
              if (_showVoiceInput)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: VoiceWaveform(
                    isListening: _isListening,
                    onStop: _stopListening,
                  ),
                ),
              
              // Input area
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      offset: const Offset(0, -1),
                      blurRadius: 4,
                      color: Colors.black12,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Voice input button
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isListening
                            ? AppTheme.errorColor
                            : AppTheme.primaryColor,
                      ),
                      child: IconButton(
                        icon: Icon(
                          _isListening ? Icons.mic : Icons.mic_none,
                          color: Colors.white,
                        ),
                        onPressed: _handleVoiceInput,
                      ),
                    ).animate(target: _isListening ? 1 : 0)
                      .scale(duration: AppTheme.quickAnimation),
                    
                    const SizedBox(width: 12),
                    
                    // Text input
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        decoration: InputDecoration(
                          hintText: _isListening
                              ? 'Listening...'
                              : 'Type your message...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        enabled: !_isListening,
                        onChanged: (val) {
                          setState(() {
                            _hasText = val.trim().isNotEmpty;
                          });
                        },
                        onSubmitted: (_) => _handleTextInput(),
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // Send button
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _hasText
                            ? AppTheme.primaryColor
                            : Colors.grey.shade300,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.send, color: Colors.white),
                        onPressed: _hasText ? _handleTextInput : null,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}