import 'dart:convert';
import '../models/recipe.dart';
import '../services/auth_service.dart';

class RecipeService {
  final AuthService _authService = AuthService();

  Future<List<Recipe>> getRecentRecipes({int limit = 10}) async {
    try {
      final currentUser = _authService.currentUser;
      
      // First try without filter to see if there are any recipes
      String endpoint = '/items/recipes?sort=-date_created&limit=$limit';
      
      final response = await _authService.authenticatedRequest('GET', endpoint);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data'] != null) {
          final List<dynamic> recipesData = data['data'];
          
          // If user has cookbookId, filter the results
          if (currentUser?.cookbookId != null) {
            final filteredRecipes = recipesData
                .where((json) => json['id_cookbook'] == currentUser!.cookbookId)
                .toList();
            return filteredRecipes.map((json) => Recipe.fromJson(json)).toList();
          }
          
          // Otherwise return all recipes (for debugging)
          return recipesData.map((json) => Recipe.fromJson(json)).toList();
        }
      } else {
        // Log error for debugging
        throw Exception('Failed to load recipes: ${response.statusCode} - ${response.body}');
      }
      return [];
    } catch (e) {
      // Log error for debugging
      rethrow;
    }
  }

  Future<List<Recipe>> getAllRecipes() async {
    try {
      final response = await _authService.authenticatedRequest(
        'GET',
        '/items/recipes',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> recipesData = data['data'];
        return recipesData.map((json) => Recipe.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Recipe?> getRecipe(String id) async {
    try {
      final response = await _authService.authenticatedRequest(
        'GET',
        '/items/recipes/$id',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Recipe.fromJson(data['data']);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Recipe> createRecipe(Recipe recipe) async {
    final currentUser = _authService.currentUser;
    
    if (currentUser?.cookbookId == null) {
      throw Exception('Cookbook ID not found');
    }

    // Créer seulement les données nécessaires, sans les champs système
    final recipeData = <String, dynamic>{
      'id_cookbook': currentUser!.cookbookId,
      'title': recipe.title,
      'subtitle': recipe.subtitle,
      'preparation_time': recipe.preparationTime,
      'cooking_time': recipe.cookingTime,
      'id_category': recipe.idCategory,
      'difficulty_level': recipe.difficultyLevel,
      'tags': recipe.tags,
      'cost': recipe.cost,
      'presentation_text': recipe.presentationText,
      'number_people': recipe.numberPeople,
      'is_shared_everyone': recipe.isSharedEveryone,
      'internal_comment': recipe.internalComment,
      'resting_time': recipe.restingTime,
      'photo': recipe.photo,
    };

    final response = await _authService.authenticatedRequest(
      'POST',
      '/items/recipes',
      body: recipeData,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return Recipe.fromJson(data['data']);
    } else {
      throw Exception('Erreur lors de la création de la recette: ${response.statusCode} - ${response.body}');
    }
  }

  Future<Recipe> updateRecipe(Recipe recipe) async {
    // Pour la modification, ne pas envoyer les champs système
    final recipeData = <String, dynamic>{
      'title': recipe.title,
      'subtitle': recipe.subtitle,
      'preparation_time': recipe.preparationTime,
      'cooking_time': recipe.cookingTime,
      'id_category': recipe.idCategory,
      'difficulty_level': recipe.difficultyLevel,
      'tags': recipe.tags,
      'cost': recipe.cost,
      'presentation_text': recipe.presentationText,
      'number_people': recipe.numberPeople,
      'is_shared_everyone': recipe.isSharedEveryone,
      'internal_comment': recipe.internalComment,
      'resting_time': recipe.restingTime,
      'photo': recipe.photo,
    };

    final response = await _authService.authenticatedRequest(
      'PATCH',
      '/items/recipes/${recipe.id}',
      body: recipeData,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Recipe.fromJson(data['data']);
    } else {
      throw Exception('Erreur lors de la mise à jour de la recette: ${response.statusCode} - ${response.body}');
    }
  }

  Future<bool> deleteRecipe(String id) async {
    try {
      final response = await _authService.authenticatedRequest(
        'DELETE',
        '/items/recipes/$id',
      );

      return response.statusCode == 204;
    } catch (e) {
      return false;
    }
  }

  Future<List<RecipeIngredient>> getRecipeIngredients(String recipeId) async {
    try {
      final response = await _authService.authenticatedRequest(
        'GET',
        '/items/recipes_ingredients?filter[id_recipe][_eq]=$recipeId',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> ingredientsData = data['data'];
        return ingredientsData.map((json) => RecipeIngredient.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<RecipeIngredient?> addRecipeIngredient(RecipeIngredient ingredient) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser?.cookbookId == null) {
        throw Exception('Cookbook ID not found');
      }

      final ingredientData = ingredient.toJson();
      // Ne pas envoyer les champs système pour la création
      ingredientData.remove('id');
      ingredientData.remove('user_created');
      ingredientData.remove('date_created');
      ingredientData.remove('user_updated');
      ingredientData.remove('date_updated');
      
      // Pour les ingrédients personnalisés, ne pas envoyer id_ingredient s'il est vide
      if (ingredient.isCustomIngredient && ingredientData['id_ingredient']?.isEmpty == true) {
        ingredientData.remove('id_ingredient');
      }
      
      print('Debug: Données à envoyer pour création ingrédient: $ingredientData');

      final response = await _authService.authenticatedRequest(
        'POST',
        '/items/recipes_ingredients',
        body: ingredientData,
      );

      print('Debug: Réponse création ingrédient: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return RecipeIngredient.fromJson(data['data']);
      } else {
        print('Debug: Erreur création ingrédient: ${response.statusCode} - ${response.body}');
      }
      return null;
    } catch (e) {
      print('Debug: Exception lors création ingrédient: $e');
      return null;
    }
  }

  Future<RecipeIngredient?> updateRecipeIngredient(RecipeIngredient ingredient) async {
    try {
      final ingredientData = <String, dynamic>{
        'quantity': ingredient.quantity,
        'unit': ingredient.unit,
        'article': ingredient.article,
        'additional_information': ingredient.additionalInformation,
        'is_custom_ingredient': ingredient.isCustomIngredient,
        'custom_ingredient_name': ingredient.customIngredientName,
      };
      
      // Ajouter id_ingredient seulement s'il n'est pas vide
      if (ingredient.idIngredient.isNotEmpty) {
        ingredientData['id_ingredient'] = ingredient.idIngredient;
      }

      print('Debug: Données à envoyer pour mise à jour ingrédient: $ingredientData');

      final response = await _authService.authenticatedRequest(
        'PATCH',
        '/items/recipes_ingredients/${ingredient.id}',
        body: ingredientData,
      );

      print('Debug: Réponse mise à jour ingrédient: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return RecipeIngredient.fromJson(data['data']);
      } else {
        print('Debug: Erreur mise à jour ingrédient: ${response.statusCode} - ${response.body}');
      }
      return null;
    } catch (e) {
      print('Debug: Exception lors mise à jour ingrédient: $e');
      return null;
    }
  }

  Future<bool> deleteRecipeIngredient(String id) async {
    try {
      final response = await _authService.authenticatedRequest(
        'DELETE',
        '/items/recipes_ingredients/$id',
      );

      return response.statusCode == 204;
    } catch (e) {
      return false;
    }
  }
}