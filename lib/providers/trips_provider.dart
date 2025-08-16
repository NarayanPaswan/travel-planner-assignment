import 'package:flutter/foundation.dart';
import '../models/trip.dart';
import '../models/trip_segment.dart';
import '../models/expense.dart';
import '../services/trip_service.dart';

class TripsProvider extends ChangeNotifier {
  final TripService _tripService = TripService();

  List<Trip> _trips = [];
  List<TripSegment> _currentTripSegments = [];
  List<Expense> _currentTripExpenses = [];
  bool _isLoading = false;
  String? _error;

  List<Trip> get trips => _trips;
  List<TripSegment> get currentTripSegments => _currentTripSegments;
  List<Expense> get currentTripExpenses => _currentTripExpenses;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load user trips
  Future<void> loadUserTrips() async {
    _setLoading(true);
    try {
      _trips = await _tripService.getUserTrips();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // Load all trips (for admin)
  Future<void> loadAllTrips() async {
    _setLoading(true);
    try {
      _trips = await _tripService.getAllTrips();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // Create new trip
  Future<bool> createTrip({
    required String title,
    required String destination,
    required DateTime startDate,
    required DateTime endDate,
    String? description,
    String? tripImageUrl,
    double? budget,
  }) async {
    _setLoading(true);
    try {
      final trip = await _tripService.createTrip(
        title: title,
        destination: destination,
        startDate: startDate,
        endDate: endDate,
        description: description,
        tripImageUrl: tripImageUrl,
        budget: budget,
      );

      if (trip != null) {
        _trips.insert(0, trip);
        _error = null;
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
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
    _setLoading(true);
    try {
      final success = await _tripService.updateTrip(
        tripId: tripId,
        title: title,
        destination: destination,
        startDate: startDate,
        endDate: endDate,
        description: description,
        tripImageUrl: tripImageUrl,
        budget: budget,
      );

      if (success) {
        final index = _trips.indexWhere((trip) => trip.id == tripId);
        if (index != -1) {
          _trips[index] = _trips[index].copyWith(
            title: title,
            destination: destination,
            startDate: startDate,
            endDate: endDate,
            description: description,
            tripImageUrl: tripImageUrl,
            budget: budget,
            updatedAt: DateTime.now(),
          );
        }
        _error = null;
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Delete trip
  Future<bool> deleteTrip(String tripId) async {
    _setLoading(true);
    try {
      final success = await _tripService.deleteTrip(tripId);
      if (success) {
        _trips.removeWhere((trip) => trip.id == tripId);
        _error = null;
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Load trip segments
  Future<void> loadTripSegments(String tripId) async {
    try {
      _currentTripSegments = await _tripService.getTripSegments(tripId);
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
  }

  // Create trip segment
  Future<bool> createTripSegment({
    required String tripId,
    required String type,
    String? details,
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    try {
      final segment = await _tripService.createTripSegment(
        tripId: tripId,
        type: type,
        details: details,
        startTime: startTime,
        endTime: endTime,
      );

      if (segment != null) {
        _currentTripSegments.add(segment);
        _error = null;
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
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
      final success = await _tripService.updateTripSegment(
        segmentId: segmentId,
        type: type,
        details: details,
        startTime: startTime,
        endTime: endTime,
      );

      if (success) {
        final index = _currentTripSegments.indexWhere(
          (segment) => segment.id == segmentId,
        );
        if (index != -1) {
          _currentTripSegments[index] = _currentTripSegments[index].copyWith(
            type: type,
            details: details,
            startTime: startTime,
            endTime: endTime,
          );
        }
        _error = null;
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  // Delete trip segment
  Future<bool> deleteTripSegment(String segmentId) async {
    try {
      final success = await _tripService.deleteTripSegment(segmentId);
      if (success) {
        _currentTripSegments.removeWhere((segment) => segment.id == segmentId);
        _error = null;
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  // Load trip expenses
  Future<void> loadTripExpenses(String tripId) async {
    try {
      _currentTripExpenses = await _tripService.getTripExpenses(tripId);
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
  }

  // Create expense
  Future<bool> createExpense({
    required String tripId,
    required String description,
    required double amount,
    String currency = 'USD',
    String? category,
  }) async {
    try {
      final expense = await _tripService.createExpense(
        tripId: tripId,
        description: description,
        amount: amount,
        currency: currency,
        category: category,
      );

      if (expense != null) {
        _currentTripExpenses.insert(0, expense);
        _error = null;
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
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
      final success = await _tripService.updateExpense(
        expenseId: expenseId,
        description: description,
        amount: amount,
        currency: currency,
        category: category,
      );

      if (success) {
        final index = _currentTripExpenses.indexWhere(
          (expense) => expense.id == expenseId,
        );
        if (index != -1) {
          _currentTripExpenses[index] = _currentTripExpenses[index].copyWith(
            description: description,
            amount: amount,
            currency: currency,
            category: category,
            updatedAt: DateTime.now(),
          );
        }
        _error = null;
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  // Delete expense
  Future<bool> deleteExpense(String expenseId) async {
    try {
      final success = await _tripService.deleteExpense(expenseId);
      if (success) {
        _currentTripExpenses.removeWhere((expense) => expense.id == expenseId);
        _error = null;
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Clear current trip data
  void clearCurrentTripData() {
    _currentTripSegments.clear();
    _currentTripExpenses.clear();
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
