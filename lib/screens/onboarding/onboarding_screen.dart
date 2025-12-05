import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz;
import '../../services/auth_service.dart';
import '../../services/taxonomy_service.dart';
import '../../models/user_model.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _titleController = TextEditingController();
  final _bioController = TextEditingController();
  final _phoneController = TextEditingController();
  final _taxonomyService = TaxonomyService();

  String _selectedTimezone = 'America/New_York';
  WorkMode _selectedWorkMode = WorkMode.independent;
  int _yearsExperience = 0;
  final List<String> _selectedIndustries =
      []; // Changed from specialties to industries
  bool _isLoading = false;

  // Maximum number of industries a provider can select
  static const int _maxIndustries = 3;

  final List<Map<String, String>> _timezones = [
    {'value': 'America/New_York', 'label': 'Eastern Time (ET)'},
    {'value': 'America/Chicago', 'label': 'Central Time (CT)'},
    {'value': 'America/Denver', 'label': 'Mountain Time (MT)'},
    {'value': 'America/Los_Angeles', 'label': 'Pacific Time (PT)'},
    {'value': 'America/Phoenix', 'label': 'Arizona (MST)'},
    {'value': 'America/Anchorage', 'label': 'Alaska Time (AKT)'},
    {'value': 'Pacific/Honolulu', 'label': 'Hawaii Time (HST)'},
    {'value': 'America/Sao_Paulo', 'label': 'São Paulo (BRT)'},
    {'value': 'America/Mexico_City', 'label': 'Mexico City (CST)'},
    {'value': 'Europe/London', 'label': 'London (GMT)'},
    {'value': 'Europe/Madrid', 'label': 'Madrid (CET)'},
    {'value': 'UTC', 'label': 'UTC'},
  ];

  @override
  void initState() {
    super.initState();
    tz.initializeTimeZones();
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _titleController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    super.dispose();
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

  Future<void> _handleComplete() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.currentUser;

      if (user == null) {
        throw 'User not authenticated';
      }

      // Create professional info if title is provided
      ProfessionalInfo? professionalInfo;
      if (_titleController.text.trim().isNotEmpty) {
        professionalInfo = ProfessionalInfo(
          title: _titleController.text.trim(),
          bio: _bioController.text.trim(),
          yearsExperience: _yearsExperience,
        );
      }

      await authService.createUserProfile(
        userId: user.uid,
        email: user.email ?? '',
        businessName: _businessNameController.text.trim(),
        timezone: _selectedTimezone,
        workMode: _selectedWorkMode,
        professionalInfo: professionalInfo,
        industries:
            _selectedIndustries, // Changed from specialties to industries
        phoneNumber: _phoneController.text.trim().isNotEmpty
            ? _phoneController.text.trim()
            : null,
      );

      // Navigation to dashboard handled by AuthWrapper
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

  @override
  Widget build(BuildContext context) {
    final industries = _taxonomyService.getIndustries();

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Icon
                  Icon(
                    Icons.business_outlined,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),

                  // Title
                  Text(
                    'Welcome!',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  // Subtitle
                  Text(
                    'Let\'s set up your profile',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Work Mode Selection
                  Text(
                    'I want to use Aiuda as:',
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
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ),
                      Text(
                        '${_selectedIndustries.length}/$_maxIndustries',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color:
                                  _selectedIndustries.length >= _maxIndustries
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
                      final isSelected =
                          _selectedIndustries.contains(industry.id);
                      final isDisabled = !isSelected &&
                          _selectedIndustries.length >= _maxIndustries;

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
                  const SizedBox(height: 16),

                  // Bio
                  TextFormField(
                    controller: _bioController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Bio (optional)',
                      hintText:
                          'Tell clients about yourself and your experience...',
                      prefixIcon: Icon(Icons.description_outlined),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Timezone dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedTimezone,
                    decoration: const InputDecoration(
                      labelText: 'Timezone',
                      prefixIcon: Icon(Icons.access_time_outlined),
                    ),
                    items: _timezones.map((tz) {
                      return DropdownMenuItem(
                        value: tz['value'],
                        child: Text(tz['label']!),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedTimezone = value);
                      }
                    },
                  ),
                  const SizedBox(height: 32),

                  // Complete button
                  FilledButton(
                    onPressed: _isLoading ? null : _handleComplete,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Complete Setup'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
