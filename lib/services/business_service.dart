import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import '../models/business_model.dart';
import 'firebase_service.dart';

class BusinessService {
  final FirebaseFirestore _firestore = FirebaseService.firestore;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  static const int maxPhotos = 10;

  /// Create a new business
  Future<BusinessModel> createBusiness({
    required String ownerId,
    required String name,
    String? description,
    String? industryId,
    BusinessLocation? location,
    Map<String, BusinessHours>? hours,
    String? phone,
    String? email,
  }) async {
    final now = DateTime.now();

    final docRef = _firestore.collection('businesses').doc();

    final business = BusinessModel(
      id: docRef.id,
      name: name,
      description: description,
      ownerId: ownerId,
      industryId: industryId,
      location: location,
      hours: hours ?? BusinessModel.defaultHours(),
      photos: [],
      staff: [],
      isActive: true,
      createdAt: now,
      updatedAt: now,
    );

    await docRef.set(business.toFirestore());

    // Update user's businessIds
    await _firestore.collection('users').doc(ownerId).update({
      'businessIds': FieldValue.arrayUnion([docRef.id]),
    });

    return business;
  }

  /// Get a business by ID
  Future<BusinessModel?> getBusiness(String businessId) async {
    try {
      final doc =
          await _firestore.collection('businesses').doc(businessId).get();
      if (!doc.exists) return null;
      return BusinessModel.fromFirestore(doc);
    } catch (e) {
      print('Error getting business: $e');
      return null;
    }
  }

  /// Get all businesses owned by a user
  Future<List<BusinessModel>> getMyBusinesses(String ownerId) async {
    try {
      print('DEBUG: Getting businesses for owner: $ownerId');
      final snapshot = await _firestore
          .collection('businesses')
          .where('ownerId', isEqualTo: ownerId)
          .get();

      print('DEBUG: Found ${snapshot.docs.length} businesses');

      final businesses =
          snapshot.docs.map((doc) => BusinessModel.fromFirestore(doc)).toList();

      // Sort by createdAt descending (in memory instead of Firestore)
      businesses.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return businesses;
    } catch (e) {
      print('ERROR getting businesses: $e');
      return [];
    }
  }

  /// Update business info
  Future<void> updateBusiness(
      String businessId, Map<String, dynamic> updates) async {
    updates['updatedAt'] = Timestamp.fromDate(DateTime.now());
    await _firestore.collection('businesses').doc(businessId).update(updates);
  }

  /// Update business hours
  Future<void> updateHours(
      String businessId, Map<String, BusinessHours> hours) async {
    await updateBusiness(businessId, {
      'hours': hours.map((key, value) => MapEntry(key, value.toMap())),
    });
  }

  /// Update business location
  Future<void> updateLocation(
      String businessId, BusinessLocation location) async {
    await updateBusiness(businessId, {
      'location': location.toMap(),
    });
  }

  /// Upload a business photo
  Future<String?> uploadPhoto(String businessId,
      {required ImageSource source}) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (pickedFile == null) return null;

      final file = File(pickedFile.path);
      final bytes = await file.readAsBytes();

      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}${path.extension(pickedFile.path)}';
      final storagePath = 'businesses/$businessId/$fileName';

      final ref = _storage.ref(storagePath);
      final metadata = SettableMetadata(contentType: 'image/jpeg');

      await ref.putData(bytes, metadata).timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw 'Upload timed out';
        },
      );

      final url = await ref.getDownloadURL();

      // Add to business photos array
      await _firestore.collection('businesses').doc(businessId).update({
        'photos': FieldValue.arrayUnion([url]),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      return url;
    } catch (e) {
      print('Error uploading business photo: $e');
      rethrow;
    }
  }

  /// Remove a photo from business
  Future<void> removePhoto(String businessId, String photoUrl) async {
    await _firestore.collection('businesses').doc(businessId).update({
      'photos': FieldValue.arrayRemove([photoUrl]),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Delete business (soft delete)
  Future<void> deleteBusiness(String businessId, String ownerId) async {
    await _firestore.collection('businesses').doc(businessId).update({
      'isActive': false,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });

    // Remove from user's businessIds
    await _firestore.collection('users').doc(ownerId).update({
      'businessIds': FieldValue.arrayRemove([businessId]),
    });
  }

  /// Stream of businesses for real-time updates
  Stream<List<BusinessModel>> businessesStream(String ownerId) {
    return _firestore
        .collection('businesses')
        .where('ownerId', isEqualTo: ownerId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BusinessModel.fromFirestore(doc))
            .toList());
  }

  /// Get business count for owner
  Future<int> getBusinessCount(String ownerId) async {
    final snapshot = await _firestore
        .collection('businesses')
        .where('ownerId', isEqualTo: ownerId)
        .where('isActive', isEqualTo: true)
        .count()
        .get();
    return snapshot.count ?? 0;
  }
}
