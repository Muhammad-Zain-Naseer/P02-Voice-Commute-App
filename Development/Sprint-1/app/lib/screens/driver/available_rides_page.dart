import 'package:flutter/material.dart';
import '../../services/socket_service.dart';
import '../../models/ride_request.dart';
import '../../utils/logger.dart';
import 'package:uuid/uuid.dart';

/// Driver Dashboard - View and accept available rides
class AvailableRidesPage extends StatefulWidget {
  const AvailableRidesPage({super.key});

  @override
  State<AvailableRidesPage> createState() => _AvailableRidesPageState();
}

class _AvailableRidesPageState extends State<AvailableRidesPage> {
  final Uuid _uuid = const Uuid();
  List<RideRequest> _availableRides = [];
  bool _isConnected = false;
  RideRequest? _acceptedRide;

  @override
  void initState() {
    super.initState();
    _initializeDriverSocket();
  }

  Future<void> _initializeDriverSocket() async {
    try {
      final driverId = _uuid.v4();

      // Connect as driver
      await SocketService.connect(
        userId: driverId,
        userName: 'Driver Ahmed', // TODO: Get from profile
      );

      setState(() {
        _isConnected = true;
      });

      // Listen for new rides
      SocketService.onNewRide((ride) {
        Logger.log('🆕 New ride received: ${ride.id}');
        if (mounted) {
          setState(() {
            _availableRides.add(ride);
          });
        }
      });

      // Listen for ride matched
      SocketService.onRideMatched((ride, role) {
        Logger.log('🎉 Ride matched as $role');
        if (mounted && role == 'driver') {
          setState(() {
            _acceptedRide = ride;
            _availableRides.removeWhere((r) => r.id == ride.id);
          });
          _showAcceptedDialog(ride);
        }
      });

      // Listen for ride list updates
      SocketService.onRideListUpdated((rides) {
        Logger.log('🔄 Ride list updated: ${rides.length} rides');
        if (mounted) {
          setState(() {
            _availableRides = rides.where((r) => r.isPending).toList();
          });
        }
      });

      // Request current list of rides
      SocketService.requestRideList();

      // Listen for ride list response
      SocketService.onRideList((rides) {
        Logger.log('📥 Received ${rides.length} rides');
        if (mounted) {
          setState(() {
            _availableRides = rides;
          });
        }
      });

      Logger.log('✅ Driver socket initialized');
    } catch (e) {
      Logger.error('💥 Failed to initialize driver socket: $e');
    }
  }

  void _acceptRide(RideRequest ride) {
    SocketService.matchRide(
      rideId: ride.id,
      driverId: 'driver-001', // TODO: Get from profile
      driverName: 'Driver Ahmed Khan',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Accepting ride...'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _showAcceptedDialog(RideRequest ride) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('🎉 Ride Accepted!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'You have accepted this ride!',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text('Passenger: ${ride.userName}'),
            const SizedBox(height: 8),
            Text('From: ${ride.source.address}'),
            Text('To: ${ride.destination.address}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCE4EC),
      appBar: AppBar(
        title: const Text('Available Rides'),
        backgroundColor: const Color(0xFFCF4374),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Connection status
            Container(
              padding: const EdgeInsets.all(16),
              color: _isConnected ? Colors.green[50] : Colors.red[50],
              child: Row(
                children: [
                  Icon(
                    _isConnected ? Icons.check_circle : Icons.error,
                    color: _isConnected ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isConnected
                        ? 'Connected - Listening for rides...'
                        : 'Not connected',
                    style: TextStyle(
                      color: _isConnected ? Colors.green[900] : Colors.red[900],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Rides list
            Expanded(
              child: _availableRides.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.local_taxi,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No rides available',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Waiting for ride requests...',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _availableRides.length,
                      itemBuilder: (context, index) {
                        final ride = _availableRides[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.person,
                                      color: Color(0xFFCF4374),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      ride.userName,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 24),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on,
                                      size: 20,
                                      color: Colors.green,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'From: ${ride.source.address}',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.flag,
                                      size: 20,
                                      color: Colors.red,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'To: ${ride.destination.address}',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () => _acceptRide(ride),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFCF4374),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text(
                                      'Accept Ride',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    SocketService.removeAllListeners();
    super.dispose();
  }
}
