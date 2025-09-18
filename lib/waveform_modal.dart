import 'package:flutter/material.dart';

class WaveformModal extends StatefulWidget {
  final String audioPath;
  final VoidCallback onClose;

  const WaveformModal({required this.audioPath, required this.onClose, Key? key}) : super(key: key);

  @override
  State<WaveformModal> createState() => _WaveformModalState();
}

class _WaveformModalState extends State<WaveformModal> with TickerProviderStateMixin {
  late AnimationController _waveAnimationController;
  late List<AnimationController> _barControllers;
  late List<Animation<double>> _barAnimations;

  @override
  void initState() {
    super.initState();
    
    // Initialize wave animation controller
    _waveAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    // Create individual controllers for each waveform bar
    _barControllers = List.generate(
      10, // Number of bars in waveform
      (index) => AnimationController(
        duration: Duration(milliseconds: 800 + (index * 100)), // Staggered timing
        vsync: this,
      ),
    );
    
    // Create animations for each bar
    _barAnimations = _barControllers.map((controller) {
      return Tween<double>(begin: 0.2, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      );
    }).toList();
    
    // Start the animation
    _startWaveAnimation();
  }

  void _startWaveAnimation() {
    // Start all bar animations with slight delays
    for (int i = 0; i < _barControllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 50), () {
        if (mounted) {
          _barControllers[i].repeat(reverse: true);
        }
      });
    }
  }

  void _stopWaveAnimation() {
    for (var controller in _barControllers) {
      controller.stop();
    }
  }

  @override
  void dispose() {
    _waveAnimationController.dispose();
    for (var controller in _barControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: widget.onClose,
            child: Container(
              color: Colors.black.withOpacity(0.4),
            ),
          ),
        ),
        Center(
          child: Container(
            width: 340,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Voice Message",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 20),
                Container(
                  width: 300,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.indigo.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: List.generate(10, (index) {
                      return AnimatedBuilder(
                        animation: _barAnimations[index],
                        builder: (context, child) {
                          return Container(
                            width: 4,
                            height: 60 * _barAnimations[index].value,
                            decoration: BoxDecoration(
                              color: Colors.indigo.shade400,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          );
                        },
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.play_arrow),
                      label: const Text("Play"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        // Play audio logic here
                        _startWaveAnimation();
                      },
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.pause),
                      label: const Text("Pause"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        // Pause audio logic here
                        _stopWaveAnimation();
                      },
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.close),
                      label: const Text("Close"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        _stopWaveAnimation();
                        widget.onClose();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}