import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/service_model.dart';
import '../models/user_model.dart';
import 'firebase_service.dart';

class ProviderService {
  final FirebaseFirestore _firestore = FirebaseService.firestore;

  // ============================================
  // Services CRUD Operations
  // ============================================

  /// Create a new service
  Future<ServiceModel> createService({
    required String name,
    required String description,
    required int durationMinutes,
    required double price,
    required String currency,
    required String category,
    required String providerId,
    String? businessId,
    String? industryId,
    String? categoryId,
    List<String>? tags,
  }) async {
    final now = DateTime.now();
    final docRef = _firestore.collection('services').doc();

    final service = ServiceModel(
      id: docRef.id,
      name: name,
      description: description,
      durationMinutes: durationMinutes,
      price: price,
      currency: currency,
      category: category,
      industryId: industryId,
      categoryId: categoryId,
      tags: tags ?? [],
      providerId: providerId,
      businessId: businessId,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    );

    await docRef.set(service.toFirestore());
    return service;
  }

  /// Get a service by ID
  Future<ServiceModel?> getService(String serviceId) async {
    try {
      final doc = await _firestore.collection('services').doc(serviceId).get();
      if (doc.exists) {
        return ServiceModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting service: $e');
      return null;
    }
  }

  /// Get all services for a provider
  Future<List<ServiceModel>> getServicesForProvider(String providerId) async {
    try {
      final query = await _firestore
          .collection('services')
          .where('providerId', isEqualTo: providerId)
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .get();

      return query.docs.map((doc) => ServiceModel.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error getting services for provider: $e');
      return [];
    }
  }

  /// Get all services for a business
  Future<List<ServiceModel>> getServicesForBusiness(String businessId) async {
    try {
      final query = await _firestore
          .collection('services')
          .where('businessId', isEqualTo: businessId)
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .get();

      return query.docs.map((doc) => ServiceModel.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error getting services for business: $e');
      return [];
    }
  }

  /// Get services by category
  Future<List<ServiceModel>> getServicesByCategory(String category) async {
    try {
      final query = await _firestore
          .collection('services')
          .where('category', isEqualTo: category)
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .get();

      return query.docs.map((doc) => ServiceModel.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error getting services by category: $e');
      return [];
    }
  }

  /// Update a service
  Future<void> updateService(
    String serviceId,
    Map<String, dynamic> updates,
  ) async {
    updates['updatedAt'] = Timestamp.fromDate(DateTime.now());
    await _firestore.collection('services').doc(serviceId).update(updates);
  }

  /// Delete a service (soft delete)
  Future<void> deleteService(String serviceId) async {
    await _firestore.collection('services').doc(serviceId).update({
      'isActive': false,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Stream of services for a provider (real-time)
  Stream<List<ServiceModel>> servicesStream(String providerId) {
    return _firestore
        .collection('services')
        .where('providerId', isEqualTo: providerId)
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ServiceModel.fromFirestore(doc))
          .toList();
    });
  }

  // ============================================
  // Provider Profile Operations
  // ============================================

  /// Get provider profile
  Future<UserModel?> getProviderProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting provider profile: $e');
      return null;
    }
  }

  /// Update provider profile
  Future<void> updateProviderProfile(
    String userId,
    Map<String, dynamic> updates,
  ) async {
    await _firestore.collection('users').doc(userId).update(updates);
  }

  /// Update provider availability
  Future<void> updateAvailability(String userId, bool isAvailable) async {
    await _firestore.collection('users').doc(userId).update({
      'isAvailable': isAvailable,
    });
  }

  /// Search providers by work mode
  Future<List<UserModel>> searchProvidersByWorkMode(WorkMode workMode) async {
    try {
      final query = await _firestore
          .collection('users')
          .where('workMode', isEqualTo: workMode.toFirestore())
          .where('isAvailable', isEqualTo: true)
          .limit(50)
          .get();

      return query.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error searching providers by work mode: $e');
      return [];
    }
  }

  /// Search providers by specialty (legacy - use searchProvidersByIndustry)
  Future<List<UserModel>> searchProvidersBySpecialty(String specialty) async {
    try {
      final query = await _firestore
          .collection('users')
          .where('specialties', arrayContains: specialty)
          .where('isAvailable', isEqualTo: true)
          .limit(50)
          .get();

      return query.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error searching providers by specialty: $e');
      return [];
    }
  }

  /// Search providers by industry (uses taxonomy)
  Future<List<UserModel>> searchProvidersByIndustry(String industryId) async {
    try {
      final query = await _firestore
          .collection('users')
          .where('industries', arrayContains: industryId)
          .where('isAvailable', isEqualTo: true)
          .limit(50)
          .get();

      return query.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error searching providers by industry: $e');
      return [];
    }
  }

  /// Get all available providers
  Future<List<UserModel>> getAvailableProviders({int limit = 50}) async {
    try {
      final query = await _firestore
          .collection('users')
          .where('isAvailable', isEqualTo: true)
          .limit(limit)
          .get();

      return query.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error getting available providers: $e');
      return [];
    }
  }

  /// Get providers working at a specific business
  Future<List<UserModel>> getProvidersForBusiness(String businessId) async {
    try {
      final query = await _firestore
          .collection('users')
          .where('businessIds', arrayContains: businessId)
          .get();

      return query.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error getting providers for business: $e');
      return [];
    }
  }

  // ============================================
  // Helper Methods
  // ============================================

  /// Get service categories (unique categories from all services)
  Future<List<String>> getServiceCategories() async {
    try {
      final query = await _firestore
          .collection('services')
          .where('isActive', isEqualTo: true)
          .get();

      final categories = <String>{};
      for (final doc in query.docs) {
        final category = doc.data()['category'] as String?;
        if (category != null && category.isNotEmpty) {
          categories.add(category);
        }
      }

      final list = categories.toList()..sort();
      return list;
    } catch (e) {
      print('Error getting service categories: $e');
      return [];
    }
  }

  /// Get unique specialties from all providers
  Future<List<String>> getAllSpecialties() async {
    try {
      final query = await _firestore.collection('users').get();

      final specialties = <String>{};
      for (final doc in query.docs) {
        final userSpecialties = doc.data()['specialties'] as List<dynamic>?;
        if (userSpecialties != null) {
          specialties.addAll(userSpecialties.cast<String>());
        }
      }

      final list = specialties.toList()..sort();
      return list;
    } catch (e) {
      print('Error getting all specialties: $e');
      return [];
    }
  }
}
