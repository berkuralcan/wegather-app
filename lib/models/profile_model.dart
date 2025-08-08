class ProfileModel {
  final String id;
  final String name;
  final String email;
  final String title;
  final ProfileSocialMedia socialMedia;

  ProfileModel({
    required this.id,
    required this.name,
    required this.email,
    required this.title,
    required this.socialMedia,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      title: json['title'] ?? '',
      socialMedia: ProfileSocialMedia.fromJson(json['socialMedia'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'title': title,
      'socialMedia': socialMedia.toJson(),
    };
  }

  ProfileModel copyWith({
    String? id,
    String? name,
    String? email,
    String? title,
    ProfileSocialMedia? socialMedia,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      title: title ?? this.title,
      socialMedia: socialMedia ?? this.socialMedia,
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