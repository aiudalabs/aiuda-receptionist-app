import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/invitation_service.dart';
import '../../models/invitation_model.dart';

class InvitationsScreen extends StatefulWidget {
  const InvitationsScreen({super.key});

  @override
  State<InvitationsScreen> createState() => _InvitationsScreenState();
}

class _InvitationsScreenState extends State<InvitationsScreen> {
  final _invitationService = InvitationService();
  List<InvitationModel> _invitations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInvitations();
  }

  Future<void> _loadInvitations() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.currentUser?.uid;

    if (userId == null) return;

    setState(() => _isLoading = true);

    try {
      final invitations =
          await _invitationService.getReceivedInvitations(userId);
      if (mounted) {
        setState(() {
          _invitations = invitations;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _acceptInvitation(InvitationModel invitation) async {
    try {
      await _invitationService.acceptInvitation(invitation);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You joined ${invitation.businessName}!'),
          backgroundColor: Colors.green,
        ),
      );
      _loadInvitations();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _rejectInvitation(InvitationModel invitation) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Decline Invitation'),
        content: Text('Decline invitation from ${invitation.businessName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Decline'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _invitationService.rejectInvitation(invitation.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invitation declined')),
        );
        _loadInvitations();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invitations'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _invitations.isEmpty
              ? _buildEmptyState()
              : _buildInvitationsList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.mail_outline, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No invitations',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'When businesses invite you to join their team,\nyou\'ll see them here',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildInvitationsList() {
    final pending = _invitations.where((i) => i.isPending).toList();
    final responded = _invitations.where((i) => !i.isPending).toList();

    return RefreshIndicator(
      onRefresh: _loadInvitations,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (pending.isNotEmpty) ...[
            Text(
              'Pending',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            ...pending.map((inv) => _InvitationCard(
                  invitation: inv,
                  onAccept: () => _acceptInvitation(inv),
                  onReject: () => _rejectInvitation(inv),
                )),
            const SizedBox(height: 24),
          ],
          if (responded.isNotEmpty) ...[
            Text(
              'History',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            ...responded.map((inv) => _InvitationCard(
                  invitation: inv,
                  isHistory: true,
                )),
          ],
        ],
      ),
    );
  }
}

class _InvitationCard extends StatelessWidget {
  final InvitationModel invitation;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final bool isHistory;

  const _InvitationCard({
    required this.invitation,
    this.onAccept,
    this.onReject,
    this.isHistory = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  child: Icon(
                    Icons.storefront,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        invitation.businessName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'From ${invitation.fromProviderName}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (isHistory) _buildStatusChip(),
              ],
            ),
            const SizedBox(height: 12),

            // Role
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Role: ${invitation.role}',
                style: const TextStyle(fontSize: 13),
              ),
            ),

            // Message
            if (invitation.message != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.format_quote, size: 16, color: Colors.blue[300]),
                    const SizedBox(width: 8),
                    Expanded(child: Text(invitation.message!)),
                  ],
                ),
              ),
            ],

            // Actions
            if (!isHistory) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onReject,
                      child: const Text('Decline'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: onAccept,
                      child: const Text('Accept'),
                    ),
                  ),
                ],
              ),
            ],

            // Date
            const SizedBox(height: 8),
            Text(
              _formatDate(invitation.sentAt),
              style: TextStyle(color: Colors.grey[500], fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip() {
    Color color;
    String label;

    switch (invitation.status) {
      case InvitationStatus.accepted:
        color = Colors.green;
        label = 'Accepted';
        break;
      case InvitationStatus.rejected:
        color = Colors.red;
        label = 'Declined';
        break;
      default:
        color = Colors.grey;
        label = 'Cancelled';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style:
            TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Today';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }
}
