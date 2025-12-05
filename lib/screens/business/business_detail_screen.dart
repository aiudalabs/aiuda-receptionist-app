import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/business_service.dart';
import '../../services/invitation_service.dart';
import '../../models/business_model.dart';
import '../../models/invitation_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'staff_search_screen.dart';

class BusinessDetailScreen extends StatefulWidget {
  final BusinessModel business;

  const BusinessDetailScreen({super.key, required this.business});

  @override
  State<BusinessDetailScreen> createState() => _BusinessDetailScreenState();
}

class _BusinessDetailScreenState extends State<BusinessDetailScreen>
    with SingleTickerProviderStateMixin {
  final _businessService = BusinessService();
  final _invitationService = InvitationService();
  late TabController _tabController;
  late BusinessModel _business;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _business = widget.business;
    _refreshBusiness();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshBusiness() async {
    final updated = await _businessService.getBusiness(_business.id);
    if (updated != null && mounted) {
      setState(() => _business = updated);
    }
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _uploadPhoto(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _uploadPhoto(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadPhoto(ImageSource source) async {
    setState(() => _isUploading = true);

    try {
      await _businessService.uploadPhoto(_business.id, source: source);
      await _refreshBusiness();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Photo added'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _deletePhoto(String url) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Photo'),
        content: const Text('Are you sure you want to delete this photo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _businessService.removePhoto(_business.id, url);
      await _refreshBusiness();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  _business.name,
                  style: const TextStyle(
                    shadows: [Shadow(blurRadius: 8, color: Colors.black54)],
                  ),
                ),
                background: _business.photos.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: _business.photos.first,
                        fit: BoxFit.cover,
                        color: Colors.black38,
                        colorBlendMode: BlendMode.darken,
                      )
                    : Container(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        child: Icon(
                          Icons.storefront,
                          size: 80,
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.5),
                        ),
                      ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: _editBasicInfo,
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(icon: Icon(Icons.info), text: 'Info'),
                  Tab(icon: Icon(Icons.people), text: 'Team'),
                  Tab(icon: Icon(Icons.photo), text: 'Photos'),
                  Tab(icon: Icon(Icons.schedule), text: 'Hours'),
                ],
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildInfoTab(),
            _buildTeamTab(),
            _buildPhotosTab(),
            _buildHoursTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Rating
        if (_business.rating > 0)
          Card(
            child: ListTile(
              leading: const Icon(Icons.star, color: Colors.amber),
              title: Text('${_business.rating.toStringAsFixed(1)} rating'),
              subtitle: Text('${_business.reviewCount} reviews'),
            ),
          ),

        // Description
        if (_business.description != null) ...[
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'About',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(_business.description!),
                ],
              ),
            ),
          ),
        ],

        // Location
        if (_business.location != null) ...[
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.location_on),
              title: Text(_business.location!.address),
              subtitle: _business.location!.city != null
                  ? Text(
                      '${_business.location!.city}, ${_business.location!.state ?? ''}')
                  : null,
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // TODO: Open maps
              },
            ),
          ),
        ],

        // Contact info
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              if (_business.phone != null)
                ListTile(
                  leading: const Icon(Icons.phone),
                  title: Text(_business.phone!),
                  onTap: () {
                    // TODO: Call
                  },
                ),
              if (_business.email != null)
                ListTile(
                  leading: const Icon(Icons.email),
                  title: Text(_business.email!),
                  onTap: () {
                    // TODO: Email
                  },
                ),
              if (_business.website != null)
                ListTile(
                  leading: const Icon(Icons.language),
                  title: Text(_business.website!),
                  onTap: () {
                    // TODO: Open browser
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTeamTab() {
    return FutureBuilder<List<InvitationModel>>(
      future: _invitationService.getSentInvitations(_business.id),
      builder: (context, snapshot) {
        final invitations = snapshot.data ?? [];
        final pendingInvitations =
            invitations.where((i) => i.isPending).toList();

        final hasContent =
            _business.staff.isNotEmpty || pendingInvitations.isNotEmpty;

        if (!hasContent) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  'No team members yet',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Invite providers to join your team',
                  style: TextStyle(color: Colors.grey[500]),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _inviteTeamMember,
                  icon: const Icon(Icons.person_add),
                  label: const Text('Invite Member'),
                ),
              ],
            ),
          );
        }

        return Stack(
          children: [
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Pending invitations section
                if (pendingInvitations.isNotEmpty) ...[
                  Text(
                    'Pending Invitations',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Colors.orange[700],
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  ...pendingInvitations.map((inv) => Card(
                        color: Colors.orange[50],
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.orange[100],
                            child: const Icon(Icons.hourglass_empty,
                                color: Colors.orange),
                          ),
                          title: Text(inv.toProviderName),
                          subtitle: Text('${inv.role} • Invited'),
                          trailing: IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () => _cancelInvitation(inv),
                          ),
                        ),
                      )),
                  const SizedBox(height: 16),
                ],

                // Active staff section
                if (_business.staff.isNotEmpty) ...[
                  Text(
                    'Team Members',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  ..._business.staff.map((member) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.green[100],
                            child: Text(member.role[0].toUpperCase()),
                          ),
                          title: Text(
                              'Provider ${member.providerId.substring(0, 8)}...'),
                          subtitle: Text(member.role),
                          trailing: Chip(
                            label: Text(member.status),
                            backgroundColor: member.status == 'active'
                                ? Colors.green[100]
                                : Colors.grey[100],
                          ),
                        ),
                      )),
                ],
              ],
            ),
            // FAB
            Positioned(
              right: 16,
              bottom: 16,
              child: FloatingActionButton.extended(
                onPressed: _inviteTeamMember,
                icon: const Icon(Icons.person_add),
                label: const Text('Invite'),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPhotosTab() {
    return Stack(
      children: [
        _business.photos.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.photo_library_outlined,
                        size: 64, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text(
                      'No photos yet',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _showPhotoOptions,
                      icon: const Icon(Icons.add_a_photo),
                      label: const Text('Add Photo'),
                    ),
                  ],
                ),
              )
            : GridView.builder(
                padding: const EdgeInsets.all(8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _business.photos.length,
                itemBuilder: (context, index) {
                  final url = _business.photos[index];
                  return GestureDetector(
                    onLongPress: () => _deletePhoto(url),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: url,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: Colors.grey[200],
                          child:
                              const Center(child: CircularProgressIndicator()),
                        ),
                      ),
                    ),
                  );
                },
              ),
        // FAB for adding photos
        if (_business.photos.isNotEmpty)
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton(
              onPressed: _isUploading ? null : _showPhotoOptions,
              child: _isUploading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Icon(Icons.add_a_photo),
            ),
          ),
      ],
    );
  }

  Widget _buildHoursTab() {
    final days = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday'
    ];
    final dayNames = {
      'monday': 'Monday',
      'tuesday': 'Tuesday',
      'wednesday': 'Wednesday',
      'thursday': 'Thursday',
      'friday': 'Friday',
      'saturday': 'Saturday',
      'sunday': 'Sunday',
    };

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ...days.map((day) {
          final hours = _business.hours[day];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(dayNames[day]!),
              trailing: Text(
                hours?.isOpen == true
                    ? '${hours!.openTime} - ${hours.closeTime}'
                    : 'Closed',
                style: TextStyle(
                  color: hours?.isOpen == true ? Colors.green : Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: _editHours,
          icon: const Icon(Icons.edit),
          label: const Text('Edit Hours'),
        ),
      ],
    );
  }

  void _editBasicInfo() {
    // TODO: Navigate to edit screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit screen coming in Sprint 6')),
    );
  }

  void _inviteTeamMember() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StaffSearchScreen(business: _business),
      ),
    ).then((_) => _refreshBusiness());
  }

  void _editHours() {
    // TODO: Navigate to hours edit screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Hours editor coming soon')),
    );
  }

  Future<void> _cancelInvitation(InvitationModel invitation) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Invitation'),
        content: Text('Cancel invitation to ${invitation.toProviderName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cancel Invitation'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _invitationService.cancelInvitation(invitation.id);
      setState(() {}); // Rebuild to refresh
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invitation cancelled')),
        );
      }
    }
  }
}
