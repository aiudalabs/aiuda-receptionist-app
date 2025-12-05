import '../models/taxonomy_model.dart';
import '../data/service_taxonomy.dart';

class TaxonomyService {
  static final TaxonomyService _instance = TaxonomyService._internal();
  factory TaxonomyService() => _instance;
  TaxonomyService._internal();

  ServiceTaxonomy? _taxonomy;

  /// Load taxonomy data
  ServiceTaxonomy getTaxonomy() {
    _taxonomy ??= ServiceTaxonomy.fromMap(serviceTaxonomyData);
    return _taxonomy!;
  }

  /// Get all industries
  List<Industry> getIndustries() {
    return getTaxonomy().industries;
  }

  /// Get industry by ID
  Industry? getIndustry(String industryId) {
    return getTaxonomy().getIndustry(industryId);
  }

  /// Get categories for an industry
  List<ServiceCategory> getCategoriesForIndustry(String industryId) {
    return getTaxonomy().getCategoriesForIndustry(industryId);
  }

  /// Get category by IDs
  ServiceCategory? getCategory(String industryId, String categoryId) {
    return getTaxonomy().getCategory(industryId, categoryId);
  }

  /// Get tags for a category
  List<ServiceTag> getTagsForCategory(String industryId, String categoryId) {
    return getTaxonomy().getTagsForCategory(industryId, categoryId);
  }

  /// Get common services for a category
  List<String> getCommonServicesForCategory(String industryId, String categoryId) {
    final category = getCategory(industryId, categoryId);
    return category?.commonServices ?? [];
  }

  /// Search tags across all categories (for autocomplete)
  List<ServiceTag> searchTags(String query) {
    if (query.isEmpty) return [];

    final allTags = <ServiceTag>[];
    final taxonomy = getTaxonomy();

    for (final industry in taxonomy.industries) {
      for (final category in industry.categories) {
        allTags.addAll(category.tags);
      }
    }

    final lowerQuery = query.toLowerCase();
    return allTags
        .where((tag) => tag.name.toLowerCase().contains(lowerQuery))
        .toList();
  }

  /// Get suggested category based on service name (simple keyword matching)
  Map<String, String>? suggestCategoryFromName(String serviceName) {
    if (serviceName.isEmpty) return null;

    final lowerName = serviceName.toLowerCase();
    final taxonomy = getTaxonomy();

    for (final industry in taxonomy.industries) {
      for (final category in industry.categories) {
        // Check if any tag matches the service name
        for (final tag in category.tags) {
          if (lowerName.contains(tag.name.toLowerCase()) ||
              tag.name.toLowerCase().contains(lowerName)) {
            return {
              'industryId': industry.id,
              'industryName': industry.name,
              'categoryId': category.id,
              'categoryName': category.name,
            };
          }
        }

        // Check if any common service matches
        for (final commonService in category.commonServices) {
          if (lowerName.contains(commonService.toLowerCase()) ||
              commonService.toLowerCase().contains(lowerName)) {
            return {
              'industryId': industry.id,
              'industryName': industry.name,
              'categoryId': category.id,
              'categoryName': category.name,
            };
          }
        }
      }
    }

    return null;
  }

  /// Get industry name by ID
  String getIndustryName(String industryId) {
    final industry = getIndustry(industryId);
    return industry?.name ?? industryId;
  }

  /// Get category name by IDs
  String getCategoryName(String industryId, String categoryId) {
    final category = getCategory(industryId, categoryId);
    return category?.name ?? categoryId;
  }
}
