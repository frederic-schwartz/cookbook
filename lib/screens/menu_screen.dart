import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/recipe_service.dart';
import '../services/category_service.dart';
import '../models/recipe.dart';
import '../models/category.dart';
import 'login_screen.dart';
import 'recipe_detail_screen.dart';
import 'recipe_form_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final AuthService _authService = AuthService();
  final RecipeService _recipeService = RecipeService();
  final CategoryService _categoryService = CategoryService();
  final TextEditingController _searchController = TextEditingController();
  
  List<Recipe> _allRecipes = [];
  List<Recipe> _filteredRecipes = [];
  List<Category> _categories = [];
  bool _isLoading = true;
  String? _errorMessage;
  int? _selectedCategoryFilter;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final futures = await Future.wait([
        _recipeService.getAllRecipes(),
        _categoryService.getCategories(),
      ]);

      final recipes = futures[0] as List<Recipe>;
      final categories = futures[1] as List<Category>;

      setState(() {
        _allRecipes = recipes;
        _filteredRecipes = recipes;
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du chargement des données: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadRecipes() async {
    try {
      final recipes = await _recipeService.getAllRecipes();
      setState(() {
        _allRecipes = recipes;
        _applyFilters();
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du chargement des recettes: $e';
      });
    }
  }

  String _normalizeString(String input) {
    // Normaliser la chaîne en supprimant les accents
    return input
        .toLowerCase()
        .replaceAll('à', 'a')
        .replaceAll('á', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ã', 'a')
        .replaceAll('ä', 'a')
        .replaceAll('å', 'a')
        .replaceAll('æ', 'ae')
        .replaceAll('ç', 'c')
        .replaceAll('è', 'e')
        .replaceAll('é', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('ë', 'e')
        .replaceAll('ì', 'i')
        .replaceAll('í', 'i')
        .replaceAll('î', 'i')
        .replaceAll('ï', 'i')
        .replaceAll('ñ', 'n')
        .replaceAll('ò', 'o')
        .replaceAll('ó', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('õ', 'o')
        .replaceAll('ö', 'o')
        .replaceAll('ø', 'o')
        .replaceAll('œ', 'oe')
        .replaceAll('ù', 'u')
        .replaceAll('ú', 'u')
        .replaceAll('û', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('ý', 'y')
        .replaceAll('ÿ', 'y');
  }

  void _filterRecipes(String query) {
    setState(() {
      _applyFilters();
    });
  }

  void _applyFilters() {
    List<Recipe> filtered = _allRecipes;

    // Filtre par catégorie
    if (_selectedCategoryFilter != null) {
      filtered = filtered.where((recipe) => recipe.idCategory == _selectedCategoryFilter).toList();
    }

    // Filtre par recherche textuelle (insensible aux accents)
    final query = _searchController.text;
    if (query.isNotEmpty) {
      final normalizedQuery = _normalizeString(query);
      filtered = filtered.where((recipe) {
        final normalizedTitle = _normalizeString(recipe.title);
        final normalizedSubtitle = recipe.subtitle != null ? _normalizeString(recipe.subtitle!) : '';
        final normalizedTags = recipe.tags.map((tag) => _normalizeString(tag)).toList();
        
        return normalizedTitle.contains(normalizedQuery) ||
               normalizedSubtitle.contains(normalizedQuery) ||
               normalizedTags.any((tag) => tag.contains(normalizedQuery));
      }).toList();
    }

    _filteredRecipes = filtered;
  }

  Widget _buildCategoryFilter() {
    if (_categories.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      child: DropdownButtonFormField<int>(
        value: _selectedCategoryFilter,
        decoration: InputDecoration(
          labelText: 'Filtrer par catégorie',
          prefixIcon: const Icon(Icons.category),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        items: [
          const DropdownMenuItem<int>(
            value: null,
            child: Text('Toutes les catégories'),
          ),
          ..._buildCategoryItems(),
        ],
        onChanged: (value) {
          setState(() {
            _selectedCategoryFilter = value;
            _applyFilters();
          });
        },
      ),
    );
  }

  List<DropdownMenuItem<int>> _buildCategoryItems() {
    final List<DropdownMenuItem<int>> items = [];
    
    // Ajouter les catégories parentes
    final parentCategories = _categoryService.getParentCategories(_categories);
    for (final parent in parentCategories) {
      items.add(DropdownMenuItem<int>(
        value: parent.id,
        child: Text(parent.name, style: const TextStyle(fontWeight: FontWeight.bold)),
      ));
      
      // Ajouter les sous-catégories avec indentation
      final subCategories = _categoryService.getSubCategories(_categories, parent.id);
      for (final sub in subCategories) {
        items.add(DropdownMenuItem<int>(
          value: sub.id,
          child: Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Text('• ${sub.name}'),
          ),
        ));
      }
    }
    
    return items;
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

  String _formatDuration(int? minutes) {
    if (minutes == null || minutes == 0) return '';
    if (minutes < 60) return '${minutes}min';
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (remainingMinutes == 0) return '${hours}h';
    return '${hours}h${remainingMinutes}min';
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Déconnexion'),
          content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _authService.logout();
                if (mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                  );
                }
              },
              child: const Text('Déconnexion'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Recettes'),
        actions: [
          IconButton(
            onPressed: _navigateToAddRecipe,
            icon: const Icon(Icons.add),
            tooltip: 'Ajouter une recette',
          ),
          IconButton(
            onPressed: _showLogoutDialog,
            icon: const Icon(Icons.logout),
            tooltip: 'Déconnexion',
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
          
          // Filtre par catégorie
          const SizedBox(height: 8),
          _buildCategoryFilter(),
          const SizedBox(height: 16),
          
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
                                        ],
                                      ),
                                      
                                      // Métadonnées (temps, difficulté, etc.)
                                      const SizedBox(height: 12),
                                      Wrap(
                                        spacing: 12,
                                        runSpacing: 8,
                                        children: [
                                          if (recipe.preparationTime != null || recipe.cookingTime != null)
                                            _buildInfoChip(
                                              Icons.timer,
                                              '${_formatDuration(recipe.preparationTime)} ${_formatDuration(recipe.cookingTime)}'.trim(),
                                            ),
                                          if (recipe.difficultyLevel != null)
                                            _buildInfoChip(
                                              Icons.trending_up,
                                              'Niveau ${recipe.difficultyLevel}',
                                            ),
                                          if (recipe.numberPeople != null)
                                            _buildInfoChip(
                                              Icons.people,
                                              '${recipe.numberPeople} pers.',
                                            ),
                                        ],
                                      ),
                                      
                                      // Tags
                                      if (recipe.tags.isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 4,
                                          children: recipe.tags.take(3).map((tag) => 
                                            Chip(
                                              label: Text(
                                                tag,
                                                style: Theme.of(context).textTheme.bodySmall,
                                              ),
                                              backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                              side: BorderSide.none,
                                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                              visualDensity: VisualDensity.compact,
                                            )
                                          ).toList(),
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

  Widget _buildInfoChip(IconData icon, String text) {
    if (text.isEmpty) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[700]),
          const SizedBox(width: 4),
          Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}