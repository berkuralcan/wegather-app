import '../models/profile_model.dart';
import '../repositories/profile_repository.dart';
import '../auth_services.dart';
import 'dart:io';

class ProfileService {
  final ProfileRepository _profileRepository = ProfileRepository();
  final AuthService _authService = AuthService();

  // Get profile by ID with business logic
  Future<ProfileModel?> getProfile(String profileId) async {
    if (profileId.isEmpty) {
      throw ArgumentError('Profile ID cannot be empty');
    }
    return await _profileRepository.getById(profileId);
  }

  // Get all profiles (you might add filtering/sorting logic here later)
  Future<List<ProfileModel>> getAllProfiles() async {
    final profiles = await _profileRepository.getAll();
    // Business logic: sort by name
    profiles.sort((a, b) => a.name.compareTo(b.name));
    return profiles;
  }



  // Validate profile data before saving
  bool validateProfile(ProfileModel profile) {
    if (profile.name.trim().isEmpty) return false;
    if (profile.email.trim().isEmpty) return false;
    if (!_isValidEmail(profile.email)) return false;
    return true;
  }

  // Helper method for email validation
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Format profile for display (example of business logic)
  String getDisplayName(ProfileModel profile) {
    return profile.title.isNotEmpty 
        ? '${profile.name} - ${profile.title}'
        : profile.name;
  }

  // Check if profile has social media (business logic)
  bool hasSocialMedia(ProfileModel profile) {
    final social = profile.socialMedia;
    return social.instagram != null || 
           social.facebook != null || 
           social.twitter != null || 
           social.linkedIn != null;
  }

  /// Uploads a profile image and updates the user's profile document
  /// Returns the download URL of the uploaded image
  Future<String> uploadProfileImage(File imageFile) async {
    // Ensure user is authenticated
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      throw Exception('User must be authenticated to upload profile image');
    }

    try {
      // Upload the image to Firebase Storage
      final imageUrl = await _profileRepository.uploadProfileImage(imageFile);
      
      // Update the user's profile document with the new image URL
      await _profileRepository.updateProfileImage(currentUser.uid, imageUrl);
      
      return imageUrl;
    } catch (e) {
      throw Exception('Failed to upload and update profile image: $e');
    }
  }

  /// Gets the current authenticated user's profile
  Future<ProfileModel?> getCurrentUserProfile() async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      return null;
    }
    return await getProfile(currentUser.uid);
  }

  /// Deletes the current user's profile image
  Future<bool> deleteCurrentUserProfileImage() async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      throw Exception('User must be authenticated to delete profile image');
    }

    try {
      // Delete from storage
      final deleted = await _profileRepository.deleteProfileImage(currentUser.uid);
      
      if (deleted) {
        // Update profile document to remove image URL
        await _profileRepository.updateProfileImage(currentUser.uid, '');
      }
      
      return deleted;
    } catch (e) {
      throw Exception('Failed to delete profile image: $e');
    }
  }
}