import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/availability_service.dart';
import '../../models/availability_model.dart';
import 'availability_setup_screen.dart';

class MultiLocationAvailabilityScreen extends StatefulWidget {
  const MultiLocationAvailabilityScreen({super.key});

  @override
  State<MultiLocationAvailabilityScreen> createState() =>
      _MultiLocationAvailabilityScreenState();
}

class _MultiLocationAvailabilityScreenState
    extends State<MultiLocationAvailabilityScreen> {
  final _availabilityService = AvailabilityService();
  List<Map<String, dynamic>> _businesses = [];
  Map<String, AvailabilityModel?> _availabilities = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.currentUser?.uid;

    if (userId == null) return;

    setState(() => _isLoading = true);

    try {
      // Get all businesses
      final businesses =
          await _availabilityService.getProviderBusinesses(userId);

      // Get availabilities for each location
      final Map<String, AvailabilityModel?> availabilities = {};

      // Independent schedule
      final independentAvail =
          await _availabilityService.getAvailability(userId);
      availabilities['independent'] = independentAvail;

      // Business schedules
      for (final business in businesses) {
        final avail = await _availabilityService.getAvailability(
          userId,
          businessId: business['id'],
        );
        availabilities[business['id']] = avail;
      }

      if (mounted) {
        setState(() {
          _businesses = businesses;
          _availabilities = availabilities;
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

  void _configureLocation(String? businessId, String businessName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AvailabilitySetupScreen(
          businessId: businessId,
          businessName: businessName,
        ),
      ),
    ).then((_) => _loadData());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Work Locations'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _businesses.isEmpty
              ? _buildEmptyState()
              : _buildLocationsList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_on_outlined, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No business locations yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create a business or accept an invitation to set location-specific hours',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500]),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => _configureLocation(null, 'Independent Schedule'),
              child: const Text('Configure Personal Hours'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationsList() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Independent schedule
        _LocationCard(
          icon: Icons.person,
          title: 'Independent Schedule',
          subtitle: 'Your personal availability when working independently',
          availability: _availabilities['independent'],
          onTap: () => _configureLocation(null, 'Independent Schedule'),
        ),

        if (_businesses.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            'Business Locations',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
        ],

        // Business schedules
        ..._businesses.map((business) {
          return _LocationCard(
            icon: Icons.storefront,
            title: business['name'],
            subtitle: business['role'],
            availability: _availabilities[business['id']],
            onTap: () => _configureLocation(business['id'], business['name']),
          );
        }),

        const SizedBox(height: 16),

        // Info card
        Card(
          color: Colors.blue[50],
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Configure different hours for each location. Clients will see your availability based on where they book.',
                    style: TextStyle(
                      color: Colors.blue[900],
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LocationCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final AvailabilityModel? availability;
  final VoidCallback onTap;

  const _LocationCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.availability,
    required this.onTap,
  });

  String _getScheduleSummary(AvailabilityModel? avail) {
    if (avail == null) return 'Not configured';

    final workingDays = avail.weeklySchedule.values
        .where((schedule) => schedule.isAvailable)
        .length;

    if (workingDays == 0) return 'All days off';
    if (workingDays == 7) return '7 days/week';
    return '$workingDays days/week';
  }

  @override
  Widget build(BuildContext context) {
    final isConfigured = availability != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isConfigured ? Colors.green[100] : Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isConfigured ? Colors.green[700] : Colors.grey[600],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isConfigured
                                ? Colors.green[50]
                                : Colors.orange[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _getScheduleSummary(availability),
                            style: TextStyle(
                              color: isConfigured
                                  ? Colors.green[700]
                                  : Colors.orange[700],
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}
