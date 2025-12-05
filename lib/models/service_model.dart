import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceModel {
  final String id;
  final String name;
  final String description;
  final int durationMinutes;
  final double price;
  final String currency;
  final String category;
  final String? industryId; // Taxonomy: e.g., 'beauty'
  final String? categoryId; // Taxonomy: e.g., 'hair'
  final List<String> tags; // Taxonomy: e.g., ['haircut', 'coloring']
  final String providerId;
  final String? businessId;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  ServiceModel({
    required this.id,
    required this.name,
    required this.description,
    required this.durationMinutes,
    required this.price,
    this.currency = 'USD',
    required this.category,
    this.industryId,
    this.categoryId,
    this.tags = const [],
    required this.providerId,
    this.businessId,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ServiceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ServiceModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      durationMinutes: data['durationMinutes'] ?? 0,
      price: (data['price'] ?? 0.0).toDouble(),
      currency: data['currency'] ?? 'USD',
      category: data['category'] ?? '',
      industryId: data['industryId'],
      categoryId: data['categoryId'],
      tags: List<String>.from(data['tags'] ?? []),
      providerId: data['providerId'] ?? '',
      businessId: data['businessId'],
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory ServiceModel.fromMap(Map<String, dynamic> data, String id) {
    return ServiceModel(
      id: id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      durationMinutes: data['durationMinutes'] ?? 0,
      price: (data['price'] ?? 0.0).toDouble(),
      currency: data['currency'] ?? 'USD',
      category: data['category'] ?? '',
      industryId: data['industryId'],
      categoryId: data['categoryId'],
      tags: List<String>.from(data['tags'] ?? []),
      providerId: data['providerId'] ?? '',
      businessId: data['businessId'],
      isActive: data['isActive'] ?? true,
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] is Timestamp
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'durationMinutes': durationMinutes,
      'price': price,
      'currency': currency,
      'category': category,
      'industryId': industryId,
      'categoryId': categoryId,
      'tags': tags,
      'providerId': providerId,
      'businessId': businessId,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  ServiceModel copyWith({
    String? id,
    String? name,
    String? description,
    int? durationMinutes,
    double? price,
    String? currency,
    String? category,
    String? industryId,
    String? categoryId,
    List<String>? tags,
    String? providerId,
    String? businessId,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ServiceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      category: category ?? this.category,
      industryId: industryId ?? this.industryId,
      categoryId: categoryId ?? this.categoryId,
      tags: tags ?? this.tags,
      providerId: providerId ?? this.providerId,
      businessId: businessId ?? this.businessId,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get durationDisplay {
    if (durationMinutes < 60) {
      return '$durationMinutes min';
    } else {
      final hours = durationMinutes ~/ 60;
      final mins = durationMinutes % 60;
      if (mins == 0) {
        return '$hours hr${hours > 1 ? 's' : ''}';
      } else {
        return '$hours hr${hours > 1 ? 's' : ''} $mins min';
      }
    }
  }

  String get priceDisplay {
    return '$currency ${price.toStringAsFixed(2)}';
  }
}
