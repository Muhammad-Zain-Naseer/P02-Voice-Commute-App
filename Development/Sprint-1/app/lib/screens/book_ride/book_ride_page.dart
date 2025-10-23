import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:math' as math;
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../../services/audio_api_service.dart';
import '../../services/location_service.dart';
import '../../services/socket_service.dart';
import '../../models/ride_request.dart';
import '../../utils/logger.dart';

class BookRidePage extends StatefulWidget {
  const BookRidePage({super.key});

  @override
  State<BookRidePage> createState() => _BookRidePageState();
}

class _BookRidePageState extends State<BookRidePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final AudioRecorder _audioRecorder = AudioRecorder();
  final Uuid _uuid = const Uuid();

  bool _isListening = false;
  bool _isProcessing = false;
  bool _isPublishing = false;
  bool _isWaitingForDriver = false;

  final TextEditingController _sourceController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();

  String? _currentRideId;
  RideRequest? _matchedRide;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    // Automatically fetch current location on page load
    _loadCurrentLocation();

    // Initialize socket connection
    _initializeSocket();
  }

  /// Initialize socket connection and event listeners
  Future<void> _initializeSocket() async {
    try {
      // Generate unique user ID
      final userId = _uuid.v4();

      // Connect to socket server
      await SocketService.connect(
        userId: userId,
        userName: 'Commuter User', // TODO: Get from user profile
      );

      // Listen for ride created confirmation
      SocketService.onRideCreated((data) {
        Logger.log('✅ Ride created confirmation: $data');
        if (mounted) {
          setState(() {
            _isPublishing = false;
            _isWaitingForDriver = true;
            _currentRideId = data['ride']['id'] as String?;
          });
        }
      });

      // Listen for ride matched event
      SocketService.onRideMatched((ride, role) {
        Logger.log('🎉 Ride matched! Role: $role');
        if (mounted) {
          setState(() {
            _matchedRide = ride;
            _isWaitingForDriver = false;
          });

          // Show matched dialog
          _showMatchedDialog(ride);
        }
      });

      // Listen for ride errors
      SocketService.onRideError((message) {
        Logger.error('🔴 Ride error: $message');
        if (mounted) {
          setState(() {
            _isPublishing = false;
            _isWaitingForDriver = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $message'),
              backgroundColor: Colors.red,
            ),
          );
        }
      });

      Logger.log('✅ Socket initialized successfully');
    } catch (e) {
      Logger.error('💥 Failed to initialize socket: $e');
    }
  }

  /// Show dialog when ride is matched with a driver
  void _showMatchedDialog(RideRequest ride) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text(
          '🎉 ڈرائیور مل گیا!',
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'آپ کی سواری کی درخواست قبول ہو گئی!',
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (ride.matchedWith != null) ...[
              Text(
                'ڈرائیور: ${ride.matchedWith!.driverName}',
                textDirection: TextDirection.rtl,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
            ],
            Text(
              'شروعات: ${ride.source.address}',
              textDirection: TextDirection.rtl,
              style: const TextStyle(fontSize: 12),
            ),
            Text(
              'منزل: ${ride.destination.address}',
              textDirection: TextDirection.rtl,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Navigate to ride tracking page
            },
            child: const Text('ٹھیک ہے'),
          ),
        ],
      ),
    );
  }

  /// Load current location and set it as source
  Future<void> _loadCurrentLocation() async {
    Logger.log('🌍 Loading current location on page load...');
    try {
      final location = await LocationService.getCurrentLocationAddress();
      if (location != null && mounted) {
        setState(() {
          _sourceController.text = location;
        });
        Logger.log('✅ Source set to current location: $location');
      }
    } catch (e) {
      Logger.error('❌ Error loading current location: $e');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _audioRecorder.dispose();
    _sourceController.dispose();
    _destinationController.dispose();
    SocketService.removeAllListeners();
    SocketService.disconnect();
    super.dispose();
  }

  /// Publish ride request to the connection pool
  Future<void> _publishRide() async {
    final source = _sourceController.text.trim();
    final destination = _destinationController.text.trim();

    // Validate inputs
    if (source.isEmpty || destination.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'براہ کرم شروعاتی جگہ اور منزل دونوں درج کریں',
            textDirection: TextDirection.rtl,
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (source == destination) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'شروعاتی جگہ اور منزل ایک جیسی نہیں ہو سکتی',
            textDirection: TextDirection.rtl,
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Check socket connection
    if (!SocketService.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'سرور سے منسلک نہیں۔ دوبارہ کوشش کریں۔',
            textDirection: TextDirection.rtl,
          ),
          backgroundColor: Colors.red,
        ),
      );
      await _initializeSocket();
      return;
    }

    setState(() {
      _isPublishing = true;
    });

    try {
      Logger.log('📤 Publishing ride request...');
      Logger.log('Source: $source');
      Logger.log('Destination: $destination');

      // Emit ride request via socket
      SocketService.emitRideRequest(
        source: source,
        destination: destination,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '✅ سواری کی درخواست شائع ہو گئی! ڈرائیور کا انتظار ہے...',
            textDirection: TextDirection.rtl,
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      Logger.error('💥 Failed to publish ride: $e');

      setState(() {
        _isPublishing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Cancel the current ride request
  Future<void> _cancelRide() async {
    if (_currentRideId == null) return;

    SocketService.cancelRide(_currentRideId!);

    setState(() {
      _isWaitingForDriver = false;
      _currentRideId = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'سواری کی درخواست منسوخ ہو گئی',
          textDirection: TextDirection.rtl,
        ),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Future<void> _toggleListening() async {
    Logger.log('🎤 Toggle listening called. Current state: $_isListening');

    // Prevent multiple clicks
    if (_isProcessing) {
      Logger.log('⚠️ Already processing, ignoring click');
      return;
    }

    if (_isListening) {
      // Stop recording
      Logger.log('🛑 Stopping recording...');
      await _stopRecording();
    } else {
      // Start recording
      Logger.log('▶️ Starting recording...');
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    // Set state immediately for UI feedback
    setState(() {
      _isProcessing = true;
    });

    Logger.log('📱 Requesting microphone permission...');

    // Check and request permission
    final status = await Permission.microphone.request();
    Logger.log('🔐 Permission status: $status');

    if (!status.isGranted) {
      Logger.error('❌ Permission denied!');
      setState(() {
        _isProcessing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Microphone permission is required'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      // Start recording
      Logger.log('🎙️ Starting audio recorder...');

      if (kIsWeb) {
        Logger.log('🌐 Web platform detected - recording to memory');
        // On web, record to memory (no path needed, handled internally)
        await _audioRecorder.start(
          const RecordConfig(
            encoder: AudioEncoder.wav, // WAV works better on web
            numChannels: 1,
            sampleRate: 16000,
          ),
          path: 'audio_recording', // Dummy path for web
        );
      } else {
        // On mobile (Android/iOS), use proper file path
        Logger.log('📱 Mobile platform detected - getting file path');
        final tempDir = await getTemporaryDirectory();
        final filePath = '${tempDir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
        Logger.log('💾 Mobile recording path: $filePath');

        await _audioRecorder.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc, // AAC works better on mobile
            numChannels: 1,
            sampleRate: 16000,
          ),
          path: filePath,
        );
      }

      Logger.log('✅ Recording started successfully!');
      setState(() {
        _isListening = true;
        _isProcessing = false; // Reset after successful start
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recording started...'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      Logger.error('💥 ERROR starting recording: $e');
      setState(() {
        _isProcessing = false; // Reset on error
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting recording: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    try {
      Logger.log('⏹️ Stopping audio recorder...');
      final path = await _audioRecorder.stop();

      setState(() {
        _isListening = false;
      });

      Logger.log('📍 Recording stopped. Path: $path');

      if (path != null && path.isNotEmpty) {
        Logger.log('🚀 Processing audio...');

        if (kIsWeb) {
          // On web, path is actually a data URL or blob URL
          Logger.log('🌐 Web: Processing audio from path...');
          // The stop() method on web returns the path as a string
          // which we'll use to fetch and upload the audio data
          await _processAudioWeb(path);
        } else {
          // On mobile, process the file path
          await _processAudioFile(path);
        }
      } else {
        Logger.error('⚠️ No recording path returned!');
      }
    } catch (e) {
      Logger.error('💥 ERROR stopping recording: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error stopping recording: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _processAudioWeb(String audioPath) async {
    Logger.log('🔄 Starting to process web audio: $audioPath');

    setState(() {
      _isProcessing = true;
    });

    try {
      // Step 1: Try to get current location
      Logger.log('📍 Attempting to get current location...');
      String? currentLocation = await LocationService.getCurrentLocationAddress();

      // Step 2: Call API to get destination from audio
      Logger.log('📡 Calling API service for web...');
      final result = await AudioApiService.processAudio(audioPath);
      Logger.log('📥 API Response: $result');

      if (result != null && mounted) {
        // Determine source: prefer current location, fallback to API source
        String source = '';
        if (currentLocation != null && currentLocation.isNotEmpty) {
          source = currentLocation;
          Logger.log('✅ Using current location as source: $source');
        } else if (result['source'] != null && result['source'].toString().isNotEmpty) {
          source = result['source'];
          Logger.log('✅ Using API source: $source');
        }

        final destination = result['destination'] ?? '';
        Logger.log('✅ Success! Source: $source, Destination: $destination');

        setState(() {
          _sourceController.text = source;
          _destinationController.text = destination;
          _isProcessing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Locations extracted!\nFrom: ${source.isEmpty ? "Not set" : source}\nTo: ${destination.isEmpty ? "Not found" : destination}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } else if (mounted) {
        Logger.error('❌ API returned null result');

        setState(() {
          _isProcessing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to process audio. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e, stackTrace) {
      Logger.error('💥 ERROR processing web audio: $e');
      Logger.error('Stack trace: $stackTrace');

      if (mounted) {
        setState(() {
          _isProcessing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _processAudioFile(String filePath) async {
    Logger.log('🔄 Starting to process audio file: $filePath');

    setState(() {
      _isProcessing = true;
    });

    try {
      // Step 1: Try to get current location
      Logger.log('📍 Attempting to get current location...');
      String? currentLocation = await LocationService.getCurrentLocationAddress();

      // Step 2: Call API to get destination from audio
      Logger.log('📡 Calling API service...');
      final result = await AudioApiService.processAudio(filePath);
      Logger.log('📥 API Response: $result');

      if (result != null && mounted) {
        // Determine source: prefer current location, fallback to API source
        String source = '';
        if (currentLocation != null && currentLocation.isNotEmpty) {
          source = currentLocation;
          Logger.log('✅ Using current location as source: $source');
        } else if (result['source'] != null && result['source'].toString().isNotEmpty) {
          source = result['source'];
          Logger.log('✅ Using API source: $source');
        }

        final destination = result['destination'] ?? '';
        Logger.log('✅ Success! Source: $source, Destination: $destination');

        setState(() {
          _sourceController.text = source;
          _destinationController.text = destination;
          _isProcessing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Locations extracted!\nFrom: ${source.isEmpty ? "Not set" : source}\nTo: ${destination.isEmpty ? "Not found" : destination}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } else if (mounted) {
        Logger.error('❌ API returned null result');

        setState(() {
          _isProcessing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to process audio. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e, stackTrace) {
      Logger.error('💥 ERROR processing audio: $e');
      Logger.error('Stack trace: $stackTrace');

      if (mounted) {
        setState(() {
          _isProcessing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
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
                // Audio waveform
                SizedBox(
                  height: 100,
                  child: AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: WaveformPainter(
                          animation: _animationController.value,
                          isListening: _isListening,
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
                    child: _isProcessing
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const CircularProgressIndicator(
                                color: Colors.pink,
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'پروسیسنگ جاری ہے',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          )
                        : GestureDetector(
                            onTap: () {
                              Logger.log('👆 BUTTON CLICKED!');
                              _toggleListening();
                            },
                            child: Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.pink[300]!,
                                  width: 3,
                                ),
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: _isListening
                                      ? [
                                          Colors.pink[300]!,
                                          Colors.pink[400]!,
                                        ]
                                      : [
                                          Colors.pink[200]!,
                                          Colors.pink[300]!,
                                        ],
                                ),
                                boxShadow: _isListening
                                    ? [
                                        BoxShadow(
                                          color: Colors.pink[200]!.withValues(alpha: 0.5),
                                          blurRadius: 20,
                                          spreadRadius: 5,
                                        ),
                                      ]
                                    : [],
                              ),
                              child: Icon(
                                _isListening ? Icons.stop : Icons.mic,
                                size: 70,
                                color: Colors.white,
                              ),
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
                // Source input field
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
                    controller: _sourceController,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                    decoration: InputDecoration(
                      hintText: 'شروعاتی جگہ (Source)',
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
                      suffixIcon: Icon(
                        Icons.location_on_outlined,
                        color: Colors.pink[300],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Destination input field
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
                    controller: _destinationController,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                    decoration: InputDecoration(
                      hintText: 'منزل (Destination)',
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
                      suffixIcon: Icon(
                        Icons.flag_outlined,
                        color: Colors.pink[300],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                // Publish Ride Button or Waiting Status
                if (_isWaitingForDriver)
                  // Waiting for driver UI
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.orange[300]!,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.orange,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'ڈرائیور کا انتظار ہے...',
                          textDirection: TextDirection.rtl,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'آپ کی سواری کی درخواست شائع ہو گئی',
                          textDirection: TextDirection.rtl,
                          style: TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: _cancelRide,
                          child: const Text(
                            'منسوخ کریں',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  // Publish Ride Button
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: _isPublishing ? null : _publishRide,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFCF4374),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                      ),
                      child: _isPublishing
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                          : const Text(
                              'سواری شائع کریں',
                              textDirection: TextDirection.rtl,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                const SizedBox(height: 20),
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
