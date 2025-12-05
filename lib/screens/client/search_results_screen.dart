import 'package:flutter/material.dart';
import '../../services/search_service.dart';
import '../../models/user_model.dart';
import '../../models/business_model.dart';
import 'provider_public_profile_screen.dart';
import 'business_public_profile_screen.dart';

class SearchResultsScreen extends StatefulWidget {
  final String query;
  final String? industryId;

  const SearchResultsScreen({
    super.key,
    required this.query,
    this.industryId,
  });

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen>
    with SingleTickerProviderStateMixin {
  final _searchService = SearchService();
  late TabController _tabController;

  List<BusinessModel> _businesses = [];
  List<UserModel> _providers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _search();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    setState(() => _isLoading = true);

    try {
      final filter = widget.industryId != null
          ? SearchFilter(industryId: widget.industryId)
          : null;

      final businesses =
          await _searchService.searchBusinesses(widget.query, filter: filter);
      final providers =
          await _searchService.searchProviders(widget.query, filter: filter);

      if (mounted) {
        setState(() {
          _businesses = businesses;
          _providers = providers;
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
    final title = widget.query.isNotEmpty
        ? 'Results for "${widget.query}"'
        : 'Browse Services';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              text: 'Businesses (${_businesses.length})',
              icon: const Icon(Icons.storefront),
            ),
            Tab(
              text: 'Providers (${_providers.length})',
              icon: const Icon(Icons.person),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildBusinessesList(),
                _buildProvidersList(),
              ],
            ),
    );
  }

  Widget _buildBusinessesList() {
    if (_businesses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No businesses found',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _businesses.length,
      itemBuilder: (context, index) {
        final business = _businesses[index];
        return _BusinessCard(
          business: business,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    BusinessPublicProfileScreen(business: business),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildProvidersList() {
    if (_providers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No providers found',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _providers.length,
      itemBuilder: (context, index) {
        final provider = _providers[index];
        return _ProviderCard(
          provider: provider,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ProviderPublicProfileScreen(provider: provider),
              ),
            );
          },
        );
      },
    );
  }
}

class _BusinessCard extends StatelessWidget {
  final BusinessModel business;
  final VoidCallback onTap;

  const _BusinessCard({required this.business, required this.onTap});

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
            // Image
            if (business.photos.isNotEmpty)
              Image.network(
                business.photos.first,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 150,
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: Icon(
                    Icons.storefront,
                    size: 48,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            // Info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    business.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  if (business.description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      business.description!,
                      style: TextStyle(color: Colors.grey[600]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (business.rating > 0) ...[
                        const Icon(Icons.star, size: 18, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          business.rating.toStringAsFixed(1),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          ' (${business.reviewCount})',
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                        const SizedBox(width: 16),
                      ],
                      Icon(Icons.people, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${business.staff.length} staff',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
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
}

class _ProviderCard extends StatelessWidget {
  final UserModel provider;
  final VoidCallback onTap;

  const _ProviderCard({required this.provider, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          radius: 32,
          backgroundImage: provider.profileImageUrl != null
              ? NetworkImage(provider.profileImageUrl!)
              : null,
          child: provider.profileImageUrl == null
              ? Text(
                  provider.businessName.isNotEmpty
                      ? provider.businessName[0].toUpperCase()
                      : 'P',
                  style: const TextStyle(fontSize: 24),
                )
              : null,
        ),
        title: Text(
          provider.businessName.isNotEmpty ? provider.businessName : 'Provider',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (provider.professionalInfo?.title != null) ...[
              const SizedBox(height: 4),
              Text(provider.professionalInfo!.title),
            ],
            if (provider.professionalInfo?.bio != null) ...[
              const SizedBox(height: 4),
              Text(
                provider.professionalInfo!.bio,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ],
        ),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
