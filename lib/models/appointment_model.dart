import 'package:cloud_firestore/cloud_firestore.dart';

enum AppointmentStatus {
  pending, // Waiting for provider confirmation
  confirmed, // Provider accepted
  cancelled, // Cancelled by either party
  completed, // Service completed
  noShow; // Client didn't show up

  String toFirestore() => name;

  static AppointmentStatus fromFirestore(String value) {
    return AppointmentStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AppointmentStatus.pending,
    );
  }
}

class AppointmentModel {
  final String id;
  final String clientId;
  final String clientName;
  final String clientEmail;
  final String clientPhone;

  final String providerId;
  final String providerName;
  final String? businessId; // null if independent provider
  final String? businessName;

  final String serviceId;
  final String serviceName;
  final double servicePrice;
  final int serviceDuration; // in minutes

  final DateTime appointmentDate;
  final String appointmentTime; // Format: "HH:mm"

  final AppointmentStatus status;
  final String? cancellationReason;
  final String? notes;

  final DateTime createdAt;
  final DateTime? updatedAt;

  AppointmentModel({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.clientEmail,
    required this.clientPhone,
    required this.providerId,
    required this.providerName,
    this.businessId,
    this.businessName,
    required this.serviceId,
    required this.serviceName,
    required this.servicePrice,
    required this.serviceDuration,
    required this.appointmentDate,
    required this.appointmentTime,
    this.status = AppointmentStatus.pending,
    this.cancellationReason,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  factory AppointmentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return AppointmentModel(
      id: doc.id,
      clientId: data['clientId'] ?? '',
      clientName: data['clientName'] ?? '',
      clientEmail: data['clientEmail'] ?? '',
      clientPhone: data['clientPhone'] ?? '',
      providerId: data['providerId'] ?? '',
      providerName: data['providerName'] ?? '',
      businessId: data['businessId'],
      businessName: data['businessName'],
      serviceId: data['serviceId'] ?? '',
      serviceName: data['serviceName'] ?? '',
      servicePrice: (data['servicePrice'] ?? 0).toDouble(),
      serviceDuration: data['serviceDuration'] ?? 30,
      appointmentDate: (data['appointmentDate'] as Timestamp).toDate(),
      appointmentTime: data['appointmentTime'] ?? '',
      status: AppointmentStatus.fromFirestore(data['status'] ?? 'pending'),
      cancellationReason: data['cancellationReason'],
      notes: data['notes'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'clientId': clientId,
      'clientName': clientName,
      'clientEmail': clientEmail,
      'clientPhone': clientPhone,
      'providerId': providerId,
      'providerName': providerName,
      'businessId': businessId,
      'businessName': businessName,
      'serviceId': serviceId,
      'serviceName': serviceName,
      'servicePrice': servicePrice,
      'serviceDuration': serviceDuration,
      'appointmentDate': Timestamp.fromDate(appointmentDate),
      'appointmentTime': appointmentTime,
      'status': status.toFirestore(),
      'cancellationReason': cancellationReason,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  AppointmentModel copyWith({
    String? id,
    String? clientId,
    String? clientName,
    String? clientEmail,
    String? clientPhone,
    String? providerId,
    String? providerName,
    String? businessId,
    String? businessName,
    String? serviceId,
    String? serviceName,
    double? servicePrice,
    int? serviceDuration,
    DateTime? appointmentDate,
    String? appointmentTime,
    AppointmentStatus? status,
    String? cancellationReason,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppointmentModel(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      clientEmail: clientEmail ?? this.clientEmail,
      clientPhone: clientPhone ?? this.clientPhone,
      providerId: providerId ?? this.providerId,
      providerName: providerName ?? this.providerName,
      businessId: businessId ?? this.businessId,
      businessName: businessName ?? this.businessName,
      serviceId: serviceId ?? this.serviceId,
      serviceName: serviceName ?? this.serviceName,
      servicePrice: servicePrice ?? this.servicePrice,
      serviceDuration: serviceDuration ?? this.serviceDuration,
      appointmentDate: appointmentDate ?? this.appointmentDate,
      appointmentTime: appointmentTime ?? this.appointmentTime,
      status: status ?? this.status,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isPending => status == AppointmentStatus.pending;
  bool get isConfirmed => status == AppointmentStatus.confirmed;
  bool get isCancelled => status == AppointmentStatus.cancelled;
  bool get isCompleted => status == AppointmentStatus.completed;

  /// Get full datetime
  DateTime get dateTime {
    final parts = appointmentTime.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    return DateTime(
      appointmentDate.year,
      appointmentDate.month,
      appointmentDate.day,
      hour,
      minute,
    );
  }

  /// Check if appointment is in the past
  bool get isPast => dateTime.isBefore(DateTime.now());

  /// Check if appointment is today
  bool get isToday {
    final now = DateTime.now();
    return appointmentDate.year == now.year &&
        appointmentDate.month == now.month &&
        appointmentDate.day == now.day;
  }
}
