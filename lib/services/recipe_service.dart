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

  Future<Recipe?> createRecipe(Recipe recipe) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser?.cookbookId == null) {
        throw Exception('Cookbook ID not found');
      }

      final recipeData = recipe.toJson();
      recipeData['id_cookbook'] = currentUser!.cookbookId;

      final response = await _authService.authenticatedRequest(
        'POST',
        '/items/recipes',
        body: recipeData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return Recipe.fromJson(data['data']);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Recipe?> updateRecipe(Recipe recipe) async {
    try {
      final response = await _authService.authenticatedRequest(
        'PATCH',
        '/items/recipes/${recipe.id}',
        body: recipe.toJson(),
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
      ingredientData['id_cookbook'] = currentUser!.cookbookId;

      final response = await _authService.authenticatedRequest(
        'POST',
        '/items/recipes_ingredients',
        body: ingredientData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return RecipeIngredient.fromJson(data['data']);
      }
      return null;
    } catch (e) {
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