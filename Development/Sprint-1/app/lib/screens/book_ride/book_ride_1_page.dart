import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:math' as math;
import 'book_ride_2_page.dart';

class BookRide1Page extends StatefulWidget {
  const BookRide1Page({super.key});

  @override
  State<BookRide1Page> createState() => _BookRide1PageState();
}

class _BookRide1PageState extends State<BookRide1Page>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final TextEditingController _locationController = TextEditingController();

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
    _locationController.dispose();
    super.dispose();
  }

  void _startListening() {
    // Navigate to the listening page
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BookRide2Page()),
    );
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
                const SizedBox(height: 20),
                // Header text in Urdu
              
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
                // Audio waveform
                SizedBox(
                  height: 100,
                  child: AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: WaveformPainter(
                          animation: _animationController.value,
                          isListening: false,
                        ),
                        size: const Size(double.infinity, 100),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 30),
                // Microphone button container
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
                  child: Center(
                    child: GestureDetector(
                      onTap: _startListening,
                      child: SvgPicture.asset(
                        'assets/icons/mic_icon.svg',
                        width: 140,
                        height: 140,
                      ),
                    ),
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
                // Text input field
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

class WaveformPainter extends CustomPainter {
  final double animation;
  final bool isListening;

  WaveformPainter({
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
  bool shouldRepaint(WaveformPainter oldDelegate) {
    return oldDelegate.animation != animation ||
        oldDelegate.isListening != isListening;
  }
}
