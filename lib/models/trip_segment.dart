class TripSegment {
  final String id;
  final String tripId;
  final String userId;
  final String type;
  final String? details;
  final DateTime? startTime;
  final DateTime? endTime;
  final DateTime createdAt;

  // Static getter for UI components
  static List<String> get segmentTypes => [
    'Flight',
    'Hotel',
    'Activity',
    'Transport',
    'Restaurant',
    'Meeting',
    'Other',
  ];

  TripSegment({
    required this.id,
    required this.tripId,
    required this.userId,
    required this.type,
    this.details,
    this.startTime,
    this.endTime,
    required this.createdAt,
  });

  factory TripSegment.fromJson(Map<String, dynamic> json) {
    return TripSegment(
      id: json['id'] ?? '',
      tripId: json['trip_id'] ?? '',
      userId: json['user_id'] ?? '',
      type: json['type'] ?? '',
      details: json['details'],
      startTime: json['start_time'] != null
          ? DateTime.parse(json['start_time'])
          : null,
      endTime: json['end_time'] != null
          ? DateTime.parse(json['end_time'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trip_id': tripId,
      'user_id': userId,
      'type': type,
      'details': details,
      'start_time': startTime?.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  TripSegment copyWith({
    String? id,
    String? tripId,
    String? userId,
    String? type,
    String? details,
    DateTime? startTime,
    DateTime? endTime,
    DateTime? createdAt,
  }) {
    return TripSegment(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      details: details ?? this.details,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'TripSegment(id: $id, tripId: $tripId, type: $type, details: $details)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TripSegment && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
