import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final _uuid = const Uuid();
  static const String _bucketName = 'trip_images'; // Use existing bucket
  static const String _avatarFolder = 'avatars';

  // Upload trip image from File (primarily for mobile)
  Future<String> uploadTripImage(File imageFile, String tripId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('No user logged in');

      final fileExtension = path.extension(imageFile.path);
      final fileName = '${_uuid.v4()}$fileExtension';
      final filePath = '${user.id}/$tripId/$fileName';

      await _supabase.storage.from(_bucketName).upload(filePath, imageFile);

      final imageUrl = _supabase.storage
          .from(_bucketName)
          .getPublicUrl(filePath);

      return imageUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  // Upload image from XFile (works for both web and mobile)
  Future<String> uploadImageFromXFile(XFile pickedImage, String tripId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('No user logged in');

      final fileExtension = path.extension(pickedImage.name);
      final fileName = '${_uuid.v4()}$fileExtension';
      final filePath = '${user.id}/$tripId/$fileName';

      final bytes = await pickedImage.readAsBytes();
      await _supabase.storage.from(_bucketName).uploadBinary(filePath, bytes);

      final imageUrl = _supabase.storage
          .from(_bucketName)
          .getPublicUrl(filePath);

      return imageUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  // Upload trip image from bytes
  Future<String> uploadAvatarFromBytes(
    Uint8List imageBytes,
    String fileExtension,
  ) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('No user logged in');

      final fileName = '${_uuid.v4()}.$fileExtension';
      final filePath = '$_avatarFolder/${user.id}/$fileName';

      await _supabase.storage
          .from(_bucketName)
          .uploadBinary(filePath, imageBytes);

      return _supabase.storage.from(_bucketName).getPublicUrl(filePath);
    } catch (e) {
      throw Exception('Failed to upload avatar: $e');
    }
  }

  Future<String> uploadAvatar(File imageFile) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('No user logged in');

      final fileExtension = path.extension(imageFile.path);
      final fileName = '${_uuid.v4()}$fileExtension';
      final filePath = '$_avatarFolder/${user.id}/$fileName';

      await _supabase.storage.from(_bucketName).upload(filePath, imageFile);

      return _supabase.storage.from(_bucketName).getPublicUrl(filePath);
    } catch (e) {
      throw Exception('Failed to upload avatar: $e');
    }
  }

  Future<String> uploadTripImageFromBytes(
    Uint8List imageBytes,
    String tripId,
    String fileExtension,
  ) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('No user logged in');

      final fileName = '${_uuid.v4()}.$fileExtension';
      final filePath = '${user.id}/$tripId/$fileName';

      await _supabase.storage
          .from(_bucketName)
          .uploadBinary(filePath, imageBytes);

      final imageUrl = _supabase.storage
          .from(_bucketName)
          .getPublicUrl(filePath);

      return imageUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  // Delete trip image
  Future<void> deleteTripImage(String imageUrl) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('No user logged in');

      // Extract file path from URL
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      if (pathSegments.length >= 3) {
        final filePath =
            '${pathSegments[pathSegments.length - 3]}/${pathSegments[pathSegments.length - 2]}/${pathSegments[pathSegments.length - 1]}';

        await _supabase.storage.from(_bucketName).remove([filePath]);
      }
    } catch (e) {
      throw Exception('Failed to delete image: $e');
    }
  }

  // Get image URL
  String getImageUrl(String filePath) {
    return _supabase.storage.from(_bucketName).getPublicUrl(filePath);
  }

  // Check if image exists
  Future<bool> imageExists(String imageUrl) async {
    try {
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      if (pathSegments.length >= 3) {
        final files = await _supabase.storage
            .from(_bucketName)
            .list(
              path:
                  '${pathSegments[pathSegments.length - 3]}/${pathSegments[pathSegments.length - 2]}',
            );

        return files.any((file) => file.name == pathSegments.last);
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Get user's trip images
  Future<List<String>> getUserTripImages(String tripId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('No user logged in');

      final files = await _supabase.storage
          .from(_bucketName)
          .list(path: '${user.id}/$tripId');

      return files
          .map((file) => getImageUrl('${user.id}/$tripId/${file.name}'))
          .toList();
    } catch (e) {
      return [];
    }
  }
}
