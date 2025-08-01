import 'dart:convert';
import '../models/category.dart';
import 'auth_service.dart';

class CategoryService {
  final AuthService _authService = AuthService();

  Future<List<Category>> getCategories() async {
    final response = await _authService.authenticatedRequest('GET', '/items/categories');

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final List<dynamic> categoriesData = data['data'];
      return categoriesData.map((categoryJson) => Category.fromJson(categoryJson)).toList();
    } else {
      throw Exception('Erreur lors du chargement des catégories: ${response.statusCode}');
    }
  }

  Future<Category?> getCategoryById(int id) async {
    final response = await _authService.authenticatedRequest('GET', '/items/categories/$id');

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return Category.fromJson(data['data']);
    } else if (response.statusCode == 404) {
      return null;
    } else {
      throw Exception('Erreur lors du chargement de la catégorie: ${response.statusCode}');
    }
  }

  List<Category> getParentCategories(List<Category> categories) {
    return categories.where((category) => category.isParentCategory).toList();
  }

  List<Category> getSubCategories(List<Category> categories, int parentId) {
    return categories.where((category) => category.idParent == parentId).toList();
  }

  String getCategoryPath(List<Category> categories, int categoryId) {
    final category = categories.firstWhere(
      (c) => c.id == categoryId,
      orElse: () => Category(
        id: 0,
        userCreated: '',
        dateCreated: DateTime.now(),
        name: 'Catégorie inconnue',
      ),
    );

    if (category.idParent == null) {
      return category.name;
    }

    final parent = categories.firstWhere(
      (c) => c.id == category.idParent,
      orElse: () => Category(
        id: 0,
        userCreated: '',
        dateCreated: DateTime.now(),
        name: 'Catégorie inconnue',
      ),
    );

    return '${parent.name} > ${category.name}';
  }
}