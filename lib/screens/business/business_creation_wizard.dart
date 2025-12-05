import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/business_service.dart';
import '../../services/taxonomy_service.dart';
import '../../models/business_model.dart';

class BusinessCreationWizard extends StatefulWidget {
  const BusinessCreationWizard({super.key});

  @override
  State<BusinessCreationWizard> createState() => _BusinessCreationWizardState();
}

class _BusinessCreationWizardState extends State<BusinessCreationWizard> {
  final _businessService = BusinessService();
  final _taxonomyService = TaxonomyService();
  final _pageController = PageController();

  int _currentStep = 0;
  bool _isCreating = false;

  // Step 1: Basic Info
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedIndustryId;

  // Step 2: Location
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipController = TextEditingController();

  // Step 3: Hours
  Map<String, BusinessHours> _hours = BusinessModel.defaultHours();

  // Step 4: Contact
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _websiteController = TextEditingController();

  final List<String> _stepTitles = [
    'Basic Info',
    'Location',
    'Business Hours',
    'Contact Info',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _stepTitles.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep++);
    } else {
      _createBusiness();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep--);
    } else {
      Navigator.pop(context);
    }
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return _nameController.text.trim().isNotEmpty;
      case 1:
        return _addressController.text.trim().isNotEmpty;
      case 2:
        return true; // Hours are optional
      case 3:
        return true; // Contact is optional
      default:
        return false;
    }
  }

  Future<void> _createBusiness() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.currentUser?.uid;

    if (userId == null) return;

    setState(() => _isCreating = true);

    try {
      BusinessLocation? location;
      if (_addressController.text.isNotEmpty) {
        location = BusinessLocation(
          address: _addressController.text.trim(),
          city: _cityController.text.trim().isNotEmpty
              ? _cityController.text.trim()
              : null,
          state: _stateController.text.trim().isNotEmpty
              ? _stateController.text.trim()
              : null,
          zipCode: _zipController.text.trim().isNotEmpty
              ? _zipController.text.trim()
              : null,
        );
      }

      await _businessService.createBusiness(
        ownerId: userId,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        industryId: _selectedIndustryId,
        location: location,
        hours: _hours,
        phone: _phoneController.text.trim().isNotEmpty
            ? _phoneController.text.trim()
            : null,
        email: _emailController.text.trim().isNotEmpty
            ? _emailController.text.trim()
            : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Business created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Business'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Progress indicator
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: List.generate(_stepTitles.length, (index) {
                    return Expanded(
                      child: Container(
                        height: 4,
                        margin: EdgeInsets.only(
                            right: index < _stepTitles.length - 1 ? 8 : 0),
                        decoration: BoxDecoration(
                          color: index <= _currentStep
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 8),
                Text(
                  'Step ${_currentStep + 1} of ${_stepTitles.length}: ${_stepTitles[_currentStep]}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
          ),

          // Page content
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildBasicInfoStep(),
                _buildLocationStep(),
                _buildHoursStep(),
                _buildContactStep(),
              ],
            ),
          ),

          // Action buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _previousStep,
                      child: const Text('Back'),
                    ),
                  ),
                if (_currentStep > 0) const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: _canProceed() && !_isCreating ? _nextStep : null,
                    child: _isCreating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(_currentStep == _stepTitles.length - 1
                            ? 'Create Business'
                            : 'Continue'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoStep() {
    final industries = _taxonomyService.getIndustries();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Tell us about your business',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 24),

        // Business name
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Business Name *',
            hintText: 'e.g., Luxe Hair Salon',
            prefixIcon: Icon(Icons.storefront),
          ),
          textCapitalization: TextCapitalization.words,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),

        // Industry
        DropdownButtonFormField<String>(
          value: _selectedIndustryId,
          decoration: const InputDecoration(
            labelText: 'Industry',
            prefixIcon: Icon(Icons.category),
          ),
          items: industries.map((industry) {
            return DropdownMenuItem(
              value: industry.id,
              child: Text(industry.name),
            );
          }).toList(),
          onChanged: (value) {
            setState(() => _selectedIndustryId = value);
          },
        ),
        const SizedBox(height: 16),

        // Description
        TextFormField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            labelText: 'Description',
            hintText: 'Tell customers about your business...',
            alignLabelWithHint: true,
          ),
          maxLines: 4,
          textCapitalization: TextCapitalization.sentences,
        ),
      ],
    );
  }

  Widget _buildLocationStep() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Where is your business located?',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: _addressController,
          decoration: const InputDecoration(
            labelText: 'Street Address *',
            hintText: '123 Main Street',
            prefixIcon: Icon(Icons.location_on),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(
                  labelText: 'City',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _stateController,
                decoration: const InputDecoration(
                  labelText: 'State',
                ),
                textCapitalization: TextCapitalization.characters,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _zipController,
          decoration: const InputDecoration(
            labelText: 'ZIP Code',
          ),
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }

  Widget _buildHoursStep() {
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
        Text(
          'Set your business hours',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'You can change these later',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
        ),
        const SizedBox(height: 24),
        ...days.map((day) {
          final hours = _hours[day] ?? BusinessHours();
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  SizedBox(
                    width: 100,
                    child: Text(
                      dayNames[day]!,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  Switch(
                    value: hours.isOpen,
                    onChanged: (value) {
                      setState(() {
                        _hours[day] = hours.copyWith(
                          isOpen: value,
                          openTime: value ? '09:00' : null,
                          closeTime: value ? '18:00' : null,
                        );
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  if (hours.isOpen) ...[
                    Expanded(
                      child: Text(
                        '${hours.openTime ?? '09:00'} - ${hours.closeTime ?? '18:00'}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                  ] else
                    Expanded(
                      child: Text(
                        'Closed',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildContactStep() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Contact Information',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Optional - help customers reach you',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
        ),
        const SizedBox(height: 24),

        TextFormField(
          controller: _phoneController,
          decoration: const InputDecoration(
            labelText: 'Phone',
            hintText: '+1 (555) 123-4567',
            prefixIcon: Icon(Icons.phone),
          ),
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),

        TextFormField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: 'Email',
            hintText: 'contact@mybusiness.com',
            prefixIcon: Icon(Icons.email),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),

        TextFormField(
          controller: _websiteController,
          decoration: const InputDecoration(
            labelText: 'Website',
            hintText: 'www.mybusiness.com',
            prefixIcon: Icon(Icons.language),
          ),
          keyboardType: TextInputType.url,
        ),
        const SizedBox(height: 32),

        // Summary
        Card(
          color:
              Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Ready to create!',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'You can add photos and invite team members after creating your business.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
