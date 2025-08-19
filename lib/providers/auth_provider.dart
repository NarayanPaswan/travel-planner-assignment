import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../models/user.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _currentUser;
  bool _isLoading = false;
  String? _error;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;

  // Initialize user on app start
  Future<void> initializeUser() async {
    _setLoading(true);
    try {
      _currentUser = await _authService.getCurrentUser();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // Sign up
  Future<bool> signUp({
    required String email,
    required String password,
    String role = 'user',
  }) async {
    _setLoading(true);
    try {
      final response = await _authService.signUp(
        email: email,
        password: password,
        role: role,
      );

      if (response.user != null) {
        // Wait a moment for the trigger to create the profile
        await Future.delayed(const Duration(seconds: 2));
        await initializeUser();
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

  // Sign in
  Future<bool> signIn({required String email, required String password}) async {
    _setLoading(true);
    try {
      final response = await _authService.signIn(
        email: email,
        password: password,
      );

      if (response.user != null) {
        await initializeUser();
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

  // Sign out
  Future<void> signOut() async {
    _setLoading(true);
    try {
      await _authService.signOut();
      _currentUser = null;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // Update profile
  void setCurrentUser(User? user) {
    _currentUser = user;
    notifyListeners();
  }

  Future<bool> updateProfile({
    required String username,
    String? fullName,
    String? avatarUrl,
  }) async {
    _setLoading(true);
    try {
      await _authService.updateProfile(
        username: username,
        fullName: fullName,
        avatarUrl: avatarUrl,
      );

      // Optimistically update local user for immediate UI feedback
      if (_currentUser != null) {
        _currentUser = _currentUser!.copyWith(
          fullName: fullName ?? _currentUser!.fullName,
          avatarUrl: avatarUrl ?? _currentUser!.avatarUrl,
        );
        _error = null;
        notifyListeners();
      }

      // Refresh user data from backend to ensure consistency
      await initializeUser();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Reset password
  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    try {
      await _authService.resetPassword(email);
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
