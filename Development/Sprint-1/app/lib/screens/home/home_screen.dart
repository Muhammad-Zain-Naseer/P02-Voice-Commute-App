import 'package:flutter/material.dart';
import 'dart:math' as math;

class VoiceInputPage extends StatefulWidget {
  const VoiceInputPage({Key? key}) : super(key: key);

  @override
  State<VoiceInputPage> createState() => _VoiceInputPageState();
}

class _VoiceInputPageState extends State<VoiceInputPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isListening = false;
  String _transcribedText = '';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleListening() {
    setState(() {
      _isListening = !_isListening;
      if (_isListening) {
        _animationController.repeat();
        // Here you would start actual voice recognition
        // For demo, we'll simulate after 2 seconds
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted && _isListening) {
            setState(() {
              _transcribedText = 'جوہر ٹاؤن سے گلبرگ';
            });
          }
        });
      } else {
        _animationController.stop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCE4EC), // Light pink background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),

            // HerSafar Logo
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.local_taxi,
                size: 40,
                color: Color(0xFFD81B60),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'HerSafar',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFFD81B60),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 40),

            // Audio Waveform Animation
            SizedBox(
              height: 80,
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: WaveformPainter(
                      animationValue: _animationController.value,
                      isListening: _isListening,
                    ),
                    size: Size(MediaQuery.of(context).size.width - 60, 80),
                  );
                },
              ),
            ),
            const SizedBox(height: 60),

            // Microphone Button Container
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFD81B60).withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Center(
                child: GestureDetector(
                  onTap: _toggleListening,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(
                        color: const Color(0xFFD81B60),
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFD81B60).withOpacity(0.2),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Icon(
                      _isListening ? Icons.mic : Icons.mic_none,
                      size: 60,
                      color: const Color(0xFFD81B60),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),

            // Divider with "یا" (or)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 1,
                      color: const Color(0xFFD81B60).withOpacity(0.3),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'یا',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFFD81B60),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 1,
                      color: const Color(0xFFD81B60).withOpacity(0.3),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Urdu Text
            const Text(
              'لوکو کر بتائیں',
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),

            // Text Input Field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  controller: TextEditingController(text: _transcribedText),
                  decoration: const InputDecoration(
                    hintText: 'جگہ کا نام لکھیں',
                    hintTextDirection: TextDirection.rtl,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(20),
                    hintStyle: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
            const Spacer(),

            // Listening Status (if active)
            if (_isListening)
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFFD81B60),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'سن رہے ہیں...',
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        color: Color(0xFFD81B60),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// Custom Painter for Waveform Animation
class WaveformPainter extends CustomPainter {
  final double animationValue;
  final bool isListening;

  WaveformPainter({
    required this.animationValue,
    required this.isListening,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD81B60)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final int barCount = 50;
    final double barWidth = size.width / barCount;
    final double centerY = size.height / 2;

    for (int i = 0; i < barCount; i++) {
      // Create different heights for bars
      final double normalizedPosition = i / barCount;
      final double wave = math.sin(
        (normalizedPosition * 4 * math.pi) + (animationValue * 2 * math.pi),
      );

      // Add some randomness
      final double randomFactor = math.sin(i * 0.5 + animationValue * 3);

      // Calculate bar height
      double barHeight = isListening
          ? (wave.abs() * 30 + 10) * (0.5 + randomFactor.abs() * 0.5)
          : 5; // Small bars when not listening

      final double x = i * barWidth + barWidth / 2;

      // Vary opacity for depth effect
      final double opacity = isListening
          ? 0.4 + (wave.abs() * 0.6)
          : 0.3;

      paint.color = Color(0xFFD81B60).withOpacity(opacity);

      // Draw the bar
      canvas.drawLine(
        Offset(x, centerY - barHeight),
        Offset(x, centerY + barHeight),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(WaveformPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.isListening != isListening;
  }
}