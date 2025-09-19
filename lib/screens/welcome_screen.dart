import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import 'chat_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image with Gradient Overlay
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
                  Colors.black.withOpacity(0.7),
                  Colors.black.withOpacity(0.5),
                  Colors.black.withOpacity(0.3),
                ],
              ),
            ),
          ),
          
          // Content
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                
                // Logo and Title
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Image.asset(
                      'assets/images/logo.jpeg',
                      fit: BoxFit.contain,
                    ),
                  ),
                ).animate()
                  .fadeIn(duration: AppTheme.slowAnimation)
                  .scale(delay: AppTheme.quickAnimation),
                
                const SizedBox(height: 24),
                
                Text(
                  'Welcome to Edumate',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ).animate()
                  .fadeIn(delay: AppTheme.quickAnimation)
                  .moveY(begin: 20, end: 0),
                
                const SizedBox(height: 12),
                
                Text(
                  'Your Intelligent College Assistant',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                  textAlign: TextAlign.center,
                ).animate()
                  .fadeIn(delay: AppTheme.normalAnimation)
                  .moveY(begin: 20, end: 0),
                
                const SizedBox(height: 48),
                
                // Feature List
                ..._buildFeatureList(context).animate(
                  interval: Duration(milliseconds: 100),
                ).fadeIn(delay: AppTheme.normalAnimation)
                  .moveX(begin: -30, end: 0),
                
                const Spacer(),
                
                // Start Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const ChatScreen()),
                    ),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                      backgroundColor: AppTheme.primaryColor,
                    ),
                    child: const Text(
                      'Start Chatting',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ).animate()
                  .fadeIn(delay: AppTheme.slowAnimation)
                  .moveY(begin: 50, end: 0),
                
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFeatureList(BuildContext context) {
    final features = [
      {'icon': Icons.chat_bubble_outline, 'text': 'Instant Academic Support'},
      {'icon': Icons.language, 'text': 'Multi-language Support'},
      {'icon': Icons.mic, 'text': 'Voice Interaction'},
      {'icon': Icons.school, 'text': 'College Resources'},
    ];

    return features.map((feature) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                feature['icon'] as IconData,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              feature['text'] as String,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}