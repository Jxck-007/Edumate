import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // 🔥 CHANGE THIS URL TO YOUR BACKEND SERVER
  static const String _baseUrl = 'http://localhost:5000'; // Change to your Flask server URL
  static const String _chatEndpoint = '/api/chat/message';
  static const String _sessionEndpoint = '/api/chat/sessions';
  static const String _healthEndpoint = '/health';

  // For direct Rasa access (optional)
  static const String _rasaUrl = 'http://localhost:5005'; // Change to your Rasa server URL
  static const String _rasaWebhook = '/webhooks/rest/webhook';

  final http.Client _client = http.Client();

  /// Send chat message to backend
  Future<Map<String, dynamic>> sendMessage({
    required String message,
    String? sessionId,
    String? userId,
    String language = 'en',
    String inputType = 'text',
  }) async {
    try {
      final url = Uri.parse('$_baseUrl$_chatEndpoint');
      
      final body = {
        'message': message,
        'session_id': sessionId,
        'user_id': userId,
        'language': language,
        'input_type': inputType,
      };

      print('🚀 Sending to backend: $url');
      print('📤 Body: ${jsonEncode(body)}');

      final response = await _client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode}',
          'error': 'HTTP ${response.statusCode}'
        };
      }
    } catch (e) {
      print('❌ API Error: $e');
      return {
        'success': false,
        'message': 'Connection failed. Please check your internet connection.',
        'error': e.toString()
      };
    }
  }

  /// Create new chat session
  Future<Map<String, dynamic>> createChatSession({
    String? userId,
    String language = 'en',
    String? title,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl$_sessionEndpoint');
      
      final body = {
        'user_id': userId,
        'language': language,
        'title': title ?? 'New Chat',
      };

      final response = await _client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to create session: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Session creation error: $e');
      return {
        'success': true,
        'session': {
          'id': 'fallback_${DateTime.now().millisecondsSinceEpoch}',
          'title': 'Local Session',
        }
      };
    }
  }

  /// Get chat history for a session
  Future<Map<String, dynamic>> getChatHistory({
    required String sessionId,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl$_sessionEndpoint/$sessionId/history?page=$page&per_page=$perPage');
      
      final response = await _client.get(url);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get history: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ History fetch error: $e');
      return {
        'success': false,
        'error': e.toString(),
        'messages': []
      };
    }
  }

  /// Check backend health
  Future<Map<String, dynamic>> checkHealth() async {
    try {
      final url = Uri.parse('$_baseUrl$_healthEndpoint');
      
      final response = await _client.get(url);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Health check failed: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Health check error: $e');
      return {
        'status': 'unhealthy',
        'error': e.toString()
      };
    }
  }

  /// Direct Rasa API call (fallback method)
  Future<Map<String, dynamic>> sendToRasaDirectly({
    required String message,
    required String senderId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final url = Uri.parse('$_rasaUrl$_rasaWebhook');
      
      final body = {
        'sender': senderId,
        'message': message,
        if (metadata != null) 'metadata': metadata,
      };

      print('🤖 Sending directly to Rasa: $url');
      print('📤 Body: ${jsonEncode(body)}');

      final response = await _client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      print('🤖 Rasa response status: ${response.statusCode}');
      print('🤖 Rasa response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        
        if (data.isNotEmpty) {
          return {
            'success': true,
            'message': data[0]['text'] ?? 'No response text',
            'buttons': data[0]['buttons'] ?? [],
            'images': data[0]['image'] != null ? [data[0]['image']] : [],
          };
        } else {
          return {
            'success': false,
            'message': 'No response from Rasa',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Rasa server error: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('❌ Rasa direct error: $e');
      return {
        'success': false,
        'message': 'Failed to connect to Rasa server',
        'error': e.toString()
      };
    }
  }

  /// Check if message is college-related (client-side validation)
  bool isCollegeRelated(String message) {
    final keywords = [
      'college', 'university', 'course', 'degree', 'admission', 'fees', 'scholarship',
      'hostel', 'placement', 'exam', 'result', 'timetable', 'faculty', 'professor',
      'department', 'semester', 'syllabus', 'assignment', 'project', 'lab',
      'library', 'canteen', 'sports', 'event', 'club', 'society', 'student',
      'education', 'academic', 'study', 'learning', 'class', 'lecture',
      'engineering', 'medical', 'arts', 'science', 'commerce', 'management',
      'attendance', 'marks', 'grade', 'cgpa', 'gpa', 'transcript'
    ];
    
    final messageLower = message.toLowerCase();
    return keywords.any((keyword) => messageLower.contains(keyword));
  }

  void dispose() {
    _client.close();
  }
}

/// Configuration class for easy URL management
class ApiConfig {
  // 🔥 UPDATE THESE URLS FOR YOUR TEAM
  
  // Backend URLs
  static const String flaskUrl = 'http://localhost:5000';           // Local Flask
  // static const String flaskUrl = 'https://your-app.herokuapp.com';  // Heroku
  // static const String flaskUrl = 'http://192.168.1.100:5000';      // Network IP
  // static const String flaskUrl = 'https://abc123.ngrok.io';        // ngrok tunnel
  
  // Rasa URLs  
  static const String rasaUrl = 'http://localhost:5005';            // Local Rasa
  // static const String rasaUrl = 'http://192.168.1.100:5005';       // Network IP
  // static const String rasaUrl = 'https://xyz789.ngrok.io';         // ngrok tunnel
  
  // Endpoints
  static const String chatEndpoint = '/api/chat/message';
  static const String sessionEndpoint = '/api/chat/sessions';
  static const String healthEndpoint = '/health';
  static const String rasaWebhook = '/webhooks/rest/webhook';
  
  // Timeouts
  static const Duration requestTimeout = Duration(seconds: 30);
  static const Duration connectionTimeout = Duration(seconds: 10);
}