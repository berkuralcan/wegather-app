import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/profile_model.dart';
import '../services/storage_service.dart';
import 'base_repository.dart';
import 'dart:io';

class ProfileRepository extends BaseRepository<ProfileModel> {
  ProfileRepository() : super('users');
  
  final StorageService _storageService = StorageService();

  @override
  ProfileModel fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProfileModel.fromJson({...data, 'id': doc.id});
  }

  @override
  Map<String, dynamic> toFirestore(ProfileModel profile) {
    final json = profile.toJson();
    json.remove('id'); // Remove ID as Firestore handles it automatically
    return json;
  }

  /// Uploads a profile image to Firebase Storage and returns the download URL
  Future<String> uploadProfileImage(File imageFile) async {
    try {
      return await _storageService.uploadProfileImage(imageFile);
    } catch (e) {
      throw Exception('Failed to upload profile image: $e');
    }
  }

  /// Updates a user's profile with the new image URL
  Future<void> updateProfileImage(String userId, String imageUrl) async {
    try {
      await FirebaseFirestore.instance.collection(collectionPath).doc(userId).update({
        'profileImage': imageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update profile image URL: $e');
    }
  }

  /// Deletes a profile image from storage
  Future<bool> deleteProfileImage(String userId) async {
    try {
      return await _storageService.deleteProfileImage(userId);
    } catch (e) {
      throw Exception('Failed to delete profile image: $e');
    }
  }

  /// Gets the profile image URL for a user
  Future<String?> getProfileImageUrl(String userId) async {
    try {
      return await _storageService.getProfileImageUrl(userId);
    } catch (e) {
      throw Exception('Failed to get profile image URL: $e');
    }
  }
}

