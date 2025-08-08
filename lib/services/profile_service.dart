import '../models/profile_model.dart';
import '../repositories/profile_repository.dart';

class ProfileService {
  final ProfileRepository _profileRepository = ProfileRepository();

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

  // Get current user's profile (placeholder - you'll implement this with auth)
  Future<ProfileModel?> getCurrentUserProfile() async {
    // TODO: Get current user ID from AuthService
    // final currentUserId = AuthService.getCurrentUserId();
    // return await getProfile(currentUserId);
    
    // For now, return null - you'll implement this when you add auth
    return null;
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
}