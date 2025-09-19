import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/chat_message.dart';
import '../theme/app_theme.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback onPlay;
  final bool isSpeaking;

  const ChatBubble({
    super.key,
    required this.message,
    required this.onPlay,
    this.isSpeaking = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: 
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            // Bot avatar
            CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.primaryColor,
              child: const Icon(Icons.smart_toy, color: Colors.white, size: 16),
            ).animate()
              .scale(duration: AppTheme.quickAnimation, curve: Curves.elasticOut)
              .fadeIn(),
            const SizedBox(width: 8),
          ],
          
          // Message content
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              padding: const EdgeInsets.all(12),
              decoration: message.isUser 
                  ? AppTheme.userMessageDecoration
                  : AppTheme.botMessageDecoration,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Message text
                  Text(
                    message.text ?? '',
                    style: TextStyle(
                      color: message.isUser ? Colors.white : AppTheme.primaryTextColor,
                      fontSize: 16,
                    ),
                  ),
                  
                  // Metadata and controls for bot messages
                  if (!message.isUser) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Input type indicator
                        Icon(
                          message.inputType == 'voice' 
                              ? Icons.keyboard_voice 
                              : Icons.keyboard,
                          size: 12,
                          color: AppTheme.secondaryTextColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          message.inputType == 'voice' 
                              ? 'Voice response' 
                              : 'Text response',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppTheme.secondaryTextColor,
                          ),
                        ),
                        
                        if (message.intent != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            '${message.intent} (${(message.confidence ?? 0 * 100).toInt()}%)',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppTheme.secondaryTextColor,
                            ),
                          ),
                        ],
                        
                        const Spacer(),
                        
                        // Audio control button
                        GestureDetector(
                          onTap: onPlay,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSpeaking 
                                  ? AppTheme.errorColor.withOpacity(0.1)
                                  : AppTheme.primaryColor.withOpacity(0.1),
                            ),
                            child: Icon(
                              isSpeaking ? Icons.stop : Icons.volume_up,
                              size: 16,
                              color: isSpeaking 
                                  ? AppTheme.errorColor
                                  : AppTheme.primaryColor,
                            ),
                          ),
                        ).animate(target: isSpeaking ? 1 : 0)
                          .scale(duration: AppTheme.quickAnimation, curve: Curves.easeInOut),
                      ],
                    ),
                  ],
                ],
              ),
            ).animate()
              .slideX(
                begin: message.isUser ? 0.3 : -0.3,
                end: 0,
                duration: AppTheme.normalAnimation,
                curve: Curves.easeOutQuad,
              )
              .fadeIn(),
          ),
          
          if (message.isUser) ...[
            const SizedBox(width: 8),
            // User avatar
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey,
              child: const Icon(Icons.person, color: Colors.white, size: 16),
            ).animate()
              .scale(duration: AppTheme.quickAnimation, curve: Curves.elasticOut)
              .fadeIn(),
          ],
        ],
      ),
    );
  }
}