import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../models/user.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get current user from users table
  Future<User?> getCurrentUser() async {
    try {
      final session = _supabase.auth.currentSession;
      if (session == null) return null;

      // Try to get user from users table first
      final userData = await _supabase
          .from('users')
          .select()
          .eq('id', session.user.id)
          .maybeSingle();

      if (userData != null) {
        // Convert users table structure to User model
        return User(
          id: userData['id'],
          email: userData['email'] ?? '', // Use email as username for now
          fullName: userData['full_name'],
          avatarUrl: userData['avatar_url'],
          role: userData['is_admin'] == true ? 'admin' : 'user',
          createdAt: DateTime.parse(userData['created_at']),
        );
      }

      // Fallback: create user profile if it doesn't exist
      try {
        final authUser = _supabase.auth.currentUser;
        if (authUser != null) {
          // Insert new user record
          final newUser = await _supabase
              .from('users')
              .insert({
                'id': authUser.id,
                'email': authUser.email,
                'full_name': authUser.userMetadata?['full_name'],
                'is_admin': false,
              })
              .select()
              .single();

          return User(
            id: newUser['id'],
            email: newUser['email'] ?? '',
            fullName: newUser['full_name'],
            avatarUrl: newUser['avatar_url'],
            role: 'user',
            createdAt: DateTime.parse(newUser['created_at']),
          );
        }
      } catch (e) {
        print('Error creating user profile: $e');
      }

      return null;
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  // Sign up with email and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String role = 'user',
  }) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': email.split('@')[0]}, // Set default full name
    );

    // If signup is successful and user is confirmed, create the user profile
    if (response.user != null && response.session != null) {
      try {
        await _supabase.from('users').insert({
          'id': response.user!.id,
          'email': response.user!.email,
          'full_name': email.split('@')[0], // Default name from email
          'is_admin': role == 'admin',
        });
      } catch (e) {
        print('Error creating user profile: $e');
      }
    }

    return response;
  }

  // Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // Sign out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // Update user profile
  Future<void> updateProfile({
    required String username,
    String? fullName,
    String? avatarUrl,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      await _supabase
          .from('users')
          .update({
            'full_name': fullName,
            if (avatarUrl != null) 'avatar_url': avatarUrl,
          })
          .eq('id', user.id);
    } catch (e) {
      print('Error updating user profile: $e');
      rethrow;
    }
  }

  // Upload avatar image
  Future<String?> uploadAvatar(dynamic fileSource) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final fileName = '${user.id}_${DateTime.now().millisecondsSinceEpoch}';
      late Uint8List bytes;

      if (kIsWeb) {
        if (fileSource is XFile) {
          bytes = await fileSource.readAsBytes();
        } else {
          throw Exception('Invalid file source for web');
        }
      } else {
        if (fileSource is String) {
          final file = File(fileSource);
          bytes = await file.readAsBytes();
        } else if (fileSource is XFile) {
          bytes = await fileSource.readAsBytes();
        } else {
          throw Exception('Invalid file source for mobile');
        }
      }

      final response = await _supabase.storage
          .from('trip_images')
          .uploadBinary('avatars/$fileName', bytes);

      if (response.isNotEmpty) {
        final url = _supabase.storage
            .from('trip_images')
            .getPublicUrl('avatars/$fileName');
        return url;
      }
      return null;
    } catch (e) {
      print('Error uploading avatar: $e');
      return null;
    }
  }

  // Reset password via email
  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }
}