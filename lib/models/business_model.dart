import 'package:cloud_firestore/cloud_firestore.dart';

class BusinessLocation {
  final String address;
  final double? latitude;
  final double? longitude;
  final String? city;
  final String? state;
  final String? zipCode;

  BusinessLocation({
    required this.address,
    this.latitude,
    this.longitude,
    this.city,
    this.state,
    this.zipCode,
  });

  factory BusinessLocation.fromMap(Map<String, dynamic> map) {
    return BusinessLocation(
      address: map['address'] ?? '',
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      city: map['city'],
      state: map['state'],
      zipCode: map['zipCode'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'city': city,
      'state': state,
      'zipCode': zipCode,
    };
  }

  BusinessLocation copyWith({
    String? address,
    double? latitude,
    double? longitude,
    String? city,
    String? state,
    String? zipCode,
  }) {
    return BusinessLocation(
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      city: city ?? this.city,
      state: state ?? this.state,
      zipCode: zipCode ?? this.zipCode,
    );
  }
}

class BusinessHours {
  final bool isOpen;
  final String? openTime; // "09:00"
  final String? closeTime; // "18:00"

  BusinessHours({
    this.isOpen = false,
    this.openTime,
    this.closeTime,
  });

  factory BusinessHours.fromMap(Map<String, dynamic> map) {
    return BusinessHours(
      isOpen: map['isOpen'] ?? false,
      openTime: map['openTime'],
      closeTime: map['closeTime'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isOpen': isOpen,
      'openTime': openTime,
      'closeTime': closeTime,
    };
  }

  BusinessHours copyWith({
    bool? isOpen,
    String? openTime,
    String? closeTime,
  }) {
    return BusinessHours(
      isOpen: isOpen ?? this.isOpen,
      openTime: openTime ?? this.openTime,
      closeTime: closeTime ?? this.closeTime,
    );
  }
}

class StaffMember {
  final String providerId;
  final String role;
  final String status; // 'active', 'pending', 'inactive'
  final DateTime joinedAt;

  StaffMember({
    required this.providerId,
    required this.role,
    this.status = 'active',
    required this.joinedAt,
  });

  factory StaffMember.fromMap(Map<String, dynamic> map) {
    return StaffMember(
      providerId: map['providerId'] ?? '',
      role: map['role'] ?? '',
      status: map['status'] ?? 'active',
      joinedAt: (map['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'providerId': providerId,
      'role': role,
      'status': status,
      'joinedAt': Timestamp.fromDate(joinedAt),
    };
  }
}

class BusinessModel {
  final String id;
  final String name;
  final String? description;
  final String ownerId;
  final String? industryId;
  final BusinessLocation? location;
  final Map<String, BusinessHours> hours; // 'monday', 'tuesday', etc.
  final List<String> photos;
  final List<StaffMember> staff;
  final bool isActive;
  final double rating;
  final int reviewCount;
  final String? phone;
  final String? email;
  final String? website;
  final DateTime createdAt;
  final DateTime updatedAt;

  BusinessModel({
    required this.id,
    required this.name,
    this.description,
    required this.ownerId,
    this.industryId,
    this.location,
    this.hours = const {},
    this.photos = const [],
    this.staff = const [],
    this.isActive = true,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.phone,
    this.email,
    this.website,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BusinessModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Parse hours
    Map<String, BusinessHours> hoursMap = {};
    if (data['hours'] != null) {
      (data['hours'] as Map<String, dynamic>).forEach((key, value) {
        hoursMap[key] = BusinessHours.fromMap(value as Map<String, dynamic>);
      });
    }

    // Parse staff
    List<StaffMember> staffList = [];
    if (data['staff'] != null) {
      staffList = (data['staff'] as List<dynamic>)
          .map((s) => StaffMember.fromMap(s as Map<String, dynamic>))
          .toList();
    }

    return BusinessModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'],
      ownerId: data['ownerId'] ?? '',
      industryId: data['industryId'],
      location: data['location'] != null
          ? BusinessLocation.fromMap(data['location'])
          : null,
      hours: hoursMap,
      photos: List<String>.from(data['photos'] ?? []),
      staff: staffList,
      isActive: data['isActive'] ?? true,
      rating: (data['rating'] ?? 0.0).toDouble(),
      reviewCount: data['reviewCount'] ?? 0,
      phone: data['phone'],
      email: data['email'],
      website: data['website'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'ownerId': ownerId,
      'industryId': industryId,
      'location': location?.toMap(),
      'hours': hours.map((key, value) => MapEntry(key, value.toMap())),
      'photos': photos,
      'staff': staff.map((s) => s.toMap()).toList(),
      'isActive': isActive,
      'rating': rating,
      'reviewCount': reviewCount,
      'phone': phone,
      'email': email,
      'website': website,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Default business hours (Mon-Fri 9-6, Sat-Sun closed)
  static Map<String, BusinessHours> defaultHours() {
    return {
      'monday':
          BusinessHours(isOpen: true, openTime: '09:00', closeTime: '18:00'),
      'tuesday':
          BusinessHours(isOpen: true, openTime: '09:00', closeTime: '18:00'),
      'wednesday':
          BusinessHours(isOpen: true, openTime: '09:00', closeTime: '18:00'),
      'thursday':
          BusinessHours(isOpen: true, openTime: '09:00', closeTime: '18:00'),
      'friday':
          BusinessHours(isOpen: true, openTime: '09:00', closeTime: '18:00'),
      'saturday': BusinessHours(isOpen: false),
      'sunday': BusinessHours(isOpen: false),
    };
  }

  BusinessModel copyWith({
    String? id,
    String? name,
    String? description,
    String? ownerId,
    String? industryId,
    BusinessLocation? location,
    Map<String, BusinessHours>? hours,
    List<String>? photos,
    List<StaffMember>? staff,
    bool? isActive,
    double? rating,
    int? reviewCount,
    String? phone,
    String? email,
    String? website,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BusinessModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      ownerId: ownerId ?? this.ownerId,
      industryId: industryId ?? this.industryId,
      location: location ?? this.location,
      hours: hours ?? this.hours,
      photos: photos ?? this.photos,
      staff: staff ?? this.staff,
      isActive: isActive ?? this.isActive,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      website: website ?? this.website,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
