class Step {
  final String id;
  final String userCreated;
  final DateTime dateCreated;
  final String? userUpdated;
  final DateTime? dateUpdated;
  final String idCookbook;
  final String idRecipe;
  final String description;
  final int order;

  Step({
    required this.id,
    required this.userCreated,
    required this.dateCreated,
    this.userUpdated,
    this.dateUpdated,
    required this.idCookbook,
    required this.idRecipe,
    required this.description,
    required this.order,
  });

  factory Step.fromJson(Map<String, dynamic> json) {
    return Step(
      id: json['id'],
      userCreated: json['user_created'],
      dateCreated: DateTime.parse(json['date_created']),
      userUpdated: json['user_updated'],
      dateUpdated: json['date_updated'] != null 
          ? DateTime.parse(json['date_updated']) 
          : null,
      idCookbook: json['id_cookbook'],
      idRecipe: json['id_recipe'],
      description: json['description'],
      order: json['order'],
    );
  }

  Map<String, dynamic> toJson({bool forCreation = false}) {
    if (forCreation) {
      // Pour la création, on ne envoie que les champs nécessaires
      return {
        'id_cookbook': idCookbook,
        'id_recipe': idRecipe,
        'description': description,
        'order': order,
      };
    }
    
    // Pour la modification, on envoie tous les champs
    return {
      'id': id,
      'user_created': userCreated,
      'date_created': dateCreated.toIso8601String(),
      'user_updated': userUpdated,
      'date_updated': dateUpdated?.toIso8601String(),
      'id_cookbook': idCookbook,
      'id_recipe': idRecipe,
      'description': description,
      'order': order,
    };
  }

  Step copyWith({
    String? id,
    String? userCreated,
    DateTime? dateCreated,
    String? userUpdated,
    DateTime? dateUpdated,
    String? idCookbook,
    String? idRecipe,
    String? description,
    int? order,
  }) {
    return Step(
      id: id ?? this.id,
      userCreated: userCreated ?? this.userCreated,
      dateCreated: dateCreated ?? this.dateCreated,
      userUpdated: userUpdated ?? this.userUpdated,
      dateUpdated: dateUpdated ?? this.dateUpdated,
      idCookbook: idCookbook ?? this.idCookbook,
      idRecipe: idRecipe ?? this.idRecipe,
      description: description ?? this.description,
      order: order ?? this.order,
    );
  }
}