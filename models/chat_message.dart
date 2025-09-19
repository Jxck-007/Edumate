class ChatMessage {
  final String id;
  final String? text;
  final bool isUser;
  final String languageCode;
  final String inputType;
  final String? audioPath;
  final DateTime timestamp;
  final String? intent;
  final double? confidence;
  final String? sessionId;
  final int? responseTimeMs;

  ChatMessage({
    required this.id,
    this.text,
    required this.isUser,
    required this.languageCode,
    required this.inputType,
    this.audioPath,
    required this.timestamp,
    this.intent,
    this.confidence,
    this.sessionId,
    this.responseTimeMs,
  });

  /// Create ChatMessage from API response
  factory ChatMessage.fromApi(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      text: json['message'] ?? json['text'],
      isUser: json['is_user_message'] ?? false,
      languageCode: json['language'] ?? json['language_detected'] ?? 'en',
      inputType: json['input_type'] ?? 'text',
      audioPath: json['audio_path'],
      timestamp: json['created_at'] != null 
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      intent: json['intent'] ?? json['rasa_intent'],
      confidence: json['confidence']?.toDouble() ?? json['rasa_confidence']?.toDouble(),
      sessionId: json['session_id'],
      responseTimeMs: json['response_time_ms'],
    );
  }

  /// Create ChatMessage for user input
  factory ChatMessage.userMessage({
    required String text,
    required String inputType,
    String languageCode = 'auto',
    String? sessionId,
    String? audioPath,
  }) {
    return ChatMessage(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      text: text,
      isUser: true,
      languageCode: languageCode,
      inputType: inputType,
      timestamp: DateTime.now(),
      sessionId: sessionId,
      audioPath: audioPath,
    );
  }

  /// Create ChatMessage for bot response
  factory ChatMessage.botMessage({
    required String text,
    required String languageCode,
    required String inputType,
    String? sessionId,
    String? intent,
    double? confidence,
    int? responseTimeMs,
  }) {
    return ChatMessage(
      id: 'bot_${DateTime.now().millisecondsSinceEpoch}',
      text: text,
      isUser: false,
      languageCode: languageCode,
      inputType: inputType,
      timestamp: DateTime.now(),
      sessionId: sessionId,
      intent: intent,
      confidence: confidence,
      responseTimeMs: responseTimeMs,
    );
  }

  /// Create ChatMessage for error
  factory ChatMessage.error({
    required String errorMessage,
    String languageCode = 'en',
  }) {
    return ChatMessage(
      id: 'error_${DateTime.now().millisecondsSinceEpoch}',
      text: errorMessage,
      isUser: false,
      languageCode: languageCode,
      inputType: 'text',
      timestamp: DateTime.now(),
    );
  }

  /// Convert to JSON for storage/API
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'is_user_message': isUser,
      'language_code': languageCode,
      'input_type': inputType,
      'audio_path': audioPath,
      'timestamp': timestamp.toIso8601String(),
      'intent': intent,
      'confidence': confidence,
      'session_id': sessionId,
      'response_time_ms': responseTimeMs,
    };
  }

  /// Get formatted timestamp
  String get formattedTime {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    
    if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  /// Get confidence percentage
  String get confidencePercentage {
    if (confidence == null) return '';
    return '${(confidence! * 100).toInt()}%';
  }

  /// Check if message is recent (less than 1 minute)
  bool get isRecent {
    return DateTime.now().difference(timestamp).inMinutes < 1;
  }

  /// Check if message has audio
  bool get hasAudio {
    return audioPath != null && audioPath!.isNotEmpty;
  }

  /// Copy with updated fields
  ChatMessage copyWith({
    String? id,
    String? text,
    bool? isUser,
    String? languageCode,
    String? inputType,
    String? audioPath,
    DateTime? timestamp,
    String? intent,
    double? confidence,
    String? sessionId,
    int? responseTimeMs,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      languageCode: languageCode ?? this.languageCode,
      inputType: inputType ?? this.inputType,
      audioPath: audioPath ?? this.audioPath,
      timestamp: timestamp ?? this.timestamp,
      intent: intent ?? this.intent,
      confidence: confidence ?? this.confidence,
      sessionId: sessionId ?? this.sessionId,
      responseTimeMs: responseTimeMs ?? this.responseTimeMs,
    );
  }

  @override
  String toString() {
    return 'ChatMessage(id: $id, text: $text, isUser: $isUser, inputType: $inputType)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatMessage && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Chat session model
class ChatSession {
  final String id;
  final String? userId;
  final String? title;
  final String language;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int messageCount;

  ChatSession({
    required this.id,
    this.userId,
    this.title,
    required this.language,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.messageCount = 0,
  });

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      id: json['id'],
      userId: json['user_id'],
      title: json['session_title'] ?? json['title'],
      language: json['language'] ?? 'en',
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      messageCount: json['message_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'language': language,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'message_count': messageCount,
    };
  }

  String get displayTitle {
    return title ?? 'Chat Session';
  }

  String get formattedDate {
    final now = DateTime.now();
    final diff = now.difference(updatedAt);
    
    if (diff.inDays == 0) {
      return 'Today';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${updatedAt.day}/${updatedAt.month}/${updatedAt.year}';
    }
  }
}

/// API Response model
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final String? error;
  final int? statusCode;

  ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.error,
    this.statusCode,
  });

  factory ApiResponse.success(T data, {String? message}) {
    return ApiResponse(
      success: true,
      data: data,
      message: message,
    );
  }

  factory ApiResponse.error(String error, {int? statusCode}) {
    return ApiResponse(
      success: false,
      error: error,
      statusCode: statusCode,
    );
  }

  factory ApiResponse.fromJson(Map<String, dynamic> json, T Function(dynamic) fromJson) {
    return ApiResponse(
      success: json['success'] ?? false,
      data: json['data'] != null ? fromJson(json['data']) : null,
      message: json['message'],
      error: json['error'],
      statusCode: json['status_code'],
    );
  }
}