import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/trip.dart';
import '../models/trip_segment.dart';
import '../models/expense.dart';

class TripService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get all trips for current user
  Future<List<Trip>> getUserTrips() async {
    try {
      final response = await _supabase
          .from('trips')
          .select()
          .order('created_at', ascending: false);

      return (response as List).map((json) => Trip.fromJson(json)).toList();
    } catch (e) {
      print('Error getting user trips: $e');
      return [];
    }
  }

  // Get all trips (for admin)
  Future<List<Trip>> getAllTrips() async {
    try {
      final response = await _supabase
          .from('trips')
          .select()
          .order('created_at', ascending: false);

      return (response as List).map((json) => Trip.fromJson(json)).toList();
    } catch (e) {
      print('Error getting all trips: $e');
      return [];
    }
  }

  // Create new trip
  Future<Trip?> createTrip({
    required String title,
    required String destination,
    required DateTime startDate,
    required DateTime endDate,
    String? description,
    String? tripImageUrl,
    double? budget,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('trips')
          .insert({
            'user_id': user.id,
            'title': title,
            'destination': destination,
            'start_date': startDate.toIso8601String().split('T')[0],
            'end_date': endDate.toIso8601String().split('T')[0],
            'description': description,
            'trip_image_url': tripImageUrl,
            'budget': budget,
          })
          .select()
          .single();

      return Trip.fromJson(response);
    } catch (e) {
      print('Error creating trip: $e');
      return null;
    }
  }

  // Update trip
  Future<bool> updateTrip({
    required String tripId,
    required String title,
    required String destination,
    required DateTime startDate,
    required DateTime endDate,
    String? description,
    String? tripImageUrl,
    double? budget,
  }) async {
    try {
      await _supabase
          .from('trips')
          .update({
            'title': title,
            'destination': destination,
            'start_date': startDate.toIso8601String().split('T')[0],
            'end_date': endDate.toIso8601String().split('T')[0],
            'description': description,
            'trip_image_url': tripImageUrl,
            'budget': budget,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', tripId);

      return true;
    } catch (e) {
      print('Error updating trip: $e');
      return false;
    }
  }

  // Delete trip
  Future<bool> deleteTrip(String tripId) async {
    try {
      await _supabase.from('trips').delete().eq('id', tripId);

      return true;
    } catch (e) {
      print('Error deleting trip: $e');
      return false;
    }
  }

  // Get trip segments
  Future<List<TripSegment>> getTripSegments(String tripId) async {
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
      print('Error getting trip segments: $e');
      return [];
    }
  }

  // Create trip segment
  Future<TripSegment?> createTripSegment({
    required String tripId,
    required String type,
    String? details,
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('trip_segments')
          .insert({
            'trip_id': tripId,
            'user_id': user.id,
            'type': type,
            'details': details,
            'start_time': startTime?.toIso8601String(),
            'end_time': endTime?.toIso8601String(),
          })
          .select()
          .single();

      return TripSegment.fromJson(response);
    } catch (e) {
      print('Error creating trip segment: $e');
      return null;
    }
  }

  // Update trip segment
  Future<bool> updateTripSegment({
    required String segmentId,
    required String type,
    String? details,
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    try {
      await _supabase
          .from('trip_segments')
          .update({
            'type': type,
            'details': details,
            'start_time': startTime?.toIso8601String(),
            'end_time': endTime?.toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', segmentId);

      return true;
    } catch (e) {
      print('Error updating trip segment: $e');
      return false;
    }
  }

  // Delete trip segment
  Future<bool> deleteTripSegment(String segmentId) async {
    try {
      await _supabase.from('trip_segments').delete().eq('id', segmentId);

      return true;
    } catch (e) {
      print('Error deleting trip segment: $e');
      return false;
    }
  }

  // Get trip expenses
  Future<List<Expense>> getTripExpenses(String tripId) async {
    try {
      final response = await _supabase
          .from('expenses')
          .select()
          .eq('trip_id', tripId)
          .order('created_at', ascending: false);

      return (response as List).map((json) => Expense.fromJson(json)).toList();
    } catch (e) {
      print('Error getting trip expenses: $e');
      return [];
    }
  }

  // Create expense
  Future<Expense?> createExpense({
    required String tripId,
    required String description,
    required double amount,
    String currency = 'USD',
    String? category,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('expenses')
          .insert({
            'trip_id': tripId,
            'user_id': user.id,
            'description': description,
            'amount': amount,
            'currency': currency,
            'category': category,
          })
          .select()
          .single();

      return Expense.fromJson(response);
    } catch (e) {
      print('Error creating expense: $e');
      return null;
    }
  }

  // Update expense
  Future<bool> updateExpense({
    required String expenseId,
    required String description,
    required double amount,
    String currency = 'USD',
    String? category,
  }) async {
    try {
      await _supabase
          .from('expenses')
          .update({
            'description': description,
            'amount': amount,
            'currency': currency,
            'category': category,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', expenseId);

      return true;
    } catch (e) {
      print('Error updating expense: $e');
      return false;
    }
  }

  // Delete expense
  Future<bool> deleteExpense(String expenseId) async {
    try {
      await _supabase.from('expenses').delete().eq('id', expenseId);

      return true;
    } catch (e) {
      print('Error deleting expense: $e');
      return false;
    }
  }

  // Upload trip image
  Future<String?> uploadTripImage(String filePath, String tripId) async {
    try {
      final fileName = '${tripId}_${DateTime.now().millisecondsSinceEpoch}';
      final response = await _supabase.storage
          .from('trip_images')
          .upload('trips/$fileName', File(filePath));

      if (response.isNotEmpty) {
        final url = _supabase.storage
            .from('trip_images')
            .getPublicUrl('trips/$fileName');
        return url;
      }
      return null;
    } catch (e) {
      print('Error uploading trip image: $e');
      return null;
    }
  }
}
