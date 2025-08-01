import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/ingredient.dart';
import '../models/category.dart';
import 'database_service.dart';

class DataMigrationService {
  final DatabaseService _dbService = DatabaseService();

  Future<void> migrateIngredientsFromJson() async {
    try {
      final String jsonString = await rootBundle.loadString('resources/ingredients_fr.json');
      final List<dynamic> ingredientsList = jsonDecode(jsonString);
      
      for (final ingredientData in ingredientsList) {
        final ingredient = Ingredient.fromJson(ingredientData);
        await _dbService.insertIngredient(ingredient);
      }
    } catch (e) {
      // Handle error silently or log
    }
  }

  Future<void> migrateCategoriesFromJson() async {
    try {
      final String jsonString = await rootBundle.loadString('lib/category_fr.json');
      final Map<String, dynamic> categoriesData = jsonDecode(jsonString);
      final List<dynamic> categoriesList = categoriesData['categories'];
      
      int categoryId = 1;
      
      for (final categoryData in categoriesList) {
        final mainCategoryName = categoryData['name'];
        final mainCategory = Category(
          id: categoryId,
          name: mainCategoryName,
        );
        
        await _dbService.insertCategory(mainCategory);
        final mainCategoryId = categoryId;
        categoryId++;
        
        final List<dynamic>? subcategories = categoryData['subcategories'];
        if (subcategories != null) {
          for (final subcategoryName in subcategories) {
            final subcategory = Category(
              id: categoryId,
              name: subcategoryName,
              parentId: mainCategoryId,
            );
            
            await _dbService.insertCategory(subcategory);
            categoryId++;
          }
        }
      }
    } catch (e) {
      // Handle error silently or log
    }
  }

  Future<bool> shouldMigrate() async {
    final ingredients = await _dbService.getIngredients();
    final categories = await _dbService.getCategories();
    
    return ingredients.isEmpty && categories.isEmpty;
  }

  Future<void> performInitialMigration() async {
    if (await shouldMigrate()) {
      await migrateCategoriesFromJson();
      await migrateIngredientsFromJson();
    }
  }
}