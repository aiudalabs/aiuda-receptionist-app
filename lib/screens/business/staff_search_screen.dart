import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/auth_service.dart';
import '../../services/invitation_service.dart';
import '../../models/user_model.dart';
import '../../models/business_model.dart';

class StaffSearchScreen extends StatefulWidget {
  final BusinessModel business;

  const StaffSearchScreen({super.key, required this.business});

  @override
  State<StaffSearchScreen> createState() => _StaffSearchScreenState();
}

class _StaffSearchScreenState extends State<StaffSearchScreen> {
  final _invitationService = InvitationService();
  final _searchController = TextEditingController();
  List<UserModel> _results = [];
  bool _isSearching = false;
  String? _error;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.length < 2) {
      setState(() {
        _results = [];
        _error = null;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _error = null;
    });

    try {
      final results = await _invitationService.searchProviders(query);

      // Filter out current staff and self
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUserId = authService.currentUser?.uid;

      final filtered = results.where((user) {
        // Exclude self
        if (user.id == currentUserId) return false;
        // Exclude existing staff
        if (widget.business.staff.any((s) => s.providerId == user.id))
          return false;
        return true;
      }).toList();

      if (mounted) {
        setState(() {
          _results = filtered;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isSearching = false;
        });
      }
    }
  }

  void _showInviteDialog(UserModel provider) {
    showDialog(
      context: context,
      builder: (context) => _InviteDialog(
        business: widget.business,
        provider: provider,
        onInvited: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Invitation sent to ${provider.businessName}'),
              backgroundColor: Colors.green,
            ),
          );
          setState(() {
            _results.remove(provider);
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Team Members'),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or email...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _search('');
                        },
                      )
                    : null,
              ),
              onChanged: _search,
            ),
          ),

          // Results
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Text(_error!, style: const TextStyle(color: Colors.red)),
      );
    }

    if (_searchController.text.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Search for providers to invite',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_search, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No providers found',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different search term',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final provider = _results[index];
        return _ProviderCard(
          provider: provider,
          onInvite: () => _showInviteDialog(provider),
        );
      },
    );
  }
}

class _ProviderCard extends StatelessWidget {
  final UserModel provider;
  final VoidCallback onInvite;

  const _ProviderCard({required this.provider, required this.onInvite});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          radius: 24,
          backgroundImage: provider.profileImageUrl != null
              ? CachedNetworkImageProvider(provider.profileImageUrl!)
              : null,
          child: provider.profileImageUrl == null
              ? Text(
                  provider.businessName.isNotEmpty
                      ? provider.businessName[0].toUpperCase()
                      : 'P',
                  style: const TextStyle(fontSize: 20),
                )
              : null,
        ),
        title: Text(
          provider.businessName.isNotEmpty ? provider.businessName : 'Provider',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (provider.professionalInfo?.title != null &&
                provider.professionalInfo!.title.isNotEmpty)
              Text(provider.professionalInfo!.title),
            Text(
              provider.email,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        isThreeLine: provider.professionalInfo?.title != null &&
            provider.professionalInfo!.title.isNotEmpty,
        trailing: FilledButton(
          onPressed: onInvite,
          child: const Text('Invite'),
        ),
      ),
    );
  }
}

class _InviteDialog extends StatefulWidget {
  final BusinessModel business;
  final UserModel provider;
  final VoidCallback onInvited;

  const _InviteDialog({
    required this.business,
    required this.provider,
    required this.onInvited,
  });

  @override
  State<_InviteDialog> createState() => _InviteDialogState();
}

class _InviteDialogState extends State<_InviteDialog> {
  final _invitationService = InvitationService();
  final _messageController = TextEditingController();
  String _selectedRole = 'Team Member';
  bool _isSending = false;

  final _roles = ['Team Member', 'Stylist', 'Barber', 'Technician', 'Manager'];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendInvitation() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUser =
        await authService.getUserProfile(authService.currentUser?.uid ?? '');

    if (currentUser == null) return;

    setState(() => _isSending = true);

    try {
      await _invitationService.sendInvitation(
        business: widget.business,
        fromProvider: currentUser,
        toProvider: widget.provider,
        role: _selectedRole,
        message: _messageController.text.trim().isNotEmpty
            ? _messageController.text.trim()
            : null,
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onInvited();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Send Invitation'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Provider info
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundImage: widget.provider.profileImageUrl != null
                    ? CachedNetworkImageProvider(
                        widget.provider.profileImageUrl!)
                    : null,
                child: widget.provider.profileImageUrl == null
                    ? Text(widget.provider.businessName.isNotEmpty
                        ? widget.provider.businessName[0]
                        : 'P')
                    : null,
              ),
              title: Text(widget.provider.businessName.isNotEmpty
                  ? widget.provider.businessName
                  : 'Provider'),
              subtitle: Text(widget.provider.email),
            ),
            const Divider(),
            const SizedBox(height: 8),

            // Role selection
            Text(
              'Role',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedRole,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: _roles.map((role) {
                return DropdownMenuItem(value: role, child: Text(role));
              }).toList(),
              onChanged: (value) {
                if (value != null) setState(() => _selectedRole = value);
              },
            ),
            const SizedBox(height: 16),

            // Message
            Text(
              'Message (optional)',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Add a personal message...',
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSending ? null : _sendInvitation,
          child: _isSending
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Send Invitation'),
        ),
      ],
    );
  }
}
