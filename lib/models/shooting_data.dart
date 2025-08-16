class ShootingData {
  final String id;
  final String userId;
  final String tripId;
  final DateTime shootingDate;
  final String location;
  final String targetType;
  final int distanceMeters;
  final int shotsFired;
  final int shotsHit;
  final double accuracyPercentage;
  final String? weatherConditions;
  final double? windSpeedKmh;
  final double? temperatureCelsius;
  final String? equipmentUsed;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  ShootingData({
    required this.id,
    required this.userId,
    required this.tripId,
    required this.shootingDate,
    required this.location,
    required this.targetType,
    required this.distanceMeters,
    required this.shotsFired,
    required this.shotsHit,
    required this.accuracyPercentage,
    this.weatherConditions,
    this.windSpeedKmh,
    this.temperatureCelsius,
    this.equipmentUsed,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ShootingData.fromJson(Map<String, dynamic> json) {
    return ShootingData(
      id: json['id'],
      userId: json['user_id'],
      tripId: json['trip_id'],
      shootingDate: DateTime.parse(json['shooting_date']),
      location: json['location'],
      targetType: json['target_type'],
      distanceMeters: json['distance_meters'],
      shotsFired: json['shots_fired'],
      shotsHit: json['shots_hit'],
      accuracyPercentage: double.parse(json['accuracy_percentage'].toString()),
      weatherConditions: json['weather_conditions'],
      windSpeedKmh: json['wind_speed_kmh'] != null
          ? double.parse(json['wind_speed_kmh'].toString())
          : null,
      temperatureCelsius: json['temperature_celsius'] != null
          ? double.parse(json['temperature_celsius'].toString())
          : null,
      equipmentUsed: json['equipment_used'],
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'trip_id': tripId,
      'shooting_date': shootingDate.toIso8601String().split('T')[0],
      'location': location,
      'target_type': targetType,
      'distance_meters': distanceMeters,
      'shots_fired': shotsFired,
      'shots_hit': shotsHit,
      'weather_conditions': weatherConditions,
      'wind_speed_kmh': windSpeedKmh,
      'temperature_celsius': temperatureCelsius,
      'equipment_used': equipmentUsed,
      'notes': notes,
    };
  }

  ShootingData copyWith({
    String? id,
    String? userId,
    String? tripId,
    DateTime? shootingDate,
    String? location,
    String? targetType,
    int? distanceMeters,
    int? shotsFired,
    int? shotsHit,
    double? accuracyPercentage,
    String? weatherConditions,
    double? windSpeedKmh,
    double? temperatureCelsius,
    String? equipmentUsed,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ShootingData(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      tripId: tripId ?? this.tripId,
      shootingDate: shootingDate ?? this.shootingDate,
      location: location ?? this.location,
      targetType: targetType ?? this.targetType,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      shotsFired: shotsFired ?? this.shotsFired,
      shotsHit: shotsHit ?? this.shotsHit,
      accuracyPercentage: accuracyPercentage ?? this.accuracyPercentage,
      weatherConditions: weatherConditions ?? this.weatherConditions,
      windSpeedKmh: windSpeedKmh ?? this.windSpeedKmh,
      temperatureCelsius: temperatureCelsius ?? this.temperatureCelsius,
      equipmentUsed: equipmentUsed ?? this.equipmentUsed,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'ShootingData(id: $id, location: $location, targetType: $targetType, accuracy: ${accuracyPercentage.toStringAsFixed(1)}%)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ShootingData && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class ShootingStatistics {
  final String fullName;
  final String email;
  final String tripTitle;
  final String destination;
  final int totalSessions;
  final int totalShotsFired;
  final int totalShotsHit;
  final double avgAccuracy;
  final double bestAccuracy;
  final double worstAccuracy;
  final double avgDistance;
  final int maxDistance;
  final int uniqueLocations;
  final int targetTypesUsed;

  ShootingStatistics({
    required this.fullName,
    required this.email,
    required this.tripTitle,
    required this.destination,
    required this.totalSessions,
    required this.totalShotsFired,
    required this.totalShotsHit,
    required this.avgAccuracy,
    required this.bestAccuracy,
    required this.worstAccuracy,
    required this.avgDistance,
    required this.maxDistance,
    required this.uniqueLocations,
    required this.targetTypesUsed,
  });

  factory ShootingStatistics.fromJson(Map<String, dynamic> json) {
    return ShootingStatistics(
      fullName: json['full_name'] ?? '',
      email: json['email'] ?? '',
      tripTitle: json['trip_title'] ?? '',
      destination: json['destination'] ?? '',
      totalSessions: json['total_sessions'] ?? 0,
      totalShotsFired: json['total_shots_fired'] ?? 0,
      totalShotsHit: json['total_shots_hit'] ?? 0,
      avgAccuracy: double.parse((json['avg_accuracy'] ?? 0).toString()),
      bestAccuracy: double.parse((json['best_accuracy'] ?? 0).toString()),
      worstAccuracy: double.parse((json['worst_accuracy'] ?? 0).toString()),
      avgDistance: double.parse((json['avg_distance'] ?? 0).toString()),
      maxDistance: json['max_distance'] ?? 0,
      uniqueLocations: json['unique_locations'] ?? 0,
      targetTypesUsed: json['target_types_used'] ?? 0,
    );
  }

  double get overallAccuracy {
    if (totalShotsFired == 0) return 0.0;
    return (totalShotsHit / totalShotsFired) * 100;
  }
}
