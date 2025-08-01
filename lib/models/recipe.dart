class Recipe {
  final String id;
  final String userCreated;
  final DateTime dateCreated;
  final String? userUpdated;
  final DateTime? dateUpdated;
  final String idCookbook;
  final String title;
  final String? subtitle;
  final int? preparationTime;
  final int? cookingTime;
  final int? idCategory;
  final int? difficultyLevel;
  final List<String> tags;
  final int? cost;
  final String? presentationText;
  final int? numberPeople;
  final bool isSharedEveryone;
  final String? internalComment;
  final int? restingTime;
  final String? photo;

  Recipe({
    required this.id,
    required this.userCreated,
    required this.dateCreated,
    this.userUpdated,
    this.dateUpdated,
    required this.idCookbook,
    required this.title,
    this.subtitle,
    this.preparationTime,
    this.cookingTime,
    this.idCategory,
    this.difficultyLevel,
    this.tags = const [],
    this.cost,
    this.presentationText,
    this.numberPeople,
    this.isSharedEveryone = false,
    this.internalComment,
    this.restingTime,
    this.photo,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'],
      userCreated: json['user_created'],
      dateCreated: DateTime.parse(json['date_created']),
      userUpdated: json['user_updated'],
      dateUpdated: json['date_updated'] != null ? DateTime.parse(json['date_updated']) : null,
      idCookbook: json['id_cookbook'],
      title: json['title'],
      subtitle: json['subtitle'],
      preparationTime: json['preparation_time'],
      cookingTime: json['cooking_time'],
      idCategory: json['id_category'],
      difficultyLevel: json['difficulty_level'],
      tags: json['tags'] != null ? List<String>.from(json['tags']) : [],
      cost: json['cost'],
      presentationText: json['presentation_text'],
      numberPeople: json['number_people'],
      isSharedEveryone: json['is_shared_everyone'] ?? false,
      internalComment: json['internal_comment'],
      restingTime: json['resting_time'],
      photo: json['photo'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_created': userCreated,
      'date_created': dateCreated.toIso8601String(),
      'user_updated': userUpdated,
      'date_updated': dateUpdated?.toIso8601String(),
      'id_cookbook': idCookbook,
      'title': title,
      'subtitle': subtitle,
      'preparation_time': preparationTime,
      'cooking_time': cookingTime,
      'id_category': idCategory,
      'difficulty_level': difficultyLevel,
      'tags': tags,
      'cost': cost,
      'presentation_text': presentationText,
      'number_people': numberPeople,
      'is_shared_everyone': isSharedEveryone,
      'internal_comment': internalComment,
      'resting_time': restingTime,
      'photo': photo,
    };
  }
}

class RecipeIngredient {
  final String id;
  final String userCreated;
  final DateTime dateCreated;
  final String? userUpdated;
  final DateTime? dateUpdated;
  final String idIngredient;
  final String quantity;
  final String? unit;
  final String? article;
  final String idRecipe;
  final String idCookbook;
  final String? additionalInformation;

  RecipeIngredient({
    required this.id,
    required this.userCreated,
    required this.dateCreated,
    this.userUpdated,
    this.dateUpdated,
    required this.idIngredient,
    required this.quantity,
    this.unit,
    this.article,
    required this.idRecipe,
    required this.idCookbook,
    this.additionalInformation,
  });

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) {
    return RecipeIngredient(
      id: json['id'],
      userCreated: json['user_created'],
      dateCreated: DateTime.parse(json['date_created']),
      userUpdated: json['user_updated'],
      dateUpdated: json['date_updated'] != null ? DateTime.parse(json['date_updated']) : null,
      idIngredient: json['id_ingredient'].toString(),
      quantity: json['quantity'],
      unit: json['unit'],
      article: json['article'],
      idRecipe: json['id_recipe'],
      idCookbook: json['id_cookbook'],
      additionalInformation: json['additional_information'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_created': userCreated,
      'date_created': dateCreated.toIso8601String(),
      'user_updated': userUpdated,
      'date_updated': dateUpdated?.toIso8601String(),
      'id_ingredient': idIngredient,
      'quantity': quantity,
      'unit': unit,
      'article': article,
      'id_recipe': idRecipe,
      'id_cookbook': idCookbook,
      'additional_information': additionalInformation,
    };
  }
}