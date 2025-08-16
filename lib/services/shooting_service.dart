import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/shooting_data.dart';

class ShootingService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get all shooting data (admin only)
  Future<List<ShootingData>> getAllShootingData() async {
    try {
      final response = await _supabase
          .from('shooting_data')
          .select('*')
          .order('shooting_date', ascending: false);

      return (response as List)
          .map((json) => ShootingData.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch shooting data: $e');
    }
  }

  // Get shooting data for a specific user
  Future<List<ShootingData>> getShootingDataByUser(String userId) async {
    try {
      final response = await _supabase
          .from('shooting_data')
          .select('*')
          .eq('user_id', userId)
          .order('shooting_date', ascending: false);

      return (response as List)
          .map((json) => ShootingData.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch user shooting data: $e');
    }
  }

  // Get shooting data for a specific trip
  Future<List<ShootingData>> getShootingDataByTrip(String tripId) async {
    try {
      final response = await _supabase
          .from('shooting_data')
          .select('*')
          .eq('trip_id', tripId)
          .order('shooting_date', ascending: false);

      return (response as List)
          .map((json) => ShootingData.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch trip shooting data: $e');
    }
  }

  // Create new shooting data
  Future<ShootingData> createShootingData(ShootingData shootingData) async {
    try {
      final response = await _supabase
          .from('shooting_data')
          .insert(shootingData.toJson())
          .select()
          .single();

      return ShootingData.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create shooting data: $e');
    }
  }

  // Update shooting data
  Future<ShootingData> updateShootingData(ShootingData shootingData) async {
    try {
      final response = await _supabase
          .from('shooting_data')
          .update(shootingData.toJson())
          .eq('id', shootingData.id)
          .select()
          .single();

      return ShootingData.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update shooting data: $e');
    }
  }

  // Delete shooting data
  Future<void> deleteShootingData(String id) async {
    try {
      await _supabase.from('shooting_data').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete shooting data: $e');
    }
  }

  // Get shooting statistics (admin analytics)
  Future<List<ShootingStatistics>> getShootingStatistics() async {
    try {
      final response = await _supabase
          .from('shooting_statistics')
          .select('*')
          .order('total_sessions', ascending: false);

      return (response as List)
          .map((json) => ShootingStatistics.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch shooting statistics: $e');
    }
  }

  // Get shooting statistics for a specific user
  Future<List<ShootingStatistics>> getShootingStatisticsByUser(
    String userId,
  ) async {
    try {
      final response = await _supabase
          .from('shooting_statistics')
          .select('*')
          .eq('user_id', userId)
          .order('total_sessions', ascending: false);

      return (response as List)
          .map((json) => ShootingStatistics.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch user shooting statistics: $e');
    }
  }

  // Get aggregated shooting analytics
  Future<Map<String, dynamic>> getAggregatedAnalytics() async {
    try {
      // Get total counts
      final totalData = await _supabase.from('shooting_data').select('*');

      final totalSessions = totalData.length;

      // Get location distribution
      final locationStats = await _supabase
          .from('shooting_data')
          .select('location')
          .order('location');

      final locations = (locationStats as List)
          .map((json) => json['location'] as String)
          .toSet()
          .toList();

      // Get target type distribution
      final targetTypeStats = await _supabase
          .from('shooting_data')
          .select('target_type')
          .order('target_type');

      final targetTypes = (targetTypeStats as List)
          .map((json) => json['target_type'] as String)
          .toSet()
          .toList();

      return {
        'totalSessions': totalSessions,
        'locations': locations,
        'targetTypes': targetTypes,
      };
    } catch (e) {
      throw Exception('Failed to fetch aggregated analytics: $e');
    }
  }

  // Search shooting data with filters
  Future<List<ShootingData>> searchShootingData({
    String? location,
    String? targetType,
    DateTime? startDate,
    DateTime? endDate,
    double? minAccuracy,
    double? maxAccuracy,
    int? minDistance,
    int? maxDistance,
  }) async {
    try {
      var query = _supabase.from('shooting_data').select('*');

      if (location != null && location.isNotEmpty) {
        query = query.ilike('location', '%$location%');
      }

      if (targetType != null && targetType.isNotEmpty) {
        query = query.eq('target_type', targetType);
      }

      if (startDate != null) {
        query = query.gte(
          'shooting_date',
          startDate.toIso8601String().split('T')[0],
        );
      }

      if (endDate != null) {
        query = query.lte(
          'shooting_date',
          endDate.toIso8601String().split('T')[0],
        );
      }

      if (minAccuracy != null) {
        query = query.gte('accuracy_percentage', minAccuracy);
      }

      if (maxAccuracy != null) {
        query = query.lte('accuracy_percentage', maxAccuracy);
      }

      if (minDistance != null) {
        query = query.gte('distance_meters', minDistance);
      }

      if (maxDistance != null) {
        query = query.lte('distance_meters', maxDistance);
      }

      final response = await query.order('shooting_date', ascending: false);

      return (response as List)
          .map((json) => ShootingData.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to search shooting data: $e');
    }
  }
}
