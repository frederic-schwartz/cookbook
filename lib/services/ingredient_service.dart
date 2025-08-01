import 'dart:convert';
import '../models/ingredient.dart';
import 'auth_service.dart';

class IngredientService {
  static final IngredientService _instance = IngredientService._internal();
  factory IngredientService() => _instance;
  IngredientService._internal();

  final AuthService _authService = AuthService();
  static const String baseUrl = 'https://api-cookbook-9fd56e.online404.com';

  Future<List<Ingredient>> getIngredients() async {
    try {
      final response = await _authService.authenticatedRequest(
        'GET',
        '/items/ingredients',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> items = data['data'] ?? [];
        return items.map((item) => Ingredient.fromJson(item)).toList();
      } else {
        throw Exception('Erreur lors du chargement des ingrédients: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  Future<Ingredient?> getIngredient(String id) async {
    try {
      final response = await _authService.authenticatedRequest(
        'GET',
        '/items/ingredients/$id',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Ingredient.fromJson(data['data']);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Erreur lors du chargement de l\'ingrédient: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  Future<Ingredient> createIngredient(Ingredient ingredient) async {
    try {
      final body = {
        'singular_name': ingredient.singularName,
        'plural_name': ingredient.pluralName,
        'article': ingredient.article,
        'units': ingredient.units,
      };

      final response = await _authService.authenticatedRequest(
        'POST',
        '/items/ingredients',
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return Ingredient.fromJson(data['data']);
      } else {
        throw Exception('Erreur lors de la création de l\'ingrédient: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  Future<Ingredient> updateIngredient(Ingredient ingredient) async {
    try {
      final body = {
        'singular_name': ingredient.singularName,
        'plural_name': ingredient.pluralName,
        'article': ingredient.article,
        'units': ingredient.units,
      };

      final response = await _authService.authenticatedRequest(
        'PATCH',
        '/items/ingredients/${ingredient.id}',
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Ingredient.fromJson(data['data']);
      } else {
        throw Exception('Erreur lors de la mise à jour de l\'ingrédient: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  Future<void> deleteIngredient(String id) async {
    try {
      final response = await _authService.authenticatedRequest(
        'DELETE',
        '/items/ingredients/$id',
      );

      if (response.statusCode != 204) {
        throw Exception('Erreur lors de la suppression de l\'ingrédient: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  Future<List<Ingredient>> searchIngredients(String query) async {
    try {
      final encodedQuery = Uri.encodeComponent(query);
      final response = await _authService.authenticatedRequest(
        'GET',
        '/items/ingredients?filter[singular_name][_icontains]=$encodedQuery',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> items = data['data'] ?? [];
        return items.map((item) => Ingredient.fromJson(item)).toList();
      } else {
        throw Exception('Erreur lors de la recherche: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }
}