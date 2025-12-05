import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/availability_model.dart';
import 'firebase_service.dart';

class AvailabilityService {
  final FirebaseFirestore _firestore = FirebaseService.firestore;

  // Collection reference
  CollectionReference get _availabilityCollection =>
      _firestore.collection('availability');

  /// Get availability for a provider
  Future<AvailabilityModel?> getAvailability(String providerId,
      {String? businessId}) async {
    try {
      Query query =
          _availabilityCollection.where('providerId', isEqualTo: providerId);

      if (businessId != null) {
        query = query.where('businessId', isEqualTo: businessId);
      } else {
        query = query.where('businessId', isNull: true);
      }

      final snapshot = await query.limit(1).get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      return AvailabilityModel.fromFirestore(snapshot.docs.first);
    } catch (e) {
      print('Error getting availability: $e');
      return null;
    }
  }

  /// Get ALL availabilities for a provider (all locations)
  Future<List<AvailabilityModel>> getAllAvailabilities(
      String providerId) async {
    try {
      final snapshot = await _availabilityCollection
          .where('providerId', isEqualTo: providerId)
          .get();

      return snapshot.docs
          .map((doc) => AvailabilityModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting all availabilities: $e');
      return [];
    }
  }

  /// Get businesses where provider is employed or owns
  Future<List<Map<String, dynamic>>> getProviderBusinesses(
      String providerId) async {
    try {
      final List<Map<String, dynamic>> businesses = [];

      // Get businesses owned by this provider
      final ownedSnapshot = await _firestore
          .collection('businesses')
          .where('ownerId', isEqualTo: providerId)
          .where('isActive', isEqualTo: true)
          .get();

      for (final doc in ownedSnapshot.docs) {
        businesses.add({
          'id': doc.id,
          'name': doc.data()['name'] ?? 'Unnamed',
          'role': 'Owner',
        });
      }

      // Get businesses where provider is staff
      final allBusinesses = await _firestore
          .collection('businesses')
          .where('isActive', isEqualTo: true)
          .get();

      for (final doc in allBusinesses.docs) {
        final staff = doc.data()['staff'] as List<dynamic>? ?? [];
        final isStaff = staff.any(
            (s) => s['providerId'] == providerId && s['status'] == 'active');

        if (isStaff && !businesses.any((b) => b['id'] == doc.id)) {
          final role =
              staff.firstWhere((s) => s['providerId'] == providerId)['role'] ??
                  'Staff';
          businesses.add({
            'id': doc.id,
            'name': doc.data()['name'] ?? 'Unnamed',
            'role': role,
          });
        }
      }

      return businesses;
    } catch (e) {
      print('Error getting provider businesses: $e');
      return [];
    }
  }

  /// Create or update availability for a provider
  Future<AvailabilityModel> saveAvailability(
      AvailabilityModel availability) async {
    try {
      final updatedAvailability =
          availability.copyWith(updatedAt: DateTime.now());

      if (availability.id.isEmpty) {
        // Create new
        final docRef = await _availabilityCollection
            .add(updatedAvailability.toFirestore());
        return updatedAvailability.copyWith(id: docRef.id);
      } else {
        // Update existing
        await _availabilityCollection
            .doc(availability.id)
            .update(updatedAvailability.toFirestore());
        return updatedAvailability;
      }
    } catch (e) {
      print('Error saving availability: $e');
      rethrow;
    }
  }

  /// Get or create default availability for a provider
  Future<AvailabilityModel> getOrCreateAvailability(String providerId,
      {String? businessId}) async {
    final existing = await getAvailability(providerId, businessId: businessId);

    if (existing != null) {
      return existing;
    }

    // Create default availability
    final defaultAvailability = AvailabilityModel.defaultSchedule(
      providerId: providerId,
      businessId: businessId,
    );

    return await saveAvailability(defaultAvailability);
  }

  /// Update weekly schedule for a single day
  Future<void> updateDaySchedule(
    String availabilityId,
    String day,
    DaySchedule schedule,
  ) async {
    try {
      await _availabilityCollection.doc(availabilityId).update({
        'weeklySchedule.$day': schedule.toMap(),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      print('Error updating day schedule: $e');
      rethrow;
    }
  }

  /// Add a date exception (holiday, day off)
  Future<void> addException(
      String availabilityId, DateException exception) async {
    try {
      await _availabilityCollection.doc(availabilityId).update({
        'exceptions': FieldValue.arrayUnion([exception.toMap()]),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      print('Error adding exception: $e');
      rethrow;
    }
  }

  /// Remove a date exception
  Future<void> removeException(String availabilityId, DateTime date) async {
    try {
      final doc = await _availabilityCollection.doc(availabilityId).get();
      if (!doc.exists) return;

      final availability = AvailabilityModel.fromFirestore(doc);
      final updatedExceptions = availability.exceptions
          .where((e) =>
              e.date.year != date.year ||
              e.date.month != date.month ||
              e.date.day != date.day)
          .toList();

      await _availabilityCollection.doc(availabilityId).update({
        'exceptions': updatedExceptions.map((e) => e.toMap()).toList(),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      print('Error removing exception: $e');
      rethrow;
    }
  }

  /// Update slot duration
  Future<void> updateSlotDuration(String availabilityId, int minutes) async {
    try {
      await _availabilityCollection.doc(availabilityId).update({
        'slotDurationMinutes': minutes,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      print('Error updating slot duration: $e');
      rethrow;
    }
  }

  /// Get available time slots for a specific date
  /// This considers the weekly schedule, exceptions, and existing bookings
  Future<List<String>> getAvailableSlots(
    String providerId,
    DateTime date, {
    String? businessId,
    List<String>? bookedSlots,
  }) async {
    try {
      final availability =
          await getAvailability(providerId, businessId: businessId);
      if (availability == null) return [];

      // Generate all possible slots for the date
      final allSlots = availability.generateSlotsForDate(date);

      // Filter out booked slots
      if (bookedSlots != null && bookedSlots.isNotEmpty) {
        return allSlots.where((slot) => !bookedSlots.contains(slot)).toList();
      }

      return allSlots;
    } catch (e) {
      print('Error getting available slots: $e');
      return [];
    }
  }

  /// Get availability stream for real-time updates
  Stream<AvailabilityModel?> availabilityStream(String providerId,
      {String? businessId}) {
    Query query =
        _availabilityCollection.where('providerId', isEqualTo: providerId);

    if (businessId != null) {
      query = query.where('businessId', isEqualTo: businessId);
    } else {
      query = query.where('businessId', isNull: true);
    }

    return query.limit(1).snapshots().map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return AvailabilityModel.fromFirestore(snapshot.docs.first);
    });
  }

  /// Get upcoming exceptions for display
  Future<List<DateException>> getUpcomingExceptions(
      String availabilityId) async {
    try {
      final doc = await _availabilityCollection.doc(availabilityId).get();
      if (!doc.exists) return [];

      final availability = AvailabilityModel.fromFirestore(doc);
      final now = DateTime.now();

      return availability.exceptions
          .where((e) => e.date.isAfter(now) || _isSameDay(e.date, now))
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));
    } catch (e) {
      print('Error getting upcoming exceptions: $e');
      return [];
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
