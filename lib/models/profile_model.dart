class ProfileModel {
  final String id;
  final String name;
  final String email;
  final String title;
  final ProfileSocialMedia socialMedia;
  final String profileImage;

  ProfileModel({
    required this.id,
    required this.name,
    required this.email,
    required this.title,
    required this.socialMedia,
    required this.profileImage,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      title: json['title'] ?? '',
      socialMedia: ProfileSocialMedia.fromJson(json['socialMedia'] ?? {}),
      profileImage: json['profileImage'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'title': title,
      'socialMedia': socialMedia.toJson(),
      'profileImage': profileImage,
    };
  }

  ProfileModel copyWith({
    String? id,
    String? name,
    String? email,
    String? title,
    ProfileSocialMedia? socialMedia,
    String? profileImage,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      title: title ?? this.title,
      socialMedia: socialMedia ?? this.socialMedia,
      profileImage: profileImage ?? this.profileImage,
    );
  }
}

class ProfileSocialMedia {
  final String? instagram;
  final String? facebook;
  final String? twitter;
  final String? linkedIn;

  ProfileSocialMedia({
    this.instagram,
    this.facebook,
    this.twitter,
    this.linkedIn,
  });

  factory ProfileSocialMedia.fromJson(Map<String, dynamic> json) {
    return ProfileSocialMedia(
      instagram: json['instagram'],
      facebook: json['facebook'],
      twitter: json['twitter'],
      linkedIn: json['linkedIn'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'instagram': instagram,
      'facebook': facebook,
      'twitter': twitter,
      'linkedIn': linkedIn,
    };
  }

  ProfileSocialMedia copyWith({
    String? instagram,
    String? facebook,
    String? twitter,
    String? linkedIn,
  }) {
    return ProfileSocialMedia(
      instagram: instagram ?? this.instagram,
      facebook: facebook ?? this.facebook,
      twitter: twitter ?? this.twitter,
      linkedIn: linkedIn ?? this.linkedIn,
    );
  }
}