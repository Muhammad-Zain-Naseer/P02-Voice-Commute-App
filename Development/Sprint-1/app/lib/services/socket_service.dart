import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../constants/app_config.dart';
import '../models/ride_request.dart';
import '../utils/logger.dart';

/// Socket Service for Real-time Communication
/// Manages Socket.IO connection and ride-related events
class SocketService {
  static IO.Socket? _socket;
  static bool _isConnected = false;
  static String? _userId;
  static String? _userName;

  /// Get connection status
  static bool get isConnected => _isConnected;

  /// Get socket instance
  static IO.Socket? get socket => _socket;

  /// Connect to Socket.IO server
  static Future<void> connect({
    required String userId,
    String? userName,
  }) async {
    if (_isConnected && _socket != null) {
      Logger.log('🔌 Socket already connected: ${_socket!.id}');
      return;
    }

    _userId = userId;
    _userName = userName ?? 'Anonymous User';

    try {
      Logger.log('🔌 Connecting to socket server: ${AppConfig.socketUrl}');

      _socket = IO.io(
        AppConfig.socketUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .enableAutoConnect()
            .enableReconnection()
            .setReconnectionDelay(
              AppConfig.socketReconnectionDelay.inMilliseconds,
            )
            .setReconnectionAttempts(AppConfig.socketReconnectionAttempts)
            .setTimeout(AppConfig.socketTimeout.inMilliseconds)
            .build(),
      );

      // Connection event handlers
      _socket!.onConnect((_) {
        _isConnected = true;
        Logger.log('✅ Socket connected: ${_socket!.id}');

        // Register user with server
        _socket!.emit('user:register', {
          'userId': _userId,
          'userName': _userName,
          'userType': 'commuter',
        });
      });

      _socket!.onDisconnect((_) {
        _isConnected = false;
        Logger.log('❌ Socket disconnected');
      });

      _socket!.onConnectError((error) {
        _isConnected = false;
        Logger.error('🔴 Socket connection error: $error');
      });

      _socket!.onError((error) {
        Logger.error('🔴 Socket error: $error');
      });

      _socket!.on('user:registered', (data) {
        Logger.log('✅ User registered on server: $data');
      });

      _socket!.on('error', (data) {
        Logger.error('🔴 Server error: $data');
      });

      _socket!.connect();
    } catch (e) {
      Logger.error('💥 Failed to connect socket: $e');
      _isConnected = false;
    }
  }

  /// Disconnect from Socket.IO server
  static void disconnect() {
    if (_socket != null) {
      Logger.log('🔌 Disconnecting socket...');
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
      _isConnected = false;
    }
  }

  /// Emit a ride request to the server
  static void emitRideRequest({
    required String source,
    required String destination,
    Map<String, double>? sourceCoordinates,
    Map<String, double>? destinationCoordinates,
  }) {
    if (_socket == null || !_isConnected) {
      Logger.error('❌ Cannot emit ride request: Socket not connected');
      return;
    }

    final rideData = {
      'userId': _userId,
      'userName': _userName,
      'source': source,
      'destination': destination,
      'sourceCoordinates': sourceCoordinates,
      'destinationCoordinates': destinationCoordinates,
    };

    Logger.log('📤 Emitting ride request: $rideData');
    _socket!.emit('ride:create', rideData);
  }

  /// Listen for ride created confirmation
  static void onRideCreated(Function(Map<String, dynamic>) callback) {
    if (_socket == null) {
      Logger.error('❌ Cannot listen for ride:created: Socket not initialized');
      return;
    }

    _socket!.on('ride:created', (data) {
      Logger.log('✅ Ride created: $data');
      try {
        // Socket.IO may wrap data in array, extract first element
        final responseData = data is List ? data[0] : data;
        callback(responseData as Map<String, dynamic>);
      } catch (e) {
        Logger.error('💥 Error parsing ride created: $e');
      }
    });
  }

  /// Listen for ride matched event
  static void onRideMatched(Function(RideRequest, String) callback) {
    if (_socket == null) {
      Logger.error('❌ Cannot listen for ride:matched: Socket not initialized');
      return;
    }

    _socket!.on('ride:matched', (data) {
      Logger.log('🎉 Ride matched: $data');
      try {
        // Socket.IO may wrap data in array, extract first element
        final responseData = (data is List ? data[0] : data) as Map<String, dynamic>;
        final rideData = responseData['ride'] as Map<String, dynamic>;
        final role = responseData['role'] as String;
        final ride = RideRequest.fromJson(rideData);
        callback(ride, role);
      } catch (e) {
        Logger.error('💥 Error parsing matched ride: $e');
      }
    });
  }

  /// Listen for new rides (for drivers)
  static void onNewRide(Function(RideRequest) callback) {
    if (_socket == null) {
      Logger.error('❌ Cannot listen for ride:new: Socket not initialized');
      return;
    }

    _socket!.on('ride:new', (data) {
      Logger.log('🆕 New ride available: $data');
      try {
        // Socket.IO may wrap data in array, extract first element
        final responseData = (data is List ? data[0] : data) as Map<String, dynamic>;
        final rideData = responseData['ride'] as Map<String, dynamic>;
        final ride = RideRequest.fromJson(rideData);
        callback(ride);
      } catch (e) {
        Logger.error('💥 Error parsing new ride: $e');
      }
    });
  }

  /// Listen for ride list updates
  static void onRideListUpdated(Function(List<RideRequest>) callback) {
    if (_socket == null) {
      Logger.error(
        '❌ Cannot listen for ride:list:updated: Socket not initialized',
      );
      return;
    }

    _socket!.on('ride:list:updated', (data) {
      try {
        // Socket.IO may wrap data in array, extract first element
        final responseData = (data is List ? data[0] : data) as Map<String, dynamic>;
        Logger.log('🔄 Ride list updated: ${responseData['count']} rides');
        final ridesData = responseData['rides'] as List;
        final rides = ridesData
            .map((r) => RideRequest.fromJson(r as Map<String, dynamic>))
            .toList();
        callback(rides);
      } catch (e) {
        Logger.error('💥 Error parsing ride list: $e');
      }
    });
  }

  /// Listen for ride errors
  static void onRideError(Function(String) callback) {
    if (_socket == null) {
      Logger.error('❌ Cannot listen for ride:error: Socket not initialized');
      return;
    }

    _socket!.on('ride:error', (data) {
      Logger.error('🔴 Ride error: $data');
      try {
        // Socket.IO may wrap data in array, extract first element
        final responseData = (data is List ? data[0] : data) as Map<String, dynamic>;
        final message = responseData['message'] as String? ?? 'Unknown error occurred';
        callback(message);
      } catch (e) {
        callback('Unknown error occurred');
      }
    });
  }

  /// Request list of pending rides (for drivers)
  static void requestRideList() {
    if (_socket == null || !_isConnected) {
      Logger.error('❌ Cannot request ride list: Socket not connected');
      return;
    }

    Logger.log('📤 Requesting ride list...');
    _socket!.emit('ride:list', {});
  }

  /// Listen for ride list response
  static void onRideList(Function(List<RideRequest>) callback) {
    if (_socket == null) {
      Logger.error('❌ Cannot listen for ride:list: Socket not initialized');
      return;
    }

    _socket!.on('ride:list', (data) {
      try {
        // Socket.IO may wrap data in array, extract first element
        final responseData = (data is List ? data[0] : data) as Map<String, dynamic>;
        Logger.log('📥 Received ride list: ${responseData['count']} rides');
        final ridesData = responseData['rides'] as List;
        final rides = ridesData
            .map((r) => RideRequest.fromJson(r as Map<String, dynamic>))
            .toList();
        callback(rides);
      } catch (e) {
        Logger.error('💥 Error parsing ride list: $e');
      }
    });
  }

  /// Cancel a ride request
  static void cancelRide(String rideId) {
    if (_socket == null || !_isConnected) {
      Logger.error('❌ Cannot cancel ride: Socket not connected');
      return;
    }

    Logger.log('📤 Cancelling ride: $rideId');
    _socket!.emit('ride:cancel', {'rideId': rideId});
  }

  /// Listen for ride cancelled event
  static void onRideCancelled(Function(String) callback) {
    if (_socket == null) {
      Logger.error('❌ Cannot listen for ride:cancelled: Socket not initialized');
      return;
    }

    _socket!.on('ride:cancelled', (data) {
      Logger.log('🚫 Ride cancelled: $data');
      final rideId = data['rideId'] as String? ?? data as String;
      callback(rideId);
    });
  }

  /// Match with a ride (for drivers)
  static void matchRide({
    required String rideId,
    required String driverId,
    String? driverName,
  }) {
    if (_socket == null || !_isConnected) {
      Logger.error('❌ Cannot match ride: Socket not connected');
      return;
    }

    final matchData = {
      'rideId': rideId,
      'driverId': driverId,
      'driverName': driverName ?? 'Driver',
    };

    Logger.log('📤 Matching ride: $matchData');
    _socket!.emit('ride:match', matchData);
  }

  /// Remove all event listeners
  static void removeAllListeners() {
    if (_socket != null) {
      _socket!.off('ride:created');
      _socket!.off('ride:matched');
      _socket!.off('ride:new');
      _socket!.off('ride:list');
      _socket!.off('ride:list:updated');
      _socket!.off('ride:error');
      _socket!.off('ride:cancelled');
      Logger.log('🗑️ Removed all socket listeners');
    }
  }
}
