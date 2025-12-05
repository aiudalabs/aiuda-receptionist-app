import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/user_model.dart';
import '../../models/service_model.dart';
import '../../services/provider_service.dart';
import '../../services/portfolio_service.dart';
import '../../services/taxonomy_service.dart';

class ProfilePreviewScreen extends StatefulWidget {
  final UserModel profile;

  const ProfilePreviewScreen({
    super.key,
    required this.profile,
  });

  @override
  State<ProfilePreviewScreen> createState() => _ProfilePreviewScreenState();
}

class _ProfilePreviewScreenState extends State<ProfilePreviewScreen> {
  final _providerService = ProviderService();
  final _portfolioService = PortfolioService();
  final _taxonomyService = TaxonomyService();

  List<ServiceModel> _services = [];
  List<PortfolioPhoto> _photos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final services =
          await _providerService.getServicesForProvider(widget.profile.id);
      final photos = await _portfolioService.getPortfolio(widget.profile.id);

      if (mounted) {
        setState(() {
          _services = services;
          _photos = photos;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _shareProfile() {
    final link = 'https://aiuda.app/p/${widget.profile.id}';
    Share.share(
      'Check out ${widget.profile.businessName} on Aiuda!\n$link',
      subject: '${widget.profile.businessName} - Aiuda',
    );
  }

  void _copyLink() {
    final link = 'https://aiuda.app/p/${widget.profile.id}';
    Clipboard.setData(ClipboardData(text: link));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Link copied to clipboard'),
        backgroundColor: Colors.green,
      ),
    );
  }

  String _getIndustryNames() {
    return widget.profile.industries
        .map((id) => _taxonomyService.getIndustry(id)?.name ?? id)
        .join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with profile photo
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: _shareProfile,
              ),
              IconButton(
                icon: const Icon(Icons.link),
                onPressed: _copyLink,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.primaryContainer,
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        backgroundImage: profile.profileImageUrl != null
                            ? CachedNetworkImageProvider(
                                profile.profileImageUrl!)
                            : null,
                        child: profile.profileImageUrl == null
                            ? Text(
                                profile.businessName.isNotEmpty
                                    ? profile.businessName[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(fontSize: 36),
                              )
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        profile.businessName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      if (profile.professionalInfo?.title != null)
                        Text(
                          profile.professionalInfo!.title,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: _isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Info card
                      Card(
                        margin: const EdgeInsets.all(16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Rating placeholder
                              Row(
                                children: [
                                  const Icon(Icons.star,
                                      color: Colors.amber, size: 20),
                                  const SizedBox(width: 4),
                                  Text(
                                    '5.0',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  Text(
                                    ' (0 reviews)',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Colors.grey[600],
                                        ),
                                  ),
                                  const Spacer(),
                                  if (profile.isAvailable)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green[100],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'Available',
                                        style: TextStyle(
                                          color: Colors.green[800],
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Industries
                              if (profile.industries.isNotEmpty) ...[
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: profile.industries.map((id) {
                                    final industry =
                                        _taxonomyService.getIndustry(id);
                                    return Chip(
                                      label: Text(industry?.name ?? id),
                                      visualDensity: VisualDensity.compact,
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 16),
                              ],

                              // Bio
                              if (profile.professionalInfo?.bio.isNotEmpty ==
                                  true) ...[
                                Text(
                                  'About',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  profile.professionalInfo!.bio,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 16),
                              ],

                              // Experience
                              if ((profile.professionalInfo?.yearsExperience ??
                                      0) >
                                  0)
                                Row(
                                  children: [
                                    const Icon(Icons.work_history,
                                        size: 20, color: Colors.grey),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${profile.professionalInfo!.yearsExperience} years experience',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                    ),
                                  ],
                                ),

                              // Location
                              if (profile.location != null) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on,
                                        size: 20, color: Colors.grey),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        profile.location!.address,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                      // Services
                      if (_services.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Services',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _services.length,
                          itemBuilder: (context, index) {
                            final service = _services[index];
                            return ListTile(
                              title: Text(service.name),
                              subtitle: Text('${service.durationMinutes} min'),
                              trailing: Text(
                                '\$${service.price.toStringAsFixed(2)}',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Portfolio
                      if (_photos.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Portfolio',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 120,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            scrollDirection: Axis.horizontal,
                            itemCount: _photos.length,
                            itemBuilder: (context, index) {
                              final photo = _photos[index];
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: CachedNetworkImage(
                                    imageUrl: photo.url,
                                    width: 120,
                                    height: 120,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Book button placeholder
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: FilledButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Booking coming in Sprint 11!'),
                              ),
                            );
                          },
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(50),
                          ),
                          child: const Text('Book Appointment'),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
