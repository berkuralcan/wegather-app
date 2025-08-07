import 'package:flutter/material.dart';
import '../models/profile_model.dart';
import '../services/profile_service.dart';

class ProfileScreen extends StatefulWidget {
  final String profileId;

  const ProfileScreen({super.key, required this.profileId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileService _profileService = ProfileService();
  ProfileModel? profile;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profileData = await _profileService.getProfile(widget.profileId);
      setState(() {
        profile = profileData;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Center(child: Text('Error: $error'));
    }

    if (profile == null) {
      return const Center(child: Text('Profile not found'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('ID: ${profile!.id}'),
        const SizedBox(height: 8),
        Text('Name: ${profile!.name}'),
        const SizedBox(height: 8),
        Text('Email: ${profile!.email}'),
        const SizedBox(height: 8),
        Text('Title: ${profile!.title}'),
        const SizedBox(height: 16),
        const Text('Social Media:'),
        Text('Instagram: ${profile!.socialMedia.instagram ?? 'None'}'),
        Text('Facebook: ${profile!.socialMedia.facebook ?? 'None'}'),
        Text('Twitter: ${profile!.socialMedia.twitter ?? 'None'}'),
        Text('LinkedIn: ${profile!.socialMedia.linkedin ?? 'None'}'),
      ],
    );
  }
}