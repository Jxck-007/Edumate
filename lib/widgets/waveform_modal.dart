import 'package:flutter/material.dart';

class WaveformModal extends StatelessWidget {
  final String? audioPath;
  final bool isPlaying;
  final VoidCallback? onPlay;
  final VoidCallback? onClose;

  const WaveformModal({
    Key? key,
    this.audioPath,
    this.isPlaying = false,
    this.onPlay,
    this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Audio Message',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: onClose,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Placeholder for waveform visualization
          Container(
            height: 64,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 16),
          IconButton(
            icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
            onPressed: onPlay,
            iconSize: 32,
          ),
        ],
      ),
    );
  }
}