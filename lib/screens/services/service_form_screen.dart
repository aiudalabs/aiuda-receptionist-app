import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/provider_service.dart';
import '../../services/taxonomy_service.dart';
import '../../models/service_model.dart';
import '../../models/taxonomy_model.dart';

class ServiceFormScreen extends StatefulWidget {
  final String providerId;
  final ServiceModel? service; // null for new service, populated for edit

  const ServiceFormScreen({
    super.key,
    required this.providerId,
    this.service,
  });

  @override
  State<ServiceFormScreen> createState() => _ServiceFormScreenState();
}

class _ServiceFormScreenState extends State<ServiceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _providerService = ProviderService();
  final _taxonomyService = TaxonomyService();

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _durationController;

  String? _selectedIndustryId;
  String? _selectedCategoryId;
  List<String> _selectedTags = [];
  String _selectedCurrency = 'USD';
  bool _isLoading = false;

  final List<String> _currencies = [
    'USD',
    'EUR',
    'GBP',
    'CAD',
    'PAB',
  ];

  @override
  void initState() {
    super.initState();

    // Initialize controllers with existing data if editing
    _nameController = TextEditingController(text: widget.service?.name ?? '');
    _descriptionController =
        TextEditingController(text: widget.service?.description ?? '');
    _priceController = TextEditingController(
      text: widget.service?.price.toStringAsFixed(2) ?? '',
    );
    _durationController = TextEditingController(
      text: widget.service?.durationMinutes.toString() ?? '30',
    );

    if (widget.service != null) {
      _selectedIndustryId = widget.service!.industryId;
      _selectedCategoryId = widget.service!.categoryId;
      _selectedTags = List<String>.from(widget.service!.tags);
      _selectedCurrency = widget.service!.currency;
    }

    // Listen for service name changes to auto-suggest category
    _nameController.addListener(_onNameChanged);
  }

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  void _onNameChanged() {
    // Only auto-suggest if nothing is selected yet
    if (_selectedIndustryId == null && _selectedCategoryId == null) {
      final suggestion =
          _taxonomyService.suggestCategoryFromName(_nameController.text);
      if (suggestion != null) {
        setState(() {
          _selectedIndustryId = suggestion['industryId'];
          _selectedCategoryId = suggestion['categoryId'];
        });
      }
    }
  }

  bool get _isEditMode => widget.service != null;

  List<ServiceCategory> get _availableCategories {
    if (_selectedIndustryId == null) return [];
    return _taxonomyService.getCategoriesForIndustry(_selectedIndustryId!);
  }

  List<ServiceTag> get _availableTags {
    if (_selectedIndustryId == null || _selectedCategoryId == null) return [];
    return _taxonomyService.getTagsForCategory(
        _selectedIndustryId!, _selectedCategoryId!);
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
        title: Text(_isEditMode ? 'Edit Service' : 'Add Service'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Service Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Service Name *',
                hintText: 'e.g., Haircut, Manicure, Oil Change',
                prefixIcon: Icon(Icons.work_outline),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a service name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Industry Selection
            DropdownButtonFormField<String>(
              value: _selectedIndustryId,
              decoration: const InputDecoration(
                labelText: 'Industry *',
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: industries.map((industry) {
                return DropdownMenuItem(
                  value: industry.id,
                  child: Row(
                    children: [
                      Icon(_getIndustryIcon(industry.icon), size: 20),
                      const SizedBox(width: 8),
                      Text(industry.name),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedIndustryId = value;
                  _selectedCategoryId =
                      null; // Reset category when industry changes
                  _selectedTags = []; // Reset tags
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select an industry';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Category Selection (depends on industry)
            DropdownButtonFormField<String>(
              value: _selectedCategoryId,
              decoration: const InputDecoration(
                labelText: 'Category *',
                prefixIcon: Icon(Icons.folder_outlined),
              ),
              items: _availableCategories.map((category) {
                return DropdownMenuItem(
                  value: category.id,
                  child: Text(category.name),
                );
              }).toList(),
              onChanged: _selectedIndustryId == null
                  ? null
                  : (value) {
                      setState(() {
                        _selectedCategoryId = value;
                        _selectedTags = []; // Reset tags when category changes
                      });
                    },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a category';
                }
                return null;
              },
              disabledHint: const Text('Select an industry first'),
            ),
            const SizedBox(height: 16),

            // Tags Selection (depends on category)
            if (_availableTags.isNotEmpty) ...[
              Text(
                'Tags (optional):',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableTags.map((tag) {
                  final isSelected = _selectedTags.contains(tag.id);
                  return FilterChip(
                    label: Text(tag.name),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedTags.add(tag.id);
                        } else {
                          _selectedTags.remove(tag.id);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],

            // Description
            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Describe what this service includes...',
                prefixIcon: Icon(Icons.description_outlined),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),

            // Duration
            TextFormField(
              controller: _durationController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Duration (minutes) *',
                hintText: 'e.g., 30, 60, 120',
                prefixIcon: Icon(Icons.access_time_outlined),
                suffixText: 'min',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter duration';
                }
                final duration = int.tryParse(value);
                if (duration == null || duration <= 0) {
                  return 'Please enter a valid duration';
                }
                if (duration > 480) {
                  return 'Duration cannot exceed 8 hours (480 minutes)';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Price & Currency
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _priceController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Price *',
                      hintText: '0.00',
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter price';
                      }
                      final price = double.tryParse(value);
                      if (price == null || price < 0) {
                        return 'Please enter a valid price';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedCurrency,
                    decoration: const InputDecoration(
                      labelText: 'Currency',
                    ),
                    items: _currencies.map((currency) {
                      return DropdownMenuItem(
                        value: currency,
                        child: Text(currency),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedCurrency = value);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Info card
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.info_outlined, color: Colors.blue[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Clients will see this service when booking appointments with you.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.blue[900],
                            ),
                      ),
                    ),
                  ],
                ),
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
                  : Text(_isEditMode ? 'Update Service' : 'Create Service'),
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
      final name = _nameController.text.trim();
      final description = _descriptionController.text.trim();
      final price = double.parse(_priceController.text.trim());
      final duration = int.parse(_durationController.text.trim());

      // Get display category name for backward compatibility
      final categoryName = _taxonomyService.getCategoryName(
        _selectedIndustryId!,
        _selectedCategoryId!,
      );

      if (_isEditMode) {
        // Update existing service
        await _providerService.updateService(
          widget.service!.id,
          {
            'name': name,
            'description': description,
            'price': price,
            'durationMinutes': duration,
            'category': categoryName, // Keep for backward compatibility
            'industryId': _selectedIndustryId,
            'categoryId': _selectedCategoryId,
            'tags': _selectedTags,
            'currency': _selectedCurrency,
          },
        );
      } else {
        // Create new service
        await _providerService.createService(
          name: name,
          description: description,
          durationMinutes: duration,
          price: price,
          currency: _selectedCurrency,
          category: categoryName, // Keep for backward compatibility
          providerId: widget.providerId,
          industryId: _selectedIndustryId,
          categoryId: _selectedCategoryId,
          tags: _selectedTags,
        );
      }

      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate success
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
