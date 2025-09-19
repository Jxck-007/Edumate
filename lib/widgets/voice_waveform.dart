import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class VoiceWaveform extends StatefulWidget {
  final bool isListening;
  final VoidCallback onStop;

  const VoiceWaveform({
    super.key,
    required this.isListening,
    required this.onStop,
  });

  @override
  State<VoiceWaveform> createState() => _VoiceWaveformState();
}

class _VoiceWaveformState extends State<VoiceWaveform>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final List<double> _barHeights = List.generate(30, (_) => 0.0);
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    )..addListener(() {
        if (widget.isListening && mounted) {
          setState(() {
            // Update bar heights with smooth transitions
            for (int i = 0; i < _barHeights.length; i++) {
              if (_random.nextBool()) {
                _barHeights[i] = _random.nextDouble();
              }
            }
          });
        }
      });
  }

  @override
  void didUpdateWidget(VoiceWaveform oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isListening != oldWidget.isListening) {
      if (widget.isListening) {
        _animationController.repeat();
      } else {
        _animationController.stop();
        if (mounted) {
          setState(() {
            for (int i = 0; i < _barHeights.length; i++) {
              _barHeights[i] = 0.0;
            }
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onStop,
      child: Container(
        height: 100,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.mic,
                  color: widget.isListening ? AppTheme.errorColor : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  widget.isListening ? 'Listening...' : 'Stopped',
                  style: TextStyle(
                    color: widget.isListening ? AppTheme.errorColor : Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 32,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(30, (index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    width: 3,
                    height: _barHeights[index] * 32,
                    decoration: BoxDecoration(
                      color: widget.isListening
                          ? AppTheme.errorColor.withOpacity(0.5)
                          : Colors.grey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}