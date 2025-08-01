class Ingredient {
  final String id;
  final String userCreated;
  final DateTime dateCreated;
  final String? userUpdated;
  final DateTime? dateUpdated;
  final String singularName;
  final String? pluralName;
  final String article;
  final List<String> units;

  Ingredient({
    required this.id,
    required this.userCreated,
    required this.dateCreated,
    this.userUpdated,
    this.dateUpdated,
    required this.singularName,
    this.pluralName,
    required this.article,
    required this.units,
  });

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      id: json['id'].toString(),
      userCreated: json['user_created'] ?? '',
      dateCreated: DateTime.parse(json['date_created']),
      userUpdated: json['user_updated'],
      dateUpdated: json['date_updated'] != null ? DateTime.parse(json['date_updated']) : null,
      singularName: json['singular_name'],
      pluralName: json['plural_name'],
      article: json['article'],
      units: List<String>.from(json['units'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_created': userCreated,
      'date_created': dateCreated.toIso8601String(),
      'user_updated': userUpdated,
      'date_updated': dateUpdated?.toIso8601String(),
      'singular_name': singularName,
      'plural_name': pluralName,
      'article': article,
      'units': units,
    };
  }

  // Helper pour l'affichage
  String get displayName => singularName;
  String get defaultUnit => units.isNotEmpty ? units.first : '';
  String get effectivePluralName => pluralName ?? singularName;
}