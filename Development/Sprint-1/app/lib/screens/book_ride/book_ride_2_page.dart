import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:math' as math;

class BookRide2Page extends StatefulWidget {
  const BookRide2Page({super.key});

  @override
  State<BookRide2Page> createState() => _BookRide2PageState();
}

class _BookRide2PageState extends State<BookRide2Page>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final TextEditingController _locationController = TextEditingController();
  bool _isListening = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    // Simulate voice input after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _isListening) {
        setState(() {
          _locationController.text = 'جوہر ٹاؤن سے گلبرگ';
          _isListening = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _stopListening() {
    setState(() {
      _isListening = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCE4EC), // Light pink background
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                
                
                const SizedBox(height: 40),
                // Car icon with HerSafar text
                Column(
                  children: [
                    SvgPicture.asset(
                      'assets/icons/car_icon.svg',
                      width: 120,
                      height: 100,
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                // Circular wave animation
                SizedBox(
                  height: 150,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _animationController,
                        builder: (context, child) {
                          return CustomPaint(
                            painter: CircularWavePainter(
                              animation: _animationController.value,
                            ),
                            size: const Size(150, 150),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                // Waveform with stop button container
                Container(
                  width: double.infinity,
                  height: 300,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.pink[200]!,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Waveform
                      SizedBox(
                        height: 120,
                        width: double.infinity,
                        child: AnimatedBuilder(
                          animation: _animationController,
                          builder: (context, child) {
                            return CustomPaint(
                              painter: HorizontalWaveformPainter(
                                animation: _animationController.value,
                                isListening: _isListening,
                              ),
                              size: const Size(double.infinity, 120),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 30),
                      // Stop button
                      GestureDetector(
                        onTap: _stopListening,
                        child: SvgPicture.asset(
                          'assets/icons/stop_icon.svg',
                          width: 60,
                          height: 60,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                // "OR" divider in Urdu
                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: Colors.grey[400],
                        thickness: 1,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        'یا',
                        style: TextStyle(
                          fontSize: 24,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: Colors.grey[400],
                        thickness: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                // Text heading in Urdu
                Text(
                  'لکھ کر بتائیں',
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontSize: 28,
                    color: Colors.grey[800],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                // Text input field with location icon
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.pink[200]!,
                      width: 2,
                    ),
                  ),
                  child: TextField(
                    controller: _locationController,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                    decoration: InputDecoration(
                      hintText: 'جگہ کا نام لکھیں',
                      hintTextDirection: TextDirection.rtl,
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 16,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      suffixIcon: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: SvgPicture.asset(
                          'assets/icons/location_pin.svg',
                          width: 24,
                          height: 24,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CircularWavePainter extends CustomPainter {
  final double animation;

  CircularWavePainter({
    required this.animation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Draw multiple circular waves
    for (int i = 0; i < 8; i++) {
      final path = Path();
      const points = 100;

      for (int j = 0; j <= points; j++) {
        final angle = (j / points) * 2 * math.pi;
        final waveOffset = math.sin((j / points * 8 * math.pi) + (animation * math.pi * 2 + i * 0.3));
        final r = radius * 0.6 + waveOffset * 8;

        final x = center.dx + r * math.cos(angle);
        final y = center.dy + r * math.sin(angle);

        if (j == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }

      path.close();

      // Gradient color effect
      final colorT = (i / 8 + animation) % 1.0;
      paint.color = Color.lerp(
        const Color(0xFFE1BEE7), // Light purple
        const Color(0xFF80DEEA), // Light cyan
        colorT,
      )!.withValues(alpha: 0.7);

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(CircularWavePainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}

class HorizontalWaveformPainter extends CustomPainter {
  final double animation;
  final bool isListening;

  HorizontalWaveformPainter({
    required this.animation,
    required this.isListening,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round;

    const barCount = 50;
    final barWidth = size.width / (barCount * 2);
    final centerY = size.height / 2;

    for (int i = 0; i < barCount; i++) {
      final x = i * barWidth * 2 + barWidth;

      // Create wave effect
      final waveOffset = math.sin((i / barCount * math.pi * 2) + (animation * math.pi * 2));

      double barHeight;
      if (isListening) {
        // Animated bars when listening
        barHeight = (20 + (waveOffset.abs() * 60)).clamp(10.0, 80.0);
      } else {
        // Small static bars when not listening
        barHeight = 10 + (waveOffset.abs() * 5);
      }

      // Create gradient effect
      final gradientColors = [
        Colors.pink[200]!,
        Colors.pink[300]!,
        Colors.pink[400]!,
      ];

      final colorIndex = (i / barCount * 2).clamp(0.0, 1.0);
      paint.color = Color.lerp(
        gradientColors[0],
        gradientColors[2],
        colorIndex,
      )!.withValues(alpha: 0.6 + (waveOffset.abs() * 0.4));

      // Draw bar
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(x, centerY),
            width: barWidth,
            height: barHeight,
          ),
          Radius.circular(barWidth / 2),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(HorizontalWaveformPainter oldDelegate) {
    return oldDelegate.animation != animation ||
        oldDelegate.isListening != isListening;
  }
}
