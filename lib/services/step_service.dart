import 'dart:convert';
import '../models/step.dart';
import 'auth_service.dart';

class StepService {
  final AuthService _authService = AuthService();

  Future<List<Step>> getStepsByRecipe(String recipeId) async {
    final response = await _authService.authenticatedRequest(
      'GET', 
      '/items/steps?filter[id_recipe][_eq]=$recipeId&sort=order'
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final List<dynamic> stepsData = data['data'];
      return stepsData.map((stepJson) => Step.fromJson(stepJson)).toList();
    } else {
      throw Exception('Erreur lors du chargement des étapes: ${response.statusCode}');
    }
  }

  Future<Step> createStep(Step step) async {
    final response = await _authService.authenticatedRequest(
      'POST',
      '/items/steps',
      body: step.toJson(forCreation: true),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final Map<String, dynamic> data = json.decode(response.body);
      return Step.fromJson(data['data']);
    } else {
      throw Exception('Erreur lors de la création de l\'étape: ${response.statusCode}');
    }
  }

  Future<Step> updateStep(Step step) async {
    final response = await _authService.authenticatedRequest(
      'PATCH',
      '/items/steps/${step.id}',
      body: step.toJson(),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return Step.fromJson(data['data']);
    } else {
      throw Exception('Erreur lors de la modification de l\'étape: ${response.statusCode}');
    }
  }

  Future<void> deleteStep(String stepId) async {
    final response = await _authService.authenticatedRequest(
      'DELETE',
      '/items/steps/$stepId',
    );

    if (response.statusCode != 204) {
      throw Exception('Erreur lors de la suppression de l\'étape: ${response.statusCode}');
    }
  }

  Future<void> updateStepsOrder(List<Step> steps) async {
    // Mettre à jour l'ordre de toutes les étapes
    for (int i = 0; i < steps.length; i++) {
      final updatedStep = steps[i].copyWith(order: i + 1);
      await updateStep(updatedStep);
    }
  }

  Future<void> deleteAllStepsForRecipe(String recipeId) async {
    final steps = await getStepsByRecipe(recipeId);
    for (final step in steps) {
      await deleteStep(step.id);
    }
  }
}