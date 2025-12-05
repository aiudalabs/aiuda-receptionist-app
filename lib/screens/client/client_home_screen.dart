import 'package:flutter/material.dart';
import '../../services/search_service.dart';
import '../../services/taxonomy_service.dart';
import '../../models/user_model.dart';
import '../../models/business_model.dart';
import '../../models/taxonomy_model.dart';
import 'search_results_screen.dart';
import 'provider_public_profile_screen.dart';
import 'business_public_profile_screen.dart';

import '../chat/ai_chat_screen.dart';

class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({Key? key}) : super(key: key);

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  final _searchService = SearchService();
  final _taxonomyService = TaxonomyService();
  final _searchController = TextEditingController();

  List<UserModel> _featuredProviders = [];
  List<BusinessModel> _featuredBusinesses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFeatured();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFeatured() async {
    setState(() => _isLoading = true);

    try {
      final providers = await _searchService.getFeaturedProviders(limit: 5);
      final businesses = await _searchService.getFeaturedBusinesses(limit: 5);

      if (mounted) {
        setState(() {
          _featuredProviders = providers;
          _featuredBusinesses = businesses;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _search() {
    final query = _searchController.text.trim();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchResultsScreen(query: query),
      ),
    );
  }

  void _searchByIndustry(Industry industry) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchResultsScreen(
          query: '',
          industryId: industry.id,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () {
              // TODO: Navigate to client profile/settings
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AIChatScreen()),
          );
        },
        label: const Text('Ask Aiuda'),
        icon: const Icon(Icons.chat_bubble_outline),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: RefreshIndicator(
        onRefresh: _loadFeatured,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Search bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search for services, providers, businesses...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onSubmitted: (_) => _search(),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 24),

            // Browse by industry
            Text(
              'Browse by Category',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _taxonomyService.getIndustries().length,
                itemBuilder: (context, index) {
                  final industry = _taxonomyService.getIndustries()[index];
                  return _IndustryCard(
                    industry: industry,
                    onTap: () => _searchByIndustry(industry),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Featured Businesses
            if (_featuredBusinesses.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Featured Businesses',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const SearchResultsScreen(query: ''),
                        ),
                      );
                    },
                    child: const Text('See all'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ..._featuredBusinesses.map((business) => _BusinessCard(
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
                  )),
              const SizedBox(height: 24),
            ],

            // Featured Providers
            if (_featuredProviders.isNotEmpty) ...[
              Text(
                'Featured Providers',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              ..._featuredProviders.map((provider) => _ProviderCard(
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
                  )),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _IndustryCard extends StatelessWidget {
  final Industry industry;
  final VoidCallback onTap;

  const _IndustryCard({required this.industry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 90,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primaryContainer,
              Theme.of(context).colorScheme.primary.withOpacity(0.3),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons
                  .category, // Using generic icon since industry.icon is string
              size: 32,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 8),
            Text(
              industry.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
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
        child: Row(
          children: [
            // Image
            Container(
              width: 100,
              height: 100,
              color: Theme.of(context).colorScheme.primaryContainer,
              child: business.photos.isNotEmpty
                  ? Image.network(
                      business.photos.first,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.storefront,
                        size: 40,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    )
                  : Icon(
                      Icons.storefront,
                      size: 40,
                      color: Theme.of(context).colorScheme.primary,
                    ),
            ),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      business.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (business.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        business.description!,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (business.rating > 0) ...[
                          const Icon(Icons.star, size: 16, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            business.rating.toStringAsFixed(1),
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Icon(Icons.people, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '${business.staff.length} staff',
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
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
        leading: CircleAvatar(
          radius: 28,
          backgroundImage: provider.profileImageUrl != null
              ? NetworkImage(provider.profileImageUrl!)
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
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          provider.professionalInfo?.title ?? 'Professional',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
