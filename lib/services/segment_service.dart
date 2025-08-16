import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/trip_segment.dart';

class SegmentService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get all segments for a specific trip
  Future<List<TripSegment>> getSegmentsForTrip(String tripId) async {
    try {
      final response = await _supabase
          .from('trip_segments')
          .select()
          .eq('trip_id', tripId)
          .order('start_time', ascending: true);

      return (response as List)
          .map((json) => TripSegment.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch segments: $e');
    }
  }

  // Create a new segment
  Future<TripSegment> createSegment(TripSegment segment) async {
    try {
      // Create a copy of the segment data without the ID for new segments
      final segmentData = segment.toJson();
      segmentData.remove('id'); // Remove ID to let database generate it

      final response = await _supabase
          .from('trip_segments')
          .insert(segmentData)
          .select()
          .single();

      return TripSegment.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create segment: $e');
    }
  }

  // Update an existing segment
  Future<TripSegment> updateSegment(TripSegment segment) async {
    try {
      final response = await _supabase
          .from('trip_segments')
          .update(segment.toJson())
          .eq('id', segment.id)
          .select()
          .single();

      return TripSegment.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update segment: $e');
    }
  }

  // Delete a segment
  Future<void> deleteSegment(String segmentId) async {
    try {
      await _supabase.from('trip_segments').delete().eq('id', segmentId);
    } catch (e) {
      throw Exception('Failed to delete segment: $e');
    }
  }

  // Get a single segment by ID
  Future<TripSegment> getSegmentById(String segmentId) async {
    try {
      final response = await _supabase
          .from('trip_segments')
          .select()
          .eq('id', segmentId)
          .single();

      return TripSegment.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch segment: $e');
    }
  }

  // Get segments by type for a specific trip
  Future<List<TripSegment>> getSegmentsByType(
    String tripId,
    String type,
  ) async {
    try {
      final response = await _supabase
          .from('trip_segments')
          .select()
          .eq('trip_id', tripId)
          .eq('type', type)
          .order('start_time', ascending: true);

      return (response as List)
          .map((json) => TripSegment.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch segments by type: $e');
    }
  }

  // Get segments within a date range for a specific trip
  Future<List<TripSegment>> getSegmentsInDateRange(
    String tripId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final response = await _supabase
          .from('trip_segments')
          .select()
          .eq('trip_id', tripId)
          .gte('start_time', startDate.toIso8601String())
          .lte('end_time', endDate.toIso8601String())
          .order('start_time', ascending: true);

      return (response as List)
          .map((json) => TripSegment.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch segments in date range: $e');
    }
  }
}
