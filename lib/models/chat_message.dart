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
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      text: json['text'],
      isUser: json['is_user_message'] ?? false,
      languageCode: json['language_detected'] ?? 'en',
      inputType: json['input_type'] ?? 'text',
      audioPath: json['audio_path'],
      timestamp: json['created_at'] != null 
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      intent: json['rasa_intent'],
      confidence: json['rasa_confidence']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'is_user_message': isUser,
      'language_detected': languageCode,
      'input_type': inputType,
      'audio_path': audioPath,
      'created_at': timestamp.toIso8601String(),
      'rasa_intent': intent,
      'rasa_confidence': confidence,
    };
  }
}