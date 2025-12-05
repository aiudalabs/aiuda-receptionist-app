import 'package:cloud_firestore/cloud_firestore.dart';

enum InvitationStatus { pending, accepted, rejected, cancelled }

class InvitationModel {
  final String id;
  final String businessId;
  final String businessName;
  final String fromProviderId; // Owner who sent
  final String fromProviderName;
  final String toProviderId; // Provider being invited
  final String toProviderName;
  final String toProviderEmail;
  final String role; // 'stylist', 'barber', 'technician', etc.
  final InvitationStatus status;
  final String? message;
  final DateTime sentAt;
  final DateTime? respondedAt;

  InvitationModel({
    required this.id,
    required this.businessId,
    required this.businessName,
    required this.fromProviderId,
    required this.fromProviderName,
    required this.toProviderId,
    required this.toProviderName,
    required this.toProviderEmail,
    required this.role,
    this.status = InvitationStatus.pending,
    this.message,
    required this.sentAt,
    this.respondedAt,
  });

  factory InvitationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return InvitationModel(
      id: doc.id,
      businessId: data['businessId'] ?? '',
      businessName: data['businessName'] ?? '',
      fromProviderId: data['fromProviderId'] ?? '',
      fromProviderName: data['fromProviderName'] ?? '',
      toProviderId: data['toProviderId'] ?? '',
      toProviderName: data['toProviderName'] ?? '',
      toProviderEmail: data['toProviderEmail'] ?? '',
      role: data['role'] ?? '',
      status: _parseStatus(data['status']),
      message: data['message'],
      sentAt: (data['sentAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      respondedAt: (data['respondedAt'] as Timestamp?)?.toDate(),
    );
  }

  static InvitationStatus _parseStatus(String? status) {
    switch (status) {
      case 'pending':
        return InvitationStatus.pending;
      case 'accepted':
        return InvitationStatus.accepted;
      case 'rejected':
        return InvitationStatus.rejected;
      case 'cancelled':
        return InvitationStatus.cancelled;
      default:
        return InvitationStatus.pending;
    }
  }

  Map<String, dynamic> toFirestore() {
    return {
      'businessId': businessId,
      'businessName': businessName,
      'fromProviderId': fromProviderId,
      'fromProviderName': fromProviderName,
      'toProviderId': toProviderId,
      'toProviderName': toProviderName,
      'toProviderEmail': toProviderEmail,
      'role': role,
      'status': status.name,
      'message': message,
      'sentAt': Timestamp.fromDate(sentAt),
      'respondedAt':
          respondedAt != null ? Timestamp.fromDate(respondedAt!) : null,
    };
  }

  bool get isPending => status == InvitationStatus.pending;
  bool get isAccepted => status == InvitationStatus.accepted;
  bool get isRejected => status == InvitationStatus.rejected;
}
