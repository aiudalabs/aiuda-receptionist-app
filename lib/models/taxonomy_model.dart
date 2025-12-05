class ServiceTag {
  final String id;
  final String name;

  ServiceTag({
    required this.id,
    required this.name,
  });

  factory ServiceTag.fromMap(Map<String, dynamic> map) {
    return ServiceTag(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }
}

class ServiceCategory {
  final String id;
  final String name;
  final List<ServiceTag> tags;
  final List<String> commonServices;

  ServiceCategory({
    required this.id,
    required this.name,
    required this.tags,
    this.commonServices = const [],
  });

  factory ServiceCategory.fromMap(Map<String, dynamic> map) {
    final tagsData = map['tags'] as List<dynamic>? ?? [];
    final tags = tagsData
        .map((tag) => ServiceTag.fromMap(tag as Map<String, dynamic>))
        .toList();

    return ServiceCategory(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      tags: tags,
      commonServices: List<String>.from(map['commonServices'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'tags': tags.map((tag) => tag.toMap()).toList(),
      'commonServices': commonServices,
    };
  }
}

class Industry {
  final String id;
  final String name;
  final String icon;
  final String description;
  final List<ServiceCategory> categories;

  Industry({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
    required this.categories,
  });

  factory Industry.fromMap(Map<String, dynamic> map) {
    final categoriesData = map['categories'] as List<dynamic>? ?? [];
    final categories = categoriesData
        .map((cat) => ServiceCategory.fromMap(cat as Map<String, dynamic>))
        .toList();

    return Industry(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      icon: map['icon'] ?? 'work',
      description: map['description'] ?? '',
      categories: categories,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'description': description,
      'categories': categories.map((cat) => cat.toMap()).toList(),
    };
  }
}

class ServiceTaxonomy {
  final List<Industry> industries;

  ServiceTaxonomy({required this.industries});

  factory ServiceTaxonomy.fromMap(Map<String, dynamic> map) {
    final industriesData = map['industries'] as List<dynamic>? ?? [];
    final industries = industriesData
        .map((ind) => Industry.fromMap(ind as Map<String, dynamic>))
        .toList();

    return ServiceTaxonomy(industries: industries);
  }

  Map<String, dynamic> toMap() {
    return {
      'industries': industries.map((ind) => ind.toMap()).toList(),
    };
  }

  Industry? getIndustry(String id) {
    try {
      return industries.firstWhere((ind) => ind.id == id);
    } catch (e) {
      return null;
    }
  }

  ServiceCategory? getCategory(String industryId, String categoryId) {
    final industry = getIndustry(industryId);
    if (industry == null) return null;

    try {
      return industry.categories.firstWhere((cat) => cat.id == categoryId);
    } catch (e) {
      return null;
    }
  }

  List<ServiceCategory> getCategoriesForIndustry(String industryId) {
    final industry = getIndustry(industryId);
    return industry?.categories ?? [];
  }

  List<ServiceTag> getTagsForCategory(String industryId, String categoryId) {
    final category = getCategory(industryId, categoryId);
    return category?.tags ?? [];
  }
}
