import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/business_model.dart';
import '../models/service_model.dart';
import 'firebase_service.dart';

enum SearchType { providers, businesses, services }

class SearchFilter {
  final double? maxPrice;
  final double? minRating;
  final double? maxDistance; // in km
  final String? industryId;
  final bool? availableNow;

  SearchFilter({
    this.maxPrice,
    this.minRating,
    this.maxDistance,
    this.industryId,
    this.availableNow,
  });
}

class SearchService {
  final FirebaseFirestore _firestore = FirebaseService.firestore;

  /// Search providers by query (name, service, industry)
  Future<List<UserModel>> searchProviders(
    String query, {
    SearchFilter? filter,
  }) async {
    try {
      Query providersQuery = _firestore.collection('users');

      // Search by business name (contains query)
      if (query.isNotEmpty) {
        final queryLower = query.toLowerCase();
        providersQuery = providersQuery
            .where('businessName', isGreaterThanOrEqualTo: queryLower)
            .where('businessName', isLessThan: '${queryLower}z');
      }

      final snapshot = await providersQuery.limit(50).get();
      var results =
          snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();

      // Apply filters
      if (filter != null) {
        if (filter.industryId != null) {
          results = results
              .where((p) => p.industries.contains(filter.industryId))
              .toList();
        }

        // TODO: Add other filters when we have that data
      }

      return results;
    } catch (e) {
      print('ERROR searching providers: $e');
      return [];
    }
  }

  /// Search businesses by query
  Future<List<BusinessModel>> searchBusinesses(
    String query, {
    SearchFilter? filter,
  }) async {
    try {
      Query businessQuery = _firestore
          .collection('businesses')
          .where('isActive', isEqualTo: true);

      if (query.isNotEmpty) {
        final queryLower = query.toLowerCase();
        businessQuery = businessQuery
            .where('name', isGreaterThanOrEqualTo: queryLower)
            .where('name', isLessThan: '${queryLower}z');
      }

      final snapshot = await businessQuery.limit(50).get();
      var results =
          snapshot.docs.map((doc) => BusinessModel.fromFirestore(doc)).toList();

      // Apply filters
      if (filter != null) {
        if (filter.minRating != null) {
          results =
              results.where((b) => b.rating >= filter.minRating!).toList();
        }

        if (filter.industryId != null) {
          results =
              results.where((b) => b.industryId == filter.industryId).toList();
        }
      }

      // Sort by rating
      results.sort((a, b) => b.rating.compareTo(a.rating));

      return results;
    } catch (e) {
      print('ERROR searching businesses: $e');
      return [];
    }
  }

  /// Search services
  Future<List<ServiceModel>> searchServices(
    String query, {
    SearchFilter? filter,
  }) async {
    try {
      Query servicesQuery = _firestore.collection('services');

      if (query.isNotEmpty) {
        final queryLower = query.toLowerCase();
        servicesQuery = servicesQuery
            .where('name', isGreaterThanOrEqualTo: queryLower)
            .where('name', isLessThan: '${queryLower}z');
      }

      final snapshot = await servicesQuery.limit(50).get();
      var results =
          snapshot.docs.map((doc) => ServiceModel.fromFirestore(doc)).toList();

      // Apply filters
      if (filter != null) {
        if (filter.maxPrice != null) {
          results = results.where((s) => s.price <= filter.maxPrice!).toList();
        }

        if (filter.industryId != null) {
          results =
              results.where((s) => s.industryId == filter.industryId).toList();
        }
      }

      return results;
    } catch (e) {
      print('ERROR searching services: $e');
      return [];
    }
  }

  /// Get featured providers (high rating, active)
  Future<List<UserModel>> getFeaturedProviders({int limit = 10}) async {
    try {
      // For now, just get recent providers
      // TODO: Add rating/featured logic later
      final snapshot = await _firestore
          .collection('users')
          .where('isAvailable', isEqualTo: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
    } catch (e) {
      print('ERROR getting featured providers: $e');
      return [];
    }
  }

  /// Get featured businesses
  Future<List<BusinessModel>> getFeaturedBusinesses({int limit = 10}) async {
    try {
      final snapshot = await _firestore
          .collection('businesses')
          .where('isActive', isEqualTo: true)
          .limit(limit)
          .get();

      var results =
          snapshot.docs.map((doc) => BusinessModel.fromFirestore(doc)).toList();

      // Sort by rating
      results.sort((a, b) => b.rating.compareTo(a.rating));

      return results.take(limit).toList();
    } catch (e) {
      print('ERROR getting featured businesses: $e');
      return [];
    }
  }

  /// Get provider's services
  Future<List<ServiceModel>> getProviderServices(String providerId) async {
    try {
      final snapshot = await _firestore
          .collection('services')
          .where('providerId', isEqualTo: providerId)
          .get();

      return snapshot.docs
          .map((doc) => ServiceModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('ERROR getting provider services: $e');
      return [];
    }
  }
}
