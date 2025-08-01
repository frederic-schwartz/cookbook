class Category {
  final int id;
  final String userCreated;
  final DateTime dateCreated;
  final String? userUpdated;
  final DateTime? dateUpdated;
  final String name;
  final int? idParent;
  final String? description;

  Category({
    required this.id,
    required this.userCreated,
    required this.dateCreated,
    this.userUpdated,
    this.dateUpdated,
    required this.name,
    this.idParent,
    this.description,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      userCreated: json['user_created'],
      dateCreated: DateTime.parse(json['date_created']),
      userUpdated: json['user_updated'],
      dateUpdated: json['date_updated'] != null 
          ? DateTime.parse(json['date_updated']) 
          : null,
      name: json['name'],
      idParent: json['id_parent'],
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_created': userCreated,
      'date_created': dateCreated.toIso8601String(),
      'user_updated': userUpdated,
      'date_updated': dateUpdated?.toIso8601String(),
      'name': name,
      'id_parent': idParent,
      'description': description,
    };
  }

  bool get isParentCategory => idParent == null;
  
  String get fullName {
    return name;
  }
}