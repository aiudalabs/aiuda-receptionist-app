import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceModel {
  final String id;
  final String userId;
  final String name;
  final int durationMinutes;
  final double? price;
  final DateTime createdAt;

  ServiceModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.durationMinutes,
    this.price,
    required this.createdAt,
  });

  factory ServiceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ServiceModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      durationMinutes: data['durationMinutes'] ?? 30,
      price: data['price']?.toDouble(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'name': name,
      'durationMinutes': durationMinutes,
      'price': price,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
