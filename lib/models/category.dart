class Category {
  final int id;
  final String name;
  final int? parentId;
  final List<Category> subcategories;

  Category({
    required this.id,
    required this.name,
    this.parentId,
    this.subcategories = const [],
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      parentId: json['parent_id'],
      subcategories: json['subcategories'] != null
          ? (json['subcategories'] as List).map((e) => Category.fromJson(e)).toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'parent_id': parentId,
      'subcategories': subcategories.map((e) => e.toJson()).toList(),
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'parent_id': parentId,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'],
      name: map['name'],
      parentId: map['parent_id'],
    );
  }

  bool get isMainCategory => parentId == null;
  bool get isSubcategory => parentId != null;
}