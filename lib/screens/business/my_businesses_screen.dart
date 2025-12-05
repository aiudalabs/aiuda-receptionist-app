import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/business_service.dart';
import '../../models/business_model.dart';
import 'business_creation_wizard.dart';
import 'business_detail_screen.dart';

class MyBusinessesScreen extends StatefulWidget {
  const MyBusinessesScreen({super.key});

  @override
  State<MyBusinessesScreen> createState() => _MyBusinessesScreenState();
}

class _MyBusinessesScreenState extends State<MyBusinessesScreen> {
  final _businessService = BusinessService();
  List<BusinessModel> _businesses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBusinesses();
  }

  Future<void> _loadBusinesses() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.currentUser?.uid;

    if (userId == null) return;

    setState(() => _isLoading = true);

    try {
      final businesses = await _businessService.getMyBusinesses(userId);
      if (mounted) {
        setState(() {
          _businesses = businesses;
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

  void _createBusiness() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const BusinessCreationWizard(),
      ),
    );

    if (result == true) {
      _loadBusinesses();
    }
  }

  void _openBusiness(BusinessModel business) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BusinessDetailScreen(business: business),
      ),
    ).then((_) => _loadBusinesses());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Businesses'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _businesses.isEmpty
              ? _buildEmptyState()
              : _buildBusinessList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createBusiness,
        icon: const Icon(Icons.add),
        label: const Text('New Business'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.storefront_outlined,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'No businesses yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create a business to manage your team and locations',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[500],
                  ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _createBusiness,
              icon: const Icon(Icons.add),
              label: const Text('Create Business'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessList() {
    return RefreshIndicator(
      onRefresh: _loadBusinesses,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _businesses.length,
        itemBuilder: (context, index) {
          final business = _businesses[index];
          return _BusinessCard(
            business: business,
            onTap: () => _openBusiness(business),
          );
        },
      ),
    );
  }
}

class _BusinessCard extends StatelessWidget {
  final BusinessModel business;
  final VoidCallback onTap;

  const _BusinessCard({
    required this.business,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo header
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
              ),
              child: business.photos.isNotEmpty
                  ? Image.network(
                      business.photos.first,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildPlaceholder(context),
                    )
                  : _buildPlaceholder(context),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          business.name,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ),
                      if (business.rating > 0)
                        Row(
                          children: [
                            const Icon(Icons.star,
                                color: Colors.amber, size: 18),
                            const SizedBox(width: 4),
                            Text(
                              business.rating.toStringAsFixed(1),
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                    ],
                  ),
                  if (business.location?.address != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on,
                            size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            business.location!.address,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _StatChip(
                        icon: Icons.people,
                        label: '${business.staff.length} staff',
                      ),
                      const SizedBox(width: 8),
                      _StatChip(
                        icon: Icons.photo,
                        label: '${business.photos.length} photos',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Center(
      child: Icon(
        Icons.storefront,
        size: 48,
        color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
