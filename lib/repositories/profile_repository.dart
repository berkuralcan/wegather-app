import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/profile_model.dart';
import 'base_repository.dart';

class ProfileRepository extends BaseRepository<ProfileModel> {
  ProfileRepository() : super('users');

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
}