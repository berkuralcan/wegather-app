/// The signed-in user, read from `users/{uid}`.
///
/// [name], [email] and [title] are the display fields the app has always had;
/// everything below them is optional profile detail the panel may or may not
/// have filled in, so a screen showing them collapses whatever is unset. The
/// optional fields carry the same names as their `ParticipantModel`
/// counterparts, since both describe a person.
class ProfileModel {
  final String id;
  final String name;
  final String email;
  final String title;
  final String? company;
  final String? phone;
  final String? description;
  final ProfileSocialMedia socialMedia;
  final String profileImage;

  ProfileModel({
    required this.id,
    required this.name,
    required this.email,
    required this.title,
    this.company,
    this.phone,
    this.description,
    required this.socialMedia,
    required this.profileImage,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      title: json['title'] ?? '',
      company: json['company'],
      phone: json['phone'],
      description: json['description'],
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
      if (company != null) 'company': company,
      if (phone != null) 'phone': phone,
      if (description != null) 'description': description,
      'socialMedia': socialMedia.toJson(),
      'profileImage': profileImage,
    };
  }

  ProfileModel copyWith({
    String? id,
    String? name,
    String? email,
    String? title,
    String? company,
    String? phone,
    String? description,
    ProfileSocialMedia? socialMedia,
    String? profileImage,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      title: title ?? this.title,
      company: company ?? this.company,
      phone: phone ?? this.phone,
      description: description ?? this.description,
      socialMedia: socialMedia ?? this.socialMedia,
      profileImage: profileImage ?? this.profileImage,
    );
  }
}

/// Where to find the user online.
///
/// [instagram] and [linkedIn] are handles rather than URLs (see
/// `navigateToSocialMedia`), while [website] and [portfolio] are full
/// addresses. [facebook] and [twitter] predate the current profile design and
/// are kept only so existing documents survive a round trip.
class ProfileSocialMedia {
  final String? instagram;
  final String? facebook;
  final String? twitter;
  final String? linkedIn;
  final String? website;
  final String? portfolio;

  ProfileSocialMedia({
    this.instagram,
    this.facebook,
    this.twitter,
    this.linkedIn,
    this.website,
    this.portfolio,
  });

  factory ProfileSocialMedia.fromJson(Map<String, dynamic> json) {
    return ProfileSocialMedia(
      instagram: json['instagram'],
      facebook: json['facebook'],
      twitter: json['twitter'],
      linkedIn: json['linkedIn'],
      website: json['website'],
      portfolio: json['portfolio'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'instagram': instagram,
      'facebook': facebook,
      'twitter': twitter,
      'linkedIn': linkedIn,
      'website': website,
      'portfolio': portfolio,
    };
  }

  ProfileSocialMedia copyWith({
    String? instagram,
    String? facebook,
    String? twitter,
    String? linkedIn,
    String? website,
    String? portfolio,
  }) {
    return ProfileSocialMedia(
      instagram: instagram ?? this.instagram,
      facebook: facebook ?? this.facebook,
      twitter: twitter ?? this.twitter,
      linkedIn: linkedIn ?? this.linkedIn,
      website: website ?? this.website,
      portfolio: portfolio ?? this.portfolio,
    );
  }
}
