import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/recipe_service.dart';
import '../models/recipe.dart';
import '../models/user.dart';
import 'login_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final AuthService _authService = AuthService();
  final RecipeService _recipeService = RecipeService();
  List<Recipe> _recentRecipes = [];
  bool _isLoading = true;
  User? _currentUser;
  bool _hasShownDebugInfo = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _currentUser = _authService.currentUser;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasShownDebugInfo) {
      _hasShownDebugInfo = true;
      // Delay to ensure Scaffold is ready
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadData();
      });
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    await _loadRecentRecipes();

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadRecentRecipes() async {
    try {
      final recipes = await _recipeService.getRecentRecipes(limit: 10);
      setState(() {
        _recentRecipes = recipes;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du chargement des recettes: $e';
      });
    }
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
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
              onPressed: () {
                Navigator.of(context).pop();
                _logout();
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
        title: const Text('Cookbook'),
        actions: [
          IconButton(
            onPressed: _showLogoutDialog,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  Text(
                    'Dernières recettes ajoutées',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  if (_errorMessage != null) ...[
                    Card(
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
                    const SizedBox(height: 16),
                  ],
                  if (_recentRecipes.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.restaurant_menu,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Aucune recette trouvée',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Commencez par ajouter vos premières recettes',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[500],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    ..._recentRecipes.map((recipe) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(recipe.title),
                            subtitle: recipe.subtitle != null ? Text(recipe.subtitle!) : null,
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () {
                              // Navigate to recipe detail
                            },
                          ),
                        )),
                  const SizedBox(height: 32),
                  Text(
                    'Gestion',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  _buildMenuCard(
                    context,
                    'Gestion des recettes',
                    'Créer, modifier et organiser vos recettes',
                    Icons.restaurant_menu,
                    () {
                      // Navigate to recipes management
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Fonctionnalité en cours de développement')),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildMenuCard(
                    context,
                    'Gestion des ingrédients',
                    'Ajouter et modifier la liste des ingrédients',
                    Icons.inventory_2,
                    () {
                      // Navigate to ingredients management
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Fonctionnalité en cours de développement')),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildMenuCard(
                    context,
                    'Gestion des catégories',
                    'Organiser et modifier les catégories de recettes',
                    Icons.category,
                    () {
                      // Navigate to categories management
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Fonctionnalité en cours de développement')),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}