import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config/app_config.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Uploads a profile image to Firebase Storage
  /// Path: companies/{companyName}/events/{eventName}/profileImages/{userId}
  /// Returns the download URL of the uploaded image
  Future<String> uploadProfileImage(File imageFile) async {
    try {
      print('🔄 StorageService: Starting image upload...');
      
      // Get current user ID
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('❌ StorageService: User not authenticated');
        throw Exception('User not authenticated');
      }
      
      print('✅ StorageService: User authenticated - UID: ${currentUser.uid}');

      // Check if file exists
      final bool fileExists = await imageFile.exists();
      if (!fileExists) {
        print('❌ StorageService: Image file does not exist: ${imageFile.path}');
        throw Exception('Image file does not exist');
      }
      
      final int fileSize = await imageFile.length();
      print('✅ StorageService: Image file exists - Size: ${fileSize} bytes, Path: ${imageFile.path}');

      // Create the file path based on the required structure
      final String filePath = _buildProfileImagePath(currentUser.uid);
      print('✅ StorageService: Upload path: $filePath');
      
      // Create a reference to the file location
      final Reference ref = _storage.ref().child(filePath);
      print('✅ StorageService: Firebase reference created');
      
      // Set metadata for the image
      final SettableMetadata metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'uploadedBy': currentUser.uid,
          'uploadedAt': DateTime.now().toIso8601String(),
          'companyName': AppConfig.companyName,
          'eventName': AppConfig.defaultEventName,
        },
      );
      print('✅ StorageService: Metadata set');

      // Upload the file
      print('🔄 StorageService: Starting upload task...');
      final UploadTask uploadTask = ref.putFile(imageFile, metadata);
      
      // Listen to upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        print('🔄 StorageService: Upload progress: ${progress.toStringAsFixed(2)}%');
      });
      
      // Wait for upload to complete
      print('⏳ StorageService: Waiting for upload to complete...');
      final TaskSnapshot snapshot = await uploadTask;
      print('✅ StorageService: Upload completed! State: ${snapshot.state}');
      
      // Get the download URL
      print('🔄 StorageService: Getting download URL...');
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      print('✅ StorageService: Download URL obtained: $downloadUrl');
      
      return downloadUrl;
    } on FirebaseException catch (e) {
      print('❌ StorageService: Firebase error - Code: ${e.code}, Message: ${e.message}');
      throw Exception('Firebase Storage error: ${e.message}');
    } catch (e) {
      print('❌ StorageService: Unexpected error: $e');
      throw Exception('Error uploading image: $e');
    }
  }

  /// Deletes a profile image from Firebase Storage
  /// Returns true if successful, false otherwise
  Future<bool> deleteProfileImage(String userId) async {
    try {
      final String filePath = _buildProfileImagePath(userId);
      final Reference ref = _storage.ref().child(filePath);
      
      await ref.delete();
      return true;
    } on FirebaseException catch (e) {
      // If file doesn't exist, consider it as successful deletion
      if (e.code == 'object-not-found') {
        return true;
      }
      throw Exception('Firebase Storage error: ${e.message}');
    } catch (e) {
      throw Exception('Error deleting image: $e');
    }
  }

  /// Gets the download URL for a profile image if it exists
  /// Returns null if the image doesn't exist
  Future<String?> getProfileImageUrl(String userId) async {
    try {
      final String filePath = _buildProfileImagePath(userId);
      final Reference ref = _storage.ref().child(filePath);
      
      final String downloadUrl = await ref.getDownloadURL();
      return downloadUrl;
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') {
        return null; // Image doesn't exist
      }
      throw Exception('Firebase Storage error: ${e.message}');
    } catch (e) {
      throw Exception('Error getting image URL: $e');
    }
  }

  /// Builds the storage path for profile images
  /// Format: companies/{companyName}/events/{eventName}/profileImages/{userId}
  String _buildProfileImagePath(String userId) {
    // Sanitize company name and event name for storage path
    final String sanitizedCompanyName = _sanitizeForPath(AppConfig.companyName);
    final String sanitizedEventName = _sanitizeForPath(AppConfig.defaultEventName);
    
    return 'companies/$sanitizedCompanyName/events/$sanitizedEventName/profileImages/$userId.jpg';
  }

  /// Sanitizes a string to be safe for Firebase Storage paths
  /// Removes/replaces characters that could cause issues
  String _sanitizeForPath(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\-_]'), '_') // Replace invalid chars with underscore
        .replaceAll(RegExp(r'_+'), '_') // Replace multiple underscores with single
        .replaceAll(RegExp(r'^_|_$'), ''); // Remove leading/trailing underscores
  }

  /// Gets the current user's profile image path for reference
  String? getCurrentUserImagePath() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return null;
    
    return _buildProfileImagePath(currentUser.uid);
  }
}
