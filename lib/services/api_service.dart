import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // 🔥 CRITICAL FIX: Use correct base URL with /api
  static const String baseUrl = 'http://localhost:5000/api';
  
  // For real device testing, use your computer's IP:
  // static const String baseUrl = 'http://192.168.1.XXX:5000/api';
  
  final http.Client _client = http.Client();

  /// Check if backend server is healthy
  Future<Map<String, dynamic>> checkHealth() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/health'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'status': 'unhealthy',
          'error': 'HTTP ${response.statusCode}'
        };
      }
    } catch (e) {
      return {
        'status': 'unreachable',
        'error': e.toString()
      };
    }
  }

  /// Send chat message to backend
  Future<Map<String, dynamic>> sendMessage({
    required String message,
    String? sessionId,
    String inputType = 'text',
    String language = 'en',
  }) async {
    try {
      final body = {
        'message': message,
        'session_id': sessionId ?? 'default_session',
        'input_type': inputType,
        'language': language,
      };

      final response = await _client.post(
        Uri.parse('$baseUrl/chat/message'),  // ✅ FIXED: Correct endpoint
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': data['success'] ?? true,
          'message': data['message'] ?? 'No response',
          'session_id': data['session_id'] ?? sessionId,
          'language': data['language'] ?? language,
        };
      } else {
        return {
          'success': false,
          'message': 'Server error: HTTP ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection failed. Please check if backend is running.',
        'error': e.toString()
      };
    }
  }

  /// Create a session (simplified for current backend)
  Future<Map<String, dynamic>> createChatSession() async {
    return {
      'success': true,
      'session_id': 'session_${DateTime.now().millisecondsSinceEpoch}',
    };
  }

  void dispose() {
    _client.close();
  }
}
