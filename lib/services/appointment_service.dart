import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/appointment_model.dart';
import '../models/service_model.dart';
import '../models/user_model.dart';
import 'firebase_service.dart';
import 'availability_service.dart';

class AppointmentService {
  final FirebaseFirestore _firestore = FirebaseService.firestore;
  final _availabilityService = AvailabilityService();

  /// Create a new appointment
  Future<AppointmentModel> createAppointment({
    required UserModel client,
    required UserModel provider,
    required ServiceModel service,
    required DateTime date,
    required String time,
    String? businessId,
    String? businessName,
    String? notes,
  }) async {
    // Check if slot is available
    final isAvailable = await _isSlotAvailable(
      provider.id,
      date,
      time,
      businessId: businessId,
    );

    if (!isAvailable) {
      throw 'This time slot is no longer available';
    }

    final docRef = _firestore.collection('appointments').doc();

    final appointment = AppointmentModel(
      id: docRef.id,
      clientId: client.id,
      clientName: client.businessName,
      clientEmail: client.email,
      clientPhone: client.phoneNumber ?? '',
      providerId: provider.id,
      providerName: provider.businessName,
      businessId: businessId,
      businessName: businessName,
      serviceId: service.id,
      serviceName: service.name,
      servicePrice: service.price,
      serviceDuration: service.durationMinutes,
      appointmentDate: date,
      appointmentTime: time,
      status: AppointmentStatus.pending,
      notes: notes,
      createdAt: DateTime.now(),
    );

    await docRef.set(appointment.toFirestore());
    print('DEBUG: Appointment created: ${appointment.id}');

    return appointment;
  }

  /// Check if a time slot is available
  Future<bool> _isSlotAvailable(
    String providerId,
    DateTime date,
    String time, {
    String? businessId,
  }) async {
    try {
      // Check availability schedule
      final slots = await _availabilityService.getAvailableSlots(
        providerId,
        date,
        businessId: businessId,
      );

      if (!slots.contains(time)) {
        return false; // Not in available slots
      }

      // Check for existing appointments at this time
      final existingAppointments = await _firestore
          .collection('appointments')
          .where('providerId', isEqualTo: providerId)
          .where('appointmentDate', isEqualTo: Timestamp.fromDate(date))
          .where('appointmentTime', isEqualTo: time)
          .where('status', whereIn: ['pending', 'confirmed']).get();

      return existingAppointments.docs.isEmpty;
    } catch (e) {
      print('ERROR checking slot availability: $e');
      return false;
    }
  }

  /// Get available time slots for a provider on a specific date
  Future<List<String>> getAvailableSlots(
    String providerId,
    DateTime date, {
    String? businessId,
  }) async {
    try {
      // Get all slots from availability
      final allSlots = await _availabilityService.getAvailableSlots(
        providerId,
        date,
        businessId: businessId,
      );

      // Get booked slots
      final bookedAppointments = await _firestore
          .collection('appointments')
          .where('providerId', isEqualTo: providerId)
          .where('appointmentDate', isEqualTo: Timestamp.fromDate(date))
          .where('status', whereIn: ['pending', 'confirmed']).get();

      final bookedSlots = bookedAppointments.docs
          .map((doc) => AppointmentModel.fromFirestore(doc).appointmentTime)
          .toSet();

      // Filter out booked slots
      return allSlots.where((slot) => !bookedSlots.contains(slot)).toList();
    } catch (e) {
      print('ERROR getting available slots: $e');
      return [];
    }
  }

  /// Get appointments for a client
  Future<List<AppointmentModel>> getClientAppointments(String clientId) async {
    try {
      final snapshot = await _firestore
          .collection('appointments')
          .where('clientId', isEqualTo: clientId)
          .get();

      final appointments = snapshot.docs
          .map((doc) => AppointmentModel.fromFirestore(doc))
          .toList();

      // Sort by date descending
      appointments.sort((a, b) => b.dateTime.compareTo(a.dateTime));

      return appointments;
    } catch (e) {
      print('ERROR getting client appointments: $e');
      return [];
    }
  }

  /// Get appointments for a provider
  Future<List<AppointmentModel>> getProviderAppointments(
      String providerId) async {
    try {
      final snapshot = await _firestore
          .collection('appointments')
          .where('providerId', isEqualTo: providerId)
          .get();

      final appointments = snapshot.docs
          .map((doc) => AppointmentModel.fromFirestore(doc))
          .toList();

      // Sort by date ascending (upcoming first)
      appointments.sort((a, b) => a.dateTime.compareTo(b.dateTime));

      return appointments;
    } catch (e) {
      print('ERROR getting provider appointments: $e');
      return [];
    }
  }

  /// Get upcoming appointments for a provider
  Future<List<AppointmentModel>> getUpcomingAppointments(
      String providerId) async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final snapshot = await _firestore
          .collection('appointments')
          .where('providerId', isEqualTo: providerId)
          .where('appointmentDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(today))
          .where('status', whereIn: ['pending', 'confirmed']).get();

      final appointments = snapshot.docs
          .map((doc) => AppointmentModel.fromFirestore(doc))
          .toList();

      appointments.sort((a, b) => a.dateTime.compareTo(b.dateTime));

      return appointments;
    } catch (e) {
      print('ERROR getting upcoming appointments: $e');
      return [];
    }
  }

  /// Update appointment status
  Future<void> updateAppointmentStatus(
    String appointmentId,
    AppointmentStatus status, {
    String? cancellationReason,
  }) async {
    final updates = {
      'status': status.toFirestore(),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    };

    if (cancellationReason != null) {
      updates['cancellationReason'] = cancellationReason;
    }

    await _firestore
        .collection('appointments')
        .doc(appointmentId)
        .update(updates);
    print('DEBUG: Appointment $appointmentId status updated to $status');
  }

  /// Cancel appointment
  Future<void> cancelAppointment(
    String appointmentId, {
    String? reason,
  }) async {
    await updateAppointmentStatus(
      appointmentId,
      AppointmentStatus.cancelled,
      cancellationReason: reason,
    );
  }

  /// Confirm appointment (provider accepts)
  Future<void> confirmAppointment(String appointmentId) async {
    await updateAppointmentStatus(
      appointmentId,
      AppointmentStatus.confirmed,
    );
  }

  /// Complete appointment
  Future<void> completeAppointment(String appointmentId) async {
    await updateAppointmentStatus(
      appointmentId,
      AppointmentStatus.completed,
    );
  }

  /// Mark as no-show
  Future<void> markNoShow(String appointmentId) async {
    await updateAppointmentStatus(
      appointmentId,
      AppointmentStatus.noShow,
    );
  }

  /// Get appointment by ID
  Future<AppointmentModel?> getAppointment(String appointmentId) async {
    try {
      final doc =
          await _firestore.collection('appointments').doc(appointmentId).get();
      if (!doc.exists) return null;
      return AppointmentModel.fromFirestore(doc);
    } catch (e) {
      print('ERROR getting appointment: $e');
      return null;
    }
  }

  /// Stream appointments for provider (real-time)
  Stream<List<AppointmentModel>> providerAppointmentsStream(String providerId) {
    return _firestore
        .collection('appointments')
        .where('providerId', isEqualTo: providerId)
        .snapshots()
        .map((snapshot) {
      final appointments = snapshot.docs
          .map((doc) => AppointmentModel.fromFirestore(doc))
          .toList();
      appointments.sort((a, b) => a.dateTime.compareTo(b.dateTime));
      return appointments;
    });
  }

  /// Stream appointments for client (real-time)
  Stream<List<AppointmentModel>> clientAppointmentsStream(String clientId) {
    return _firestore
        .collection('appointments')
        .where('clientId', isEqualTo: clientId)
        .snapshots()
        .map((snapshot) {
      final appointments = snapshot.docs
          .map((doc) => AppointmentModel.fromFirestore(doc))
          .toList();
      appointments.sort((a, b) => b.dateTime.compareTo(a.dateTime));
      return appointments;
    });
  }
}
