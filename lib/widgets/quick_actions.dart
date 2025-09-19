import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

class QuickActions extends StatelessWidget {
  final Function(String) onActionSelected;

  const QuickActions({
    super.key,
    required this.onActionSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: _buildQuickActions()
            .animate(interval: const Duration(milliseconds: 50))
            .fadeIn()
            .slideX(begin: -0.2, end: 0),
      ),
    );
  }

  List<Widget> _buildQuickActions() {
    final actions = [
      {
        'icon': Icons.school,
        'label': 'Course Information',
        'query': 'Tell me about available courses',
      },
      {
        'icon': Icons.event,
        'label': 'Academic Calendar',
        'query': 'Show me the academic calendar',
      },
      {
        'icon': Icons.library_books,
        'label': 'Library Hours',
        'query': 'What are the library hours?',
      },
      {
        'icon': Icons.sports,
        'label': 'Campus Activities',
        'query': 'What activities are available on campus?',
      },
      {
        'icon': Icons.restaurant,
        'label': 'Dining Options',
        'query': 'What dining options are available?',
      },
    ];

    return actions.map((action) {
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ActionChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                action['icon'] as IconData,
                size: 16,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 4),
              Text(
                action['label'] as String,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
          backgroundColor: Colors.white,
          side: BorderSide(
            color: AppTheme.primaryColor.withOpacity(0.2),
          ),
          shadowColor: Colors.transparent,
          onPressed: () => onActionSelected(action['query'] as String),
        ),
      );
    }).toList();
  }
}