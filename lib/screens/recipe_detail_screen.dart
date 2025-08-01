import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../models/category.dart';
import '../services/recipe_service.dart';
import '../services/ingredient_service.dart';
import '../services/category_service.dart';

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
  
  List<RecipeIngredient> _recipeIngredients = [];
  Map<String, String> _ingredientNames = {};
  Map<String, String> _ingredientArticles = {};
  List<Category> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecipeData();
  }

  Future<void> _loadRecipeData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Charger les ingrédients et catégories en parallèle
      final futures = await Future.wait([
        _recipeService.getRecipeIngredients(widget.recipe.id),
        _ingredientService.getIngredients(),
        _categoryService.getCategories(),
      ]);

      final ingredients = futures[0] as List<RecipeIngredient>;
      final allIngredients = futures[1] as List;
      final categories = futures[2] as List<Category>;

      // Précharger tous les noms et articles d'ingrédients
      final ingredientNamesMap = <String, String>{};
      final ingredientArticlesMap = <String, String>{};
      for (final ingredient in allIngredients) {
        ingredientNamesMap[ingredient.id] = ingredient.singularName;
        ingredientArticlesMap[ingredient.id] = ingredient.article;
      }
      
      setState(() {
        _recipeIngredients = ingredients;
        _ingredientNames = ingredientNamesMap;
        _ingredientArticles = ingredientArticlesMap;
        _categories = categories;
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
    final filledEuros = '€' * cost;
    final emptyEuros = '€' * (3 - cost).clamp(0, 3);
    return filledEuros + emptyEuros;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recipe.title),
        actions: [
          IconButton(
            onPressed: () {
              // TODO: Navigate to edit recipe
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
              widget.recipe.title,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (widget.recipe.subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                widget.recipe.subtitle!,
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
                            _formatDuration(widget.recipe.preparationTime),
                          ),
                        ),
                        Expanded(
                          child: _buildInfoItem(
                            Icons.whatshot,
                            'Cuisson',
                            _formatDuration(widget.recipe.cookingTime),
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
                            widget.recipe.numberPeople?.toString() ?? 'Non spécifié',
                          ),
                        ),
                        Expanded(
                          child: _buildInfoItem(
                            Icons.star,
                            'Difficulté',
                            _getDifficultyText(widget.recipe.difficultyLevel),
                            color: _getDifficultyColor(widget.recipe.difficultyLevel),
                          ),
                        ),
                      ],
                    ),
                    if (widget.recipe.cost != null) ...[
                      const SizedBox(height: 16),
                      _buildInfoItem(
                        Icons.euro,
                        'Coût',
                        _getCostText(widget.recipe.cost),
                      ),
                    ],
                    if (widget.recipe.restingTime != null) ...[
                      const SizedBox(height: 16),
                      _buildInfoItem(
                        Icons.timer,
                        'Temps de repos',
                        _formatDuration(widget.recipe.restingTime),
                      ),
                    ],
                    const SizedBox(height: 16),
                    _buildInfoItem(
                      Icons.category,
                      'Catégorie',
                      _getCategoryName(widget.recipe.idCategory),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Présentation
            if (widget.recipe.presentationText != null) ...[
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
                        widget.recipe.presentationText!,
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
                        final ingredientName = _getIngredientName(recipeIngredient.idIngredient);
                        final ingredientArticle = _getIngredientArticle(recipeIngredient.idIngredient);
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
                                        text: '${recipeIngredient.quantity} ${recipeIngredient.unit ?? ''} ',
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

            // Tags
            if (widget.recipe.tags.isNotEmpty) ...[
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
                        children: widget.recipe.tags.map((tag) => Container(
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
            if (widget.recipe.internalComment != null) ...[
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
                        widget.recipe.internalComment!,
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
}