import 'package:flutter/foundation.dart';
import '../models/shooting_data.dart';
import '../services/shooting_service.dart';

class ShootingProvider with ChangeNotifier {
  final ShootingService _shootingService = ShootingService();

  List<ShootingData> _shootingData = [];
  List<ShootingStatistics> _shootingStatistics = [];
  Map<String, dynamic> _aggregatedAnalytics = {};
  bool _isLoading = false;
  String? _error;

  // Getters
  List<ShootingData> get shootingData => _shootingData;
  List<ShootingStatistics> get shootingStatistics => _shootingStatistics;
  Map<String, dynamic> get aggregatedAnalytics => _aggregatedAnalytics;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load all shooting data (admin only)
  Future<void> loadAllShootingData() async {
    _setLoading(true);
    try {
      _error = null;
      _shootingData = await _shootingService.getAllShootingData();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // Load shooting data for a specific user
  Future<void> loadShootingDataByUser(String userId) async {
    _setLoading(true);
    try {
      _error = null;
      _shootingData = await _shootingService.getShootingDataByUser(userId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // Load shooting data for a specific trip
  Future<void> loadShootingDataByTrip(String tripId) async {
    _setLoading(true);
    try {
      _error = null;
      _shootingData = await _shootingService.getShootingDataByTrip(tripId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // Load shooting statistics (admin analytics)
  Future<void> loadShootingStatistics() async {
    _setLoading(true);
    try {
      _error = null;
      _shootingStatistics = await _shootingService.getShootingStatistics();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // Load aggregated analytics
  Future<void> loadAggregatedAnalytics() async {
    _setLoading(true);
    try {
      _error = null;
      _aggregatedAnalytics = await _shootingService.getAggregatedAnalytics();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // Create new shooting data
  Future<bool> createShootingData(ShootingData shootingData) async {
    _setLoading(true);
    try {
      _error = null;
      final newData = await _shootingService.createShootingData(shootingData);
      _shootingData.insert(0, newData);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update shooting data
  Future<bool> updateShootingData(ShootingData shootingData) async {
    _setLoading(true);
    try {
      _error = null;
      final updatedData = await _shootingService.updateShootingData(
        shootingData,
      );
      final index = _shootingData.indexWhere(
        (data) => data.id == shootingData.id,
      );
      if (index != -1) {
        _shootingData[index] = updatedData;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Delete shooting data
  Future<bool> deleteShootingData(String id) async {
    _setLoading(true);
    try {
      _error = null;
      await _shootingService.deleteShootingData(id);
      _shootingData.removeWhere((data) => data.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Search shooting data with filters
  Future<void> searchShootingData({
    String? location,
    String? targetType,
    DateTime? startDate,
    DateTime? endDate,
    double? minAccuracy,
    double? maxAccuracy,
    int? minDistance,
    int? maxDistance,
  }) async {
    _setLoading(true);
    try {
      _error = null;
      _shootingData = await _shootingService.searchShootingData(
        location: location,
        targetType: targetType,
        startDate: startDate,
        endDate: endDate,
        minAccuracy: minAccuracy,
        maxAccuracy: maxAccuracy,
        minDistance: minDistance,
        maxDistance: maxDistance,
      );
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Clear data
  void clearData() {
    _shootingData.clear();
    _shootingStatistics.clear();
    _aggregatedAnalytics.clear();
    _error = null;
    notifyListeners();
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Get filtered data by target type
  List<ShootingData> getShootingDataByTargetType(String targetType) {
    return _shootingData
        .where((data) => data.targetType == targetType)
        .toList();
  }

  // Get filtered data by location
  List<ShootingData> getShootingDataByLocation(String location) {
    return _shootingData.where((data) => data.location == location).toList();
  }

  // Get data within date range
  List<ShootingData> getShootingDataInDateRange(
    DateTime startDate,
    DateTime endDate,
  ) {
    return _shootingData.where((data) {
      return data.shootingDate.isAfter(
            startDate.subtract(const Duration(days: 1)),
          ) &&
          data.shootingDate.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();
  }

  // Get average accuracy
  double getAverageAccuracy() {
    if (_shootingData.isEmpty) return 0.0;
    final totalAccuracy = _shootingData.fold<double>(
      0.0,
      (sum, data) => sum + data.accuracyPercentage,
    );
    return totalAccuracy / _shootingData.length;
  }

  // Get best accuracy
  double getBestAccuracy() {
    if (_shootingData.isEmpty) return 0.0;
    return _shootingData
        .map((data) => data.accuracyPercentage)
        .reduce((a, b) => a > b ? a : b);
  }

  // Get worst accuracy
  double getWorstAccuracy() {
    if (_shootingData.isEmpty) return 0.0;
    return _shootingData
        .map((data) => data.accuracyPercentage)
        .reduce((a, b) => a < b ? a : b);
  }

  // Get total shots fired
  int getTotalShotsFired() {
    return _shootingData.fold(0, (sum, data) => sum + data.shotsFired);
  }

  // Get total shots hit
  int getTotalShotsHit() {
    return _shootingData.fold(0, (sum, data) => sum + data.shotsHit);
  }

  // Get overall accuracy percentage
  double getOverallAccuracyPercentage() {
    final totalFired = getTotalShotsFired();
    if (totalFired == 0) return 0.0;
    return (getTotalShotsHit() / totalFired) * 100;
  }
}
