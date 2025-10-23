/// Ride Request Model
/// Represents a ride request in the application

class RideRequest {
  final String id;
  final String userId;
  final String userName;
  final String userType;
  final LocationData source;
  final LocationData destination;
  final String status;
  final MatchedDriver? matchedWith;
  final DateTime createdAt;
  final DateTime updatedAt;

  RideRequest({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userType,
    required this.source,
    required this.destination,
    required this.status,
    this.matchedWith,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create RideRequest from JSON
  factory RideRequest.fromJson(Map<String, dynamic> json) {
    return RideRequest(
      id: json['id'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String? ?? 'Anonymous User',
      userType: json['userType'] as String? ?? 'commuter',
      source: LocationData.fromJson(json['source'] as Map<String, dynamic>),
      destination: LocationData.fromJson(json['destination'] as Map<String, dynamic>),
      status: json['status'] as String,
      matchedWith: json['matchedWith'] != null
          ? MatchedDriver.fromJson(json['matchedWith'] as Map<String, dynamic>)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Convert RideRequest to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userType': userType,
      'source': source.toJson(),
      'destination': destination.toJson(),
      'status': status,
      'matchedWith': matchedWith?.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Check if ride is pending
  bool get isPending => status == 'pending';

  /// Check if ride is matched
  bool get isMatched => status == 'matched';

  /// Check if ride is cancelled
  bool get isCancelled => status == 'cancelled';

  /// Copy with updated fields
  RideRequest copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userType,
    LocationData? source,
    LocationData? destination,
    String? status,
    MatchedDriver? matchedWith,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RideRequest(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userType: userType ?? this.userType,
      source: source ?? this.source,
      destination: destination ?? this.destination,
      status: status ?? this.status,
      matchedWith: matchedWith ?? this.matchedWith,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Location Data with address and optional coordinates
class LocationData {
  final String address;
  final Coordinates? coordinates;

  LocationData({
    required this.address,
    this.coordinates,
  });

  factory LocationData.fromJson(Map<String, dynamic> json) {
    return LocationData(
      address: json['address'] as String,
      coordinates: json['coordinates'] != null
          ? Coordinates.fromJson(json['coordinates'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'address': address,
      'coordinates': coordinates?.toJson(),
    };
  }
}

/// Coordinates (latitude and longitude)
class Coordinates {
  final double lat;
  final double lon;

  Coordinates({
    required this.lat,
    required this.lon,
  });

  factory Coordinates.fromJson(Map<String, dynamic> json) {
    return Coordinates(
      lat: (json['lat'] as num).toDouble(),
      lon: (json['lon'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lat': lat,
      'lon': lon,
    };
  }
}

/// Matched Driver Information
class MatchedDriver {
  final String driverId;
  final String driverName;
  final String socketId;
  final DateTime matchedAt;

  MatchedDriver({
    required this.driverId,
    required this.driverName,
    required this.socketId,
    required this.matchedAt,
  });

  factory MatchedDriver.fromJson(Map<String, dynamic> json) {
    return MatchedDriver(
      driverId: json['driverId'] as String,
      driverName: json['driverName'] as String,
      socketId: json['socketId'] as String,
      matchedAt: DateTime.parse(json['matchedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'driverId': driverId,
      'driverName': driverName,
      'socketId': socketId,
      'matchedAt': matchedAt.toIso8601String(),
    };
  }
}
