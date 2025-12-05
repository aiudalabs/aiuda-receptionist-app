import 'package:cloud_firestore/cloud_firestore.dart';

enum WorkMode {
  independent,
  businessOwner,
  employee,
  both;

  String toFirestore() => name;

  static WorkMode fromFirestore(String value) {
    return WorkMode.values.firstWhere(
      (e) => e.name == value,
      orElse: () => WorkMode.independent,
    );
  }
}

class ProfessionalInfo {
  final String title;
  final String bio;
  final int yearsExperience;

  ProfessionalInfo({
    required this.title,
    this.bio = '',
    this.yearsExperience = 0,
  });

  factory ProfessionalInfo.fromMap(Map<String, dynamic> map) {
    return ProfessionalInfo(
      title: map['title'] ?? '',
      bio: map['bio'] ?? '',
      yearsExperience: map['yearsExperience'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'bio': bio,
      'yearsExperience': yearsExperience,
    };
  }
}

class UserLocation {
  final double latitude;
  final double longitude;
  final String address;

  UserLocation({
    required this.latitude,
    required this.longitude,
    required this.address,
  });

  factory UserLocation.fromMap(Map<String, dynamic> map) {
    return UserLocation(
      latitude: map['latitude']?.toDouble() ?? 0.0,
      longitude: map['longitude']?.toDouble() ?? 0.0,
      address: map['address'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
    };
  }
}

class UserModel {
  final String id;
  final String email;
  final String businessName;
  final String timezone;
  final List<String> fcmTokens;
  final DateTime createdAt;

  // New provider fields
  final WorkMode workMode;
  final ProfessionalInfo? professionalInfo;
  final List<String> industries; // Industry IDs from taxonomy (e.g., ['beauty', 'wellness'])
  final String? phoneNumber;
  final UserLocation? location;
  final String? profileImageUrl;
  final bool isAvailable;
  final List<String> businessIds; // For employees - which businesses they work for
  final List<String> specialties; // Service specialties (e.g., 'Hair Cutting', 'Massage')

  UserModel({
    required this.id,
    required this.email,
    required this.businessName,
    required this.timezone,
    this.fcmTokens = const [],
    required this.createdAt,
    this.workMode = WorkMode.independent,
    this.professionalInfo,
    this.industries = const [],
    this.phoneNumber,
    this.location,
    this.profileImageUrl,
    this.isAvailable = true,
    this.businessIds = const [],
    this.specialties = const [],
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      email: data['email'] ?? '',
      businessName: data['businessName'] ?? '',
      timezone: data['timezone'] ?? 'UTC',
      fcmTokens: List<String>.from(data['fcmTokens'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      workMode: data['workMode'] != null
          ? WorkMode.fromFirestore(data['workMode'])
          : WorkMode.independent,
      professionalInfo: data['professionalInfo'] != null
          ? ProfessionalInfo.fromMap(data['professionalInfo'])
          : null,
      industries: List<String>.from(data['industries'] ?? []),
      phoneNumber: data['phoneNumber'],
      location: data['location'] != null
          ? UserLocation.fromMap(data['location'])
          : null,
      profileImageUrl: data['profileImageUrl'],
      isAvailable: data['isAvailable'] ?? true,
      businessIds: List<String>.from(data['businessIds'] ?? []),
      specialties: List<String>.from(data['specialties'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'businessName': businessName,
      'timezone': timezone,
      'fcmTokens': fcmTokens,
      'createdAt': Timestamp.fromDate(createdAt),
      'workMode': workMode.toFirestore(),
      'professionalInfo': professionalInfo?.toMap(),
      'industries': industries,
      'phoneNumber': phoneNumber,
      'location': location?.toMap(),
      'profileImageUrl': profileImageUrl,
      'isAvailable': isAvailable,
      'businessIds': businessIds,
      'specialties': specialties,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? businessName,
    String? timezone,
    List<String>? fcmTokens,
    DateTime? createdAt,
    WorkMode? workMode,
    ProfessionalInfo? professionalInfo,
    List<String>? industries,
    String? phoneNumber,
    UserLocation? location,
    String? profileImageUrl,
    bool? isAvailable,
    List<String>? businessIds,
    List<String>? specialties,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      businessName: businessName ?? this.businessName,
      timezone: timezone ?? this.timezone,
      fcmTokens: fcmTokens ?? this.fcmTokens,
      createdAt: createdAt ?? this.createdAt,
      workMode: workMode ?? this.workMode,
      professionalInfo: professionalInfo ?? this.professionalInfo,
      industries: industries ?? this.industries,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      location: location ?? this.location,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      isAvailable: isAvailable ?? this.isAvailable,
      businessIds: businessIds ?? this.businessIds,
      specialties: specialties ?? this.specialties,
    );
  }
}
