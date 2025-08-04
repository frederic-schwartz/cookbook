import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../models/category.dart';
import '../models/step.dart' as recipe_step;
import '../services/recipe_service.dart';
import '../services/ingredient_service.dart';
import '../services/category_service.dart';
import '../services/step_service.dart';
import 'recipe_form_screen.dart';

class RecipeDetailScreen extends StatefulWidget {
  final Recipe recipe;

  const RecipeDetailScreen({super.key, required this.recipe});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  final RecipeService _recipeService = RecipeService();
  final IngredientService _ingredientService = IngredientService();
  final CategoryService _categoryService = CategoryService();
  final StepService _stepService = StepService();
  
  Recipe? _currentRecipe; // Pour stocker la recette mise à jour
  List<RecipeIngredient> _recipeIngredients = [];
  Map<String, String> _ingredientNames = {};
  Map<String, String> _ingredientArticles = {};
  List<Category> _categories = [];
  List<recipe_step.Step> _steps = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _currentRecipe = widget.recipe; // Initialiser avec la recette passée
    _loadRecipeData();
  }

  Future<void> _loadRecipeData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Charger la recette mise à jour et les données associées en parallèle
      final futures = await Future.wait([
        _recipeService.getRecipe(widget.recipe.id),
        _recipeService.getRecipeIngredients(widget.recipe.id),
        _ingredientService.getIngredients(),
        _categoryService.getCategories(),
        _stepService.getStepsByRecipe(widget.recipe.id),
      ]);

      final updatedRecipe = futures[0] as Recipe?;
      final ingredients = futures[1] as List<RecipeIngredient>;
      final allIngredients = futures[2] as List;
      final categories = futures[3] as List<Category>;
      final steps = futures[4] as List<recipe_step.Step>;

      // Précharger tous les noms et articles d'ingrédients
      final ingredientNamesMap = <String, String>{};
      final ingredientArticlesMap = <String, String>{};
      for (final ingredient in allIngredients) {
        ingredientNamesMap[ingredient.id] = ingredient.singularName;
        ingredientArticlesMap[ingredient.id] = ingredient.article;
      }
      
      setState(() {
        // Mettre à jour la recette si elle a été rechargée avec succès
        if (updatedRecipe != null) {
          _currentRecipe = updatedRecipe;
        }
        _recipeIngredients = ingredients;
        _ingredientNames = ingredientNamesMap;
        _ingredientArticles = ingredientArticlesMap;
        _categories = categories;
        _steps = steps;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getIngredientName(String ingredientId) {
    final name = _ingredientNames[ingredientId];
    if (name != null) {
      return name;
    } else {
      return 'Ingrédient inconnu';
    }
  }

  String _getIngredientArticle(String ingredientId) {
    return _ingredientArticles[ingredientId] ?? '';
  }

  String _getCategoryName(int? categoryId) {
    if (categoryId == null) return 'Non catégorisé';
    return _categoryService.getCategoryPath(_categories, categoryId);
  }

  // Getter pour la recette courante avec fallback
  Recipe get currentRecipe => _currentRecipe ?? widget.recipe;

  String _formatDuration(int? minutes) {
    if (minutes == null || minutes == 0) return 'Non spécifié';
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (remainingMinutes == 0) return '$hours h';
    return '$hours h $remainingMinutes min';
  }

  String _getDifficultyText(int? level) {
    switch (level) {
      case 1:
        return 'Facile';
      case 2:
        return 'Moyen';
      case 3:
        return 'Difficile';
      default:
        return 'Non spécifié';
    }
  }

  Color _getDifficultyColor(int? level) {
    switch (level) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getCostText(int? cost) {
    if (cost == null) return 'Non spécifié';
    switch (cost) {
      case 1:
        return '€ - Économique';
      case 2:
        return '€€ - Moyen';
      case 3:
        return '€€€ - Cher';
      default:
        return 'Non spécifié';
    }
  }

  String _formatQuantity(String quantity) {
    // Essayer de parser comme un nombre
    final double? numericValue = double.tryParse(quantity);
    if (numericValue != null) {
      // Si c'est un entier, afficher sans décimales
      if (numericValue == numericValue.roundToDouble()) {
        return numericValue.toInt().toString();
      } else {
        // Pour les décimales, supprimer les zéros inutiles à la fin
        return numericValue.toString().replaceAll(RegExp(r'\.?0+$'), '');
      }
    }
    // Si ce n'est pas un nombre, retourner tel quel
    return quantity;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(currentRecipe.title),
        actions: [
          IconButton(
            onPressed: () async {
              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => RecipeFormScreen(recipe: currentRecipe),
                ),
              );
              
              // Recharger les données si la recette a été modifiée
              if (result == true) {
                _loadRecipeData();
              }
            },
            icon: const Icon(Icons.edit),
            tooltip: 'Modifier',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre et sous-titre
            Text(
              currentRecipe.title,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (currentRecipe.subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                currentRecipe.subtitle!,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Informations générales
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Informations',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoItem(
                            Icons.schedule,
                            'Préparation',
                            _formatDuration(currentRecipe.preparationTime),
                          ),
                        ),
                        Expanded(
                          child: _buildInfoItem(
                            Icons.whatshot,
                            'Cuisson',
                            _formatDuration(currentRecipe.cookingTime),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoItem(
                            Icons.people,
                            'Personnes',
                            currentRecipe.numberPeople?.toString() ?? 'Non spécifié',
                          ),
                        ),
                        Expanded(
                          child: _buildInfoItem(
                            Icons.star,
                            'Difficulté',
                            _getDifficultyText(currentRecipe.difficultyLevel),
                            color: _getDifficultyColor(currentRecipe.difficultyLevel),
                          ),
                        ),
                      ],
                    ),
                    if (currentRecipe.cost != null) ...[
                      const SizedBox(height: 16),
                      _buildInfoItem(
                        Icons.euro,
                        'Coût',
                        _getCostText(currentRecipe.cost),
                      ),
                    ],
                    if (currentRecipe.restingTime != null) ...[
                      const SizedBox(height: 16),
                      _buildInfoItem(
                        Icons.timer,
                        'Temps de repos',
                        _formatDuration(currentRecipe.restingTime),
                      ),
                    ],
                    const SizedBox(height: 16),
                    _buildInfoItem(
                      Icons.category,
                      'Catégorie',
                      _getCategoryName(currentRecipe.idCategory),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Présentation
            if (currentRecipe.presentationText != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Présentation',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        currentRecipe.presentationText!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Ingrédients
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ingrédients',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_isLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (_recipeIngredients.isEmpty)
                      Text(
                        'Aucun ingrédient spécifié',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      )
                    else
                      ..._recipeIngredients.map((recipeIngredient) {
                        final String ingredientName;
                        final String ingredientArticle;
                        
                        if (recipeIngredient.isCustomIngredient) {
                          // Ingrédient personnalisé
                          ingredientName = recipeIngredient.customIngredientName ?? 'Ingrédient personnalisé';
                          ingredientArticle = ''; // Pas d'article pour les ingrédients personnalisés
                        } else {
                          // Ingrédient de la base de données
                          ingredientName = _getIngredientName(recipeIngredient.idIngredient);
                          ingredientArticle = _getIngredientArticle(recipeIngredient.idIngredient);
                        }
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    style: Theme.of(context).textTheme.bodyMedium,
                                    children: [
                                      TextSpan(
                                        text: '${_formatQuantity(recipeIngredient.quantity)} ${recipeIngredient.unit ?? ''} ',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      if (ingredientArticle.isNotEmpty)
                                        TextSpan(text: '$ingredientArticle '),
                                      TextSpan(text: ingredientName),
                                      if (recipeIngredient.additionalInformation != null)
                                        TextSpan(
                                          text: ' (${recipeIngredient.additionalInformation!})',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Étapes
            if (_steps.isNotEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Étapes de préparation',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._steps.map((step) => _buildStepItem(step)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Tags
            if (currentRecipe.tags.isNotEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tags',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: currentRecipe.tags.map((tag) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withAlpha(25),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.primary.withAlpha(76),
                            ),
                          ),
                          child: Text(
                            tag,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        )).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Commentaire interne (si présent)
            if (currentRecipe.internalComment != null) ...[
              Card(
                color: Colors.amber[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.note, color: Colors.amber[700]),
                          const SizedBox(width: 8),
                          Text(
                            'Commentaire interne',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.amber[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        currentRecipe.internalComment!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color ?? Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildStepItem(recipe_step.Step step) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Numéro de l'étape
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${step.order}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // Description de l'étape
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6), // Aligner avec le numéro
                Text(
                  step.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}