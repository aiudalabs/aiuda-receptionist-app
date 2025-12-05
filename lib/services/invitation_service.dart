import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/invitation_model.dart';
import '../models/user_model.dart';
import '../models/business_model.dart';
import 'firebase_service.dart';

class InvitationService {
  final FirebaseFirestore _firestore = FirebaseService.firestore;

  /// Search providers by name or email
  Future<List<UserModel>> searchProviders(String query,
      {String? excludeBusinessId}) async {
    if (query.trim().length < 2) return [];

    try {
      final queryLower = query.toLowerCase().trim();
      print('DEBUG: Searching providers with query: $queryLower');

      // Search by email (exact match prefix)
      final emailResults = await _firestore
          .collection('users')
          .where('email', isGreaterThanOrEqualTo: queryLower)
          .where('email', isLessThan: '${queryLower}z')
          .limit(10)
          .get();

      // Search by name (using businessName)
      final nameResults = await _firestore
          .collection('users')
          .where('businessName', isGreaterThanOrEqualTo: query)
          .where('businessName', isLessThan: '${query}z')
          .limit(10)
          .get();

      // Combine and dedupe results
      final Map<String, UserModel> resultsMap = {};

      for (final doc in [...emailResults.docs, ...nameResults.docs]) {
        if (!resultsMap.containsKey(doc.id)) {
          resultsMap[doc.id] = UserModel.fromFirestore(doc);
        }
      }

      print('DEBUG: Found ${resultsMap.length} providers');
      return resultsMap.values.toList();
    } catch (e) {
      print('ERROR searching providers: $e');
      return [];
    }
  }

  /// Send an invitation to a provider
  Future<InvitationModel> sendInvitation({
    required BusinessModel business,
    required UserModel fromProvider,
    required UserModel toProvider,
    required String role,
    String? message,
  }) async {
    // Check if already invited
    final existing = await _firestore
        .collection('invitations')
        .where('businessId', isEqualTo: business.id)
        .where('toProviderId', isEqualTo: toProvider.id)
        .where('status', isEqualTo: 'pending')
        .get();

    if (existing.docs.isNotEmpty) {
      throw 'This provider already has a pending invitation';
    }

    // Check if already a member
    final isMember = business.staff.any((s) => s.providerId == toProvider.id);
    if (isMember) {
      throw 'This provider is already a team member';
    }

    final docRef = _firestore.collection('invitations').doc();
    final invitation = InvitationModel(
      id: docRef.id,
      businessId: business.id,
      businessName: business.name,
      fromProviderId: fromProvider.id,
      fromProviderName: fromProvider.businessName.isNotEmpty
          ? fromProvider.businessName
          : 'Business Owner',
      toProviderId: toProvider.id,
      toProviderName: toProvider.businessName.isNotEmpty
          ? toProvider.businessName
          : 'Provider',
      toProviderEmail: toProvider.email,
      role: role,
      status: InvitationStatus.pending,
      message: message,
      sentAt: DateTime.now(),
    );

    await docRef.set(invitation.toFirestore());
    print('DEBUG: Invitation sent to ${toProvider.businessName}');

    return invitation;
  }

  /// Get invitations received by a provider
  Future<List<InvitationModel>> getReceivedInvitations(
      String providerId) async {
    try {
      final snapshot = await _firestore
          .collection('invitations')
          .where('toProviderId', isEqualTo: providerId)
          .get();

      final invitations = snapshot.docs
          .map((doc) => InvitationModel.fromFirestore(doc))
          .toList();

      // Sort: pending first, then by date
      invitations.sort((a, b) {
        if (a.isPending && !b.isPending) return -1;
        if (!a.isPending && b.isPending) return 1;
        return b.sentAt.compareTo(a.sentAt);
      });

      return invitations;
    } catch (e) {
      print('ERROR getting invitations: $e');
      return [];
    }
  }

  /// Get invitations sent by a business
  Future<List<InvitationModel>> getSentInvitations(String businessId) async {
    try {
      final snapshot = await _firestore
          .collection('invitations')
          .where('businessId', isEqualTo: businessId)
          .get();

      return snapshot.docs
          .map((doc) => InvitationModel.fromFirestore(doc))
          .toList()
        ..sort((a, b) => b.sentAt.compareTo(a.sentAt));
    } catch (e) {
      print('ERROR getting sent invitations: $e');
      return [];
    }
  }

  /// Accept an invitation
  Future<void> acceptInvitation(InvitationModel invitation) async {
    final batch = _firestore.batch();

    // Update invitation status
    batch.update(
      _firestore.collection('invitations').doc(invitation.id),
      {
        'status': 'accepted',
        'respondedAt': Timestamp.fromDate(DateTime.now()),
      },
    );

    // Add to business staff
    batch.update(
      _firestore.collection('businesses').doc(invitation.businessId),
      {
        'staff': FieldValue.arrayUnion([
          {
            'providerId': invitation.toProviderId,
            'role': invitation.role,
            'status': 'active',
            'joinedAt': Timestamp.fromDate(DateTime.now()),
          }
        ]),
      },
    );

    // Add business to user's employedAt
    batch.update(
      _firestore.collection('users').doc(invitation.toProviderId),
      {
        'employedAt': FieldValue.arrayUnion([invitation.businessId]),
      },
    );

    await batch.commit();
    print('DEBUG: Invitation accepted');
  }

  /// Reject an invitation
  Future<void> rejectInvitation(String invitationId) async {
    await _firestore.collection('invitations').doc(invitationId).update({
      'status': 'rejected',
      'respondedAt': Timestamp.fromDate(DateTime.now()),
    });
    print('DEBUG: Invitation rejected');
  }

  /// Cancel an invitation (by owner)
  Future<void> cancelInvitation(String invitationId) async {
    await _firestore.collection('invitations').doc(invitationId).update({
      'status': 'cancelled',
      'respondedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Remove staff member from business
  Future<void> removeStaffMember(String businessId, String providerId) async {
    // Get current staff
    final businessDoc =
        await _firestore.collection('businesses').doc(businessId).get();
    final data = businessDoc.data();
    if (data == null) return;

    final staff = (data['staff'] as List<dynamic>?) ?? [];
    final updatedStaff =
        staff.where((s) => s['providerId'] != providerId).toList();

    final batch = _firestore.batch();

    // Update business staff
    batch.update(
      _firestore.collection('businesses').doc(businessId),
      {'staff': updatedStaff},
    );

    // Remove from user's employedAt
    batch.update(
      _firestore.collection('users').doc(providerId),
      {
        'employedAt': FieldValue.arrayRemove([businessId]),
      },
    );

    await batch.commit();
    print('DEBUG: Staff member removed');
  }

  /// Get count of pending invitations for a provider
  Future<int> getPendingInvitationCount(String providerId) async {
    final snapshot = await _firestore
        .collection('invitations')
        .where('toProviderId', isEqualTo: providerId)
        .where('status', isEqualTo: 'pending')
        .count()
        .get();
    return snapshot.count ?? 0;
  }
}
