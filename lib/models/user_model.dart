import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String email;
  final String businessName;
  final String timezone;
  final List<String> fcmTokens;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.email,
    required this.businessName,
    required this.timezone,
    this.fcmTokens = const [],
    required this.createdAt,
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
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'businessName': businessName,
      'timezone': timezone,
      'fcmTokens': fcmTokens,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? businessName,
    String? timezone,
    List<String>? fcmTokens,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      businessName: businessName ?? this.businessName,
      timezone: timezone ?? this.timezone,
      fcmTokens: fcmTokens ?? this.fcmTokens,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
