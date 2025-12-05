import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz;
import '../../services/auth_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  String _selectedTimezone = 'America/New_York';
  bool _isLoading = false;

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
    super.dispose();
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

      await authService.createUserProfile(
        userId: user.uid,
        email: user.email ?? '',
        businessName: _businessNameController.text.trim(),
        timezone: _selectedTimezone,
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
                    'Let\'s set up your business profile',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),

                  // Business name field
                  TextFormField(
                    controller: _businessNameController,
                    decoration: const InputDecoration(
                      labelText: 'Business Name',
                      hintText: 'e.g., Maria\'s Hair Salon',
                      prefixIcon: Icon(Icons.store_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your business name';
                      }
                      return null;
                    },
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

                  // Info card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outlined,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'You can add services and business hours in settings later',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
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
