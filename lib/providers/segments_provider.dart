import 'package:flutter/foundation.dart';
import '../models/trip_segment.dart';
import '../services/segment_service.dart';

class SegmentsProvider with ChangeNotifier {
  final SegmentService _segmentService = SegmentService();

  Map<String, List<TripSegment>> _segmentsByTrip = {};
  bool _isLoading = false;
  String? _error;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<TripSegment> getSegmentsForTrip(String tripId) {
    return _segmentsByTrip[tripId] ?? [];
  }

  // Load segments for a specific trip
  Future<void> loadSegmentsForTrip(String tripId) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final segments = await _segmentService.getSegmentsForTrip(tripId);
      _segmentsByTrip[tripId] = segments;
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // Create a new segment
  Future<TripSegment?> createSegment(TripSegment segment) async {
    try {
      final createdSegment = await _segmentService.createSegment(segment);

      // Add to local state
      final tripId = segment.tripId;
      if (_segmentsByTrip[tripId] != null) {
        _segmentsByTrip[tripId]!.add(createdSegment);
        notifyListeners();
      }

      return createdSegment;
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
      return null;
    }
  }

  // Update an existing segment
  Future<TripSegment?> updateSegment(TripSegment segment) async {
    try {
      final updatedSegment = await _segmentService.updateSegment(segment);

      // Update in local state
      final tripId = segment.tripId;
      if (_segmentsByTrip[tripId] != null) {
        final index = _segmentsByTrip[tripId]!.indexWhere(
          (s) => s.id == segment.id,
        );
        if (index != -1) {
          _segmentsByTrip[tripId]![index] = updatedSegment;
          notifyListeners();
        }
      }

      return updatedSegment;
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
      return null;
    }
  }

  // Delete a segment
  Future<bool> deleteSegment(String segmentId, String tripId) async {
    try {
      await _segmentService.deleteSegment(segmentId);

      // Remove from local state
      if (_segmentsByTrip[tripId] != null) {
        _segmentsByTrip[tripId]!.removeWhere((s) => s.id == segmentId);
        notifyListeners();
      }

      return true;
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
      return false;
    }
  }

  // Get segments by type for a specific trip
  Future<List<TripSegment>> getSegmentsByType(
    String tripId,
    String type,
  ) async {
    try {
      return await _segmentService.getSegmentsByType(tripId, type);
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
      return [];
    }
  }

  // Get segments within a date range for a specific trip
  Future<List<TripSegment>> getSegmentsInDateRange(
    String tripId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      return await _segmentService.getSegmentsInDateRange(
        tripId,
        startDate,
        endDate,
      );
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
      return [];
    }
  }

  // Clear segments for a specific trip
  void clearSegmentsForTrip(String tripId) {
    _segmentsByTrip.remove(tripId);
    notifyListeners();
  }

  // Clear all segments
  void clearAllSegments() {
    _segmentsByTrip.clear();
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Helper method to set state
  void setState(VoidCallback fn) {
    fn();
    notifyListeners();
  }
}
