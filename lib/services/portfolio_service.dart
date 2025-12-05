import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'firebase_service.dart';

class PortfolioPhoto {
  final String id;
  final String url;
  final String? caption;
  final DateTime uploadedAt;

  PortfolioPhoto({
    required this.id,
    required this.url,
    this.caption,
    required this.uploadedAt,
  });

  factory PortfolioPhoto.fromMap(Map<String, dynamic> map) {
    return PortfolioPhoto(
      id: map['id'] ?? '',
      url: map['url'] ?? '',
      caption: map['caption'],
      uploadedAt: (map['uploadedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'url': url,
      'caption': caption,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
    };
  }
}

class PortfolioService {
  final FirebaseFirestore _firestore = FirebaseService.firestore;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  static const int maxPhotos = 10;
  static const int maxFileSizeMB = 5;

  /// Get portfolio photos for a user
  Future<List<PortfolioPhoto>> getPortfolio(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return [];

      final data = doc.data();
      final portfolioData = data?['portfolio'] as List<dynamic>? ?? [];

      return portfolioData
          .map((p) => PortfolioPhoto.fromMap(p as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
    } catch (e) {
      print('Error getting portfolio: $e');
      return [];
    }
  }

  /// Pick and upload a photo from gallery or camera
  Future<PortfolioPhoto?> uploadPhoto(
    String userId, {
    required ImageSource source,
    String? caption,
  }) async {
    try {
      print('DEBUG Portfolio: Starting image picker...');
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        print('DEBUG Portfolio: No image picked');
        return null;
      }

      final file = File(pickedFile.path);
      final fileSize = await file.length();
      print('DEBUG Portfolio: File size: $fileSize bytes');

      if (fileSize > maxFileSizeMB * 1024 * 1024) {
        throw 'File size exceeds ${maxFileSizeMB}MB limit';
      }

      // Check current count
      final currentPhotos = await getPortfolio(userId);
      if (currentPhotos.length >= maxPhotos) {
        throw 'Maximum $maxPhotos photos allowed';
      }

      // Upload to Firebase Storage
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}${path.extension(pickedFile.path)}';
      final storagePath = 'portfolio/$userId/$fileName';
      print('DEBUG Portfolio: Uploading to: $storagePath');

      final ref = _storage.ref(storagePath);

      // Read file as bytes (more reliable on Android)
      final bytes = await file.readAsBytes();
      print('DEBUG Portfolio: Read ${bytes.length} bytes');

      final metadata = SettableMetadata(contentType: 'image/jpeg');
      final uploadTask = ref.putData(bytes, metadata);

      // Listen to progress
      uploadTask.snapshotEvents.listen(
        (event) {
          final progress = (event.bytesTransferred / event.totalBytes) * 100;
          print(
              'DEBUG Portfolio: Upload progress: ${progress.toStringAsFixed(1)}%');
        },
        onError: (e) => print('DEBUG Portfolio: Upload error: $e'),
      );

      // Wait with timeout
      await uploadTask.timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          print('DEBUG Portfolio: Upload timed out!');
          uploadTask.cancel();
          throw 'Upload timed out. Check your internet connection.';
        },
      );

      final url = await ref.getDownloadURL();
      print('DEBUG Portfolio: Got URL: $url');

      // Create photo object
      final photo = PortfolioPhoto(
        id: fileName,
        url: url,
        caption: caption,
        uploadedAt: DateTime.now(),
      );

      // Add to Firestore
      await _firestore.collection('users').doc(userId).update({
        'portfolio': FieldValue.arrayUnion([photo.toMap()]),
      });
      print('DEBUG Portfolio: Saved to Firestore!');

      return photo;
    } catch (e) {
      print('ERROR uploading portfolio photo: $e');
      rethrow;
    }
  }

  /// Upload profile image
  Future<String?> uploadProfileImage(String userId,
      {required ImageSource source}) async {
    try {
      print('DEBUG: Starting image picker...');
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 90,
      );

      if (pickedFile == null) {
        print('DEBUG: No image picked');
        return null;
      }

      print('DEBUG: Image picked: ${pickedFile.path}');
      final file = File(pickedFile.path);
      print('DEBUG: File exists: ${await file.exists()}');
      final fileSize = await file.length();
      print('DEBUG: File size: $fileSize bytes');

      // Upload to Firebase Storage
      final storagePath =
          'profiles/$userId/profile${path.extension(pickedFile.path)}';
      print('DEBUG: Uploading to Storage path: $storagePath');
      print('DEBUG: Storage bucket: ${_storage.bucket}');

      final ref = _storage.ref(storagePath);

      print('DEBUG: Starting putFile with timeout...');

      // Read file as bytes for putData (more reliable)
      final bytes = await file.readAsBytes();
      print('DEBUG: Read ${bytes.length} bytes');

      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
      );

      final uploadTask = ref.putData(bytes, metadata);

      // Listen to upload progress
      uploadTask.snapshotEvents.listen(
        (event) {
          final progress = (event.bytesTransferred / event.totalBytes) * 100;
          print(
              'DEBUG: Upload progress: ${progress.toStringAsFixed(1)}% (${event.bytesTransferred}/${event.totalBytes})');
        },
        onError: (e) {
          print('DEBUG: Upload stream error: $e');
        },
      );

      // Wait with timeout
      final snapshot = await uploadTask.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('DEBUG: Upload timed out after 30 seconds!');
          uploadTask.cancel();
          throw 'Upload timed out. Check your internet connection and Firebase Storage configuration.';
        },
      );

      print('DEBUG: Upload complete! State: ${snapshot.state}');

      final url = await ref.getDownloadURL();
      print('DEBUG: Got URL: $url');

      // Update user profile
      print('DEBUG: Updating Firestore...');
      await _firestore.collection('users').doc(userId).update({
        'profileImageUrl': url,
      });
      print('DEBUG: Firestore updated!');

      return url;
    } catch (e, stackTrace) {
      print('ERROR uploading profile image: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Delete a portfolio photo
  Future<void> deletePhoto(String userId, PortfolioPhoto photo) async {
    try {
      // Delete from Storage
      try {
        final ref = _storage.ref('portfolio/$userId/${photo.id}');
        await ref.delete();
      } catch (e) {
        // Photo might not exist in storage, continue with Firestore removal
        print('Storage delete error: $e');
      }

      // Remove from Firestore
      await _firestore.collection('users').doc(userId).update({
        'portfolio': FieldValue.arrayRemove([photo.toMap()]),
      });
    } catch (e) {
      print('Error deleting photo: $e');
      rethrow;
    }
  }

  /// Reorder portfolio photos
  Future<void> reorderPhotos(String userId, List<PortfolioPhoto> photos) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'portfolio': photos.map((p) => p.toMap()).toList(),
      });
    } catch (e) {
      print('Error reordering photos: $e');
      rethrow;
    }
  }
}
