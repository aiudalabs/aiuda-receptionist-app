import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/business_model.dart';
import '../../models/user_model.dart';
import '../../services/search_service.dart';
import '../../models/service_model.dart';
import '../booking/service_selection_screen.dart';

class BusinessPublicProfileScreen extends StatefulWidget {
  final BusinessModel business;

  const BusinessPublicProfileScreen({super.key, required this.business});

  @override
  State<BusinessPublicProfileScreen> createState() =>
      _BusinessPublicProfileScreenState();
}

class _BusinessPublicProfileScreenState
    extends State<BusinessPublicProfileScreen> {
  final _searchService = SearchService();
  List<ServiceModel> _services = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    setState(() => _isLoading = true);

    try {
      // Get services from all staff members
      final Set<ServiceModel> allServices = {};

      for (final staff in widget.business.staff) {
        final services =
            await _searchService.getProviderServices(staff.providerId);
        allServices.addAll(services);
      }

      if (mounted) {
        setState(() {
          _services = allServices.toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.business.name,
                style: const TextStyle(
                  shadows: [Shadow(blurRadius: 8, color: Colors.black54)],
                ),
              ),
              background: widget.business.photos.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: widget.business.photos.first,
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
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Rating
                  if (widget.business.rating > 0)
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          widget.business.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          ' (${widget.business.reviewCount} reviews)',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  const SizedBox(height: 16),

                  // Description
                  if (widget.business.description != null) ...[
                    Text(
                      'About',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(widget.business.description!),
                    const SizedBox(height: 24),
                  ],

                  // Location
                  if (widget.business.location != null) ...[
                    Text(
                      'Location',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.location_on),
                        title: Text(widget.business.location!.address),
                        subtitle: widget.business.location!.city != null
                            ? Text(
                                '${widget.business.location!.city}, ${widget.business.location!.state ?? ''}')
                            : null,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Hours
                  Text(
                    'Business Hours',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: widget.business.hours.entries.map((entry) {
                          final dayName = entry.key[0].toUpperCase() +
                              entry.key.substring(1);
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(dayName),
                                Text(
                                  entry.value.isOpen
                                      ? '${entry.value.openTime} - ${entry.value.closeTime}'
                                      : 'Closed',
                                  style: TextStyle(
                                    color: entry.value.isOpen
                                        ? Colors.green
                                        : Colors.grey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Team
                  if (widget.business.staff.isNotEmpty) ...[
                    Text(
                      'Our Team',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${widget.business.staff.length} professional${widget.business.staff.length > 1 ? 's' : ''}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Services
                  Text(
                    'Services',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (_services.isEmpty)
                    const Text('No services listed')
                  else
                    ..._services.map((service) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(service.name),
                            subtitle: service.description != null
                                ? Text(service.description!)
                                : null,
                            trailing: Text(
                              '\$${service.price.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        )),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Navigate to booking screen in Sprint 10
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Booking feature coming in Sprint 10!'),
            ),
          );
        },
        icon: const Icon(Icons.calendar_month),
        label: const Text('Book Appointment'),
      ),
    );
  }
}
