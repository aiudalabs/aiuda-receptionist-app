import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/auth_service.dart';
import '../../services/taxonomy_service.dart';
import '../../services/portfolio_service.dart';
import '../../models/user_model.dart';
import 'portfolio_screen.dart';
import 'profile_preview_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _titleController = TextEditingController();
  final _bioController = TextEditingController();
  final _phoneController = TextEditingController();
  final _taxonomyService = TaxonomyService();
  final _portfolioService = PortfolioService();

  WorkMode _selectedWorkMode = WorkMode.independent;
  String? _profileImageUrl;
  bool _isUploadingPhoto = false;
  UserModel? _currentProfile;
  int _yearsExperience = 0;
  final List<String> _selectedIndustries =
      []; // Changed from specialties to industries
  bool _isLoading = false;
  bool _isAvailable = true;

  // Maximum number of industries a provider can select
  static const int _maxIndustries = 3;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _titleController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.currentUser?.uid;

    if (userId == null) return;

    final profile = await authService.getUserProfile(userId);
    if (profile != null && mounted) {
      setState(() {
        _currentProfile = profile;
        _profileImageUrl = profile.profileImageUrl;
        _businessNameController.text = profile.businessName;
        _selectedWorkMode = profile.workMode;
        _titleController.text = profile.professionalInfo?.title ?? '';
        _bioController.text = profile.professionalInfo?.bio ?? '';
        _yearsExperience = profile.professionalInfo?.yearsExperience ?? 0;
        _phoneController.text = profile.phoneNumber ?? '';
        _selectedIndustries.clear();
        _selectedIndustries.addAll(profile.industries);
        _isAvailable = profile.isAvailable;
      });
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
                _uploadProfilePhoto(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a Photo'),
              onTap: () {
                Navigator.pop(context);
                _uploadProfilePhoto(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadProfilePhoto(ImageSource source) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.currentUser?.uid;

    if (userId == null) return;

    setState(() => _isUploadingPhoto = true);

    try {
      final url =
          await _portfolioService.uploadProfileImage(userId, source: source);
      if (url != null && mounted) {
        setState(() {
          _profileImageUrl = url;
          _currentProfile = _currentProfile?.copyWith(profileImageUrl: url);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile photo updated'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
      }
    }
  }

  IconData _getIndustryIcon(String iconName) {
    switch (iconName) {
      case 'content_cut':
        return Icons.content_cut;
      case 'directions_car':
        return Icons.directions_car;
      case 'home':
        return Icons.home;
      case 'fitness_center':
        return Icons.fitness_center;
      case 'business':
        return Icons.business;
      case 'school':
        return Icons.school;
      case 'celebration':
        return Icons.celebration;
      case 'pets':
        return Icons.pets;
      case 'computer':
        return Icons.computer;
      case 'construction':
        return Icons.construction;
      default:
        return Icons.work;
    }
  }

  @override
  Widget build(BuildContext context) {
    final industries = _taxonomyService.getIndustries();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _handleSave,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Profile Photo Section
            Center(
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: _isUploadingPhoto ? null : _showPhotoOptions,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: _profileImageUrl != null
                          ? CachedNetworkImageProvider(_profileImageUrl!)
                          : null,
                      child: _isUploadingPhoto
                          ? const CircularProgressIndicator()
                          : _profileImageUrl == null
                              ? const Icon(Icons.person, size: 50)
                              : null,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Action Buttons Row
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PortfolioScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Portfolio'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _currentProfile != null
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProfilePreviewScreen(
                                  profile: _currentProfile!,
                                ),
                              ),
                            );
                          }
                        : null,
                    icon: const Icon(Icons.visibility),
                    label: const Text('Preview'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Availability Toggle
            Card(
              child: SwitchListTile(
                title: const Text('Available for Bookings'),
                subtitle: Text(_isAvailable
                    ? 'Clients can book appointments with you'
                    : 'You\'re currently unavailable'),
                value: _isAvailable,
                onChanged: (value) {
                  setState(() => _isAvailable = value);
                },
                secondary: Icon(
                  _isAvailable ? Icons.check_circle : Icons.cancel,
                  color: _isAvailable ? Colors.green : Colors.red,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Work Mode Selection
            Text(
              'Work Mode',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            ...WorkMode.values.map((mode) {
              final labels = {
                WorkMode.independent: 'Independent Provider',
                WorkMode.businessOwner: 'Business Owner',
                WorkMode.employee: 'Employee',
                WorkMode.both: 'Both Independent & Employee',
              };
              return RadioListTile<WorkMode>(
                title: Text(labels[mode]!),
                value: mode,
                groupValue: _selectedWorkMode,
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedWorkMode = value);
                  }
                },
                contentPadding: EdgeInsets.zero,
              );
            }),
            const SizedBox(height: 24),

            // Business name field
            TextFormField(
              controller: _businessNameController,
              decoration: InputDecoration(
                labelText: _selectedWorkMode == WorkMode.businessOwner
                    ? 'Business Name'
                    : 'Business/Professional Name',
                hintText: 'e.g., Maria\'s Hair Salon',
                prefixIcon: const Icon(Icons.store_outlined),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Professional Title
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Professional Title',
                hintText: 'e.g., Hair Stylist, Barber, Mechanic',
                prefixIcon: Icon(Icons.work_outlined),
              ),
            ),
            const SizedBox(height: 16),

            // Phone Number
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                hintText: '+1 (555) 123-4567',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: 16),

            // Years of Experience
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Years of Experience: $_yearsExperience',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Slider(
                    value: _yearsExperience.toDouble(),
                    min: 0,
                    max: 50,
                    divisions: 50,
                    label: _yearsExperience.toString(),
                    onChanged: (value) {
                      setState(() => _yearsExperience = value.toInt());
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Industries Selection (replaced specialties)
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Industries (select up to $_maxIndustries):',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                Text(
                  '${_selectedIndustries.length}/$_maxIndustries',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _selectedIndustries.length >= _maxIndustries
                            ? Colors.orange
                            : Colors.grey,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: industries.map((industry) {
                final isSelected = _selectedIndustries.contains(industry.id);
                final isDisabled =
                    !isSelected && _selectedIndustries.length >= _maxIndustries;

                return FilterChip(
                  avatar: Icon(
                    _getIndustryIcon(industry.icon),
                    size: 18,
                    color: isSelected ? Colors.white : null,
                  ),
                  label: Text(industry.name),
                  selected: isSelected,
                  onSelected: isDisabled
                      ? null
                      : (selected) {
                          setState(() {
                            if (selected) {
                              _selectedIndustries.add(industry.id);
                            } else {
                              _selectedIndustries.remove(industry.id);
                            }
                          });
                        },
                  tooltip: industry.description,
                );
              }).toList(),
            ),

            // Show selected industries categories
            if (_selectedIndustries.isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(
                color: Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your categories:',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[900],
                            ),
                      ),
                      const SizedBox(height: 4),
                      ..._selectedIndustries.map((industryId) {
                        final industry =
                            _taxonomyService.getIndustry(industryId);
                        if (industry == null) return const SizedBox.shrink();
                        final categories =
                            industry.categories.map((c) => c.name).join(', ');
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '${industry.name}: $categories',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.blue[800],
                                    ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),

            // Bio
            TextFormField(
              controller: _bioController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Bio (optional)',
                hintText: 'Tell clients about yourself and your experience...',
                prefixIcon: Icon(Icons.description_outlined),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 32),

            // Save button
            FilledButton(
              onPressed: _isLoading ? null : _handleSave,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.currentUser?.uid;

      if (userId == null) {
        throw 'User not authenticated';
      }

      // Prepare updates
      final updates = <String, dynamic>{
        'businessName': _businessNameController.text.trim(),
        'workMode': _selectedWorkMode.toFirestore(),
        'industries':
            _selectedIndustries, // Changed from specialties to industries
        'phoneNumber': _phoneController.text.trim().isNotEmpty
            ? _phoneController.text.trim()
            : null,
        'isAvailable': _isAvailable,
      };

      // Add professional info if title is provided
      if (_titleController.text.trim().isNotEmpty) {
        updates['professionalInfo'] = {
          'title': _titleController.text.trim(),
          'bio': _bioController.text.trim(),
          'yearsExperience': _yearsExperience,
        };
      }

      // Update in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update(updates);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
