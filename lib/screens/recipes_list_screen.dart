import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../services/recipe_service.dart';
import 'recipe_detail_screen.dart';
import 'recipe_form_screen.dart';

class RecipesListScreen extends StatefulWidget {
  const RecipesListScreen({super.key});

  @override
  State<RecipesListScreen> createState() => _RecipesListScreenState();
}

class _RecipesListScreenState extends State<RecipesListScreen> {
  final RecipeService _recipeService = RecipeService();
  final TextEditingController _searchController = TextEditingController();
  
  List<Recipe> _allRecipes = [];
  List<Recipe> _filteredRecipes = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadRecipes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRecipes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final recipes = await _recipeService.getAllRecipes();
      setState(() {
        _allRecipes = recipes;
        _filteredRecipes = recipes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du chargement des recettes: $e';
        _isLoading = false;
      });
    }
  }

  void _filterRecipes(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredRecipes = _allRecipes;
      } else {
        _filteredRecipes = _allRecipes.where((recipe) {
          return recipe.title.toLowerCase().contains(query.toLowerCase()) ||
                 (recipe.subtitle?.toLowerCase().contains(query.toLowerCase()) ?? false) ||
                 recipe.tags.any((tag) => tag.toLowerCase().contains(query.toLowerCase()));
        }).toList();
      }
    });
  }

  void _navigateToRecipeDetail(Recipe recipe) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecipeDetailScreen(recipe: recipe),
      ),
    ).then((_) => _loadRecipes()); // Refresh list when returning
  }

  void _navigateToAddRecipe() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RecipeFormScreen(),
      ),
    ).then((_) => _loadRecipes()); // Refresh list when returning
  }

  void _navigateToEditRecipe(Recipe recipe) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecipeFormScreen(recipe: recipe),
      ),
    ).then((_) => _loadRecipes()); // Refresh list when returning
  }

  String _formatDuration(int? minutes) {
    if (minutes == null || minutes == 0) return '';
    if (minutes < 60) return '${minutes}min';
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (remainingMinutes == 0) return '${hours}h';
    return '${hours}h${remainingMinutes}min';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recettes'),
        actions: [
          IconButton(
            onPressed: _navigateToAddRecipe,
            icon: const Icon(Icons.add),
            tooltip: 'Ajouter une recette',
          ),
        ],
      ),
      body: Column(
        children: [
          // Barre de recherche
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher une recette...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          _filterRecipes('');
                        },
                        icon: const Icon(Icons.clear),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: _filterRecipes,
            ),
          ),
          
          // Message d'erreur
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Card(
                color: Colors.red[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red[700]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red[700]),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          
          // Liste des recettes
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredRecipes.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.restaurant_menu,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchController.text.isNotEmpty
                                  ? 'Aucune recette trouvée'
                                  : 'Aucune recette disponible',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _searchController.text.isNotEmpty
                                  ? 'Essayez avec d\'autres mots-clés'
                                  : 'Commencez par ajouter votre première recette',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadRecipes,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          itemCount: _filteredRecipes.length,
                          itemBuilder: (context, index) {
                            final recipe = _filteredRecipes[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: InkWell(
                                onTap: () => _navigateToRecipeDetail(recipe),
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Titre et actions
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  recipe.title,
                                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                if (recipe.subtitle != null) ...[
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    recipe.subtitle!,
                                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                          PopupMenuButton<String>(
                                            onSelected: (value) {
                                              if (value == 'edit') {
                                                _navigateToEditRecipe(recipe);
                                              } else if (value == 'delete') {
                                                _showDeleteDialog(recipe);
                                              }
                                            },
                                            itemBuilder: (context) => [
                                              const PopupMenuItem(
                                                value: 'edit',
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.edit),
                                                    SizedBox(width: 8),
                                                    Text('Modifier'),
                                                  ],
                                                ),
                                              ),
                                              const PopupMenuItem(
                                                value: 'delete',
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.delete, color: Colors.red),
                                                    SizedBox(width: 8),
                                                    Text('Supprimer', style: TextStyle(color: Colors.red)),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      
                                      // Informations complémentaires
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          if (recipe.preparationTime != null) ...[
                                            Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Prep: ${_formatDuration(recipe.preparationTime)}',
                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                          ],
                                          if (recipe.cookingTime != null) ...[
                                            Icon(Icons.whatshot, size: 16, color: Colors.grey[600]),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Cuisson: ${_formatDuration(recipe.cookingTime)}',
                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                          ],
                                          if (recipe.numberPeople != null) ...[
                                            Icon(Icons.people, size: 16, color: Colors.grey[600]),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${recipe.numberPeople} pers.',
                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      
                                      // Tags
                                      if (recipe.tags.isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 4,
                                          children: recipe.tags.take(3).map((tag) => Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              tag,
                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                color: Theme.of(context).colorScheme.primary,
                                              ),
                                            ),
                                          )).toList(),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(Recipe recipe) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Supprimer la recette'),
          content: Text('Êtes-vous sûr de vouloir supprimer "${recipe.title}" ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () async {
                final navigator = Navigator.of(context);
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                navigator.pop();
                final success = await _recipeService.deleteRecipe(recipe.id);
                if (success) {
                  _loadRecipes();
                  if (mounted) {
                    scaffoldMessenger.showSnackBar(
                      const SnackBar(content: Text('Recette supprimée')),
                    );
                  }
                } else {
                  if (mounted) {
                    scaffoldMessenger.showSnackBar(
                      const SnackBar(
                        content: Text('Erreur lors de la suppression'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );
  }
}