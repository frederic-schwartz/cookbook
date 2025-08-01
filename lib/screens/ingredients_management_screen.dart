import 'package:flutter/material.dart';
import '../models/ingredient.dart';
import '../services/ingredient_service.dart';

class IngredientsManagementScreen extends StatefulWidget {
  const IngredientsManagementScreen({super.key});

  @override
  State<IngredientsManagementScreen> createState() => _IngredientsManagementScreenState();
}

class _IngredientsManagementScreenState extends State<IngredientsManagementScreen> {
  final IngredientService _ingredientService = IngredientService();
  final TextEditingController _searchController = TextEditingController();
  
  List<Ingredient> _allIngredients = [];
  List<Ingredient> _filteredIngredients = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadIngredients();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadIngredients() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final ingredients = await _ingredientService.getIngredients();
      setState(() {
        _allIngredients = ingredients;
        _filteredIngredients = ingredients;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du chargement des ingrédients: $e';
        _isLoading = false;
      });
    }
  }

  void _filterIngredients(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredIngredients = _allIngredients;
      } else {
        _filteredIngredients = _allIngredients.where((ingredient) {
          return ingredient.singularName.toLowerCase().contains(query.toLowerCase()) ||
                 (ingredient.pluralName?.toLowerCase().contains(query.toLowerCase()) ?? false);
        }).toList();
      }
    });
  }

  void _showAddIngredientDialog() {
    _showIngredientDialog();
  }

  void _showEditIngredientDialog(Ingredient ingredient) {
    _showIngredientDialog(ingredient: ingredient);
  }

  void _showIngredientDialog({Ingredient? ingredient}) {
    final isEditing = ingredient != null;
    final singularNameController = TextEditingController(text: ingredient?.singularName ?? '');
    final pluralNameController = TextEditingController(text: ingredient?.pluralName ?? '');
    final articleController = TextEditingController(text: ingredient?.article ?? '');
    final unitsController = TextEditingController(text: ingredient?.units.join(', ') ?? '');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(isEditing ? 'Modifier l\'ingrédient' : 'Nouvel ingrédient'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: singularNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nom singulier *',
                    border: OutlineInputBorder(),
                    hintText: 'Ex: oignon, tomate, carotte...',
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: pluralNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nom pluriel',
                    border: OutlineInputBorder(),
                    hintText: 'Ex: oignons, tomates, carottes...',
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: articleController,
                  decoration: const InputDecoration(
                    labelText: 'Article *',
                    border: OutlineInputBorder(),
                    hintText: "Ex: d', de, du...",
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: unitsController,
                  decoration: const InputDecoration(
                    labelText: 'Unités (séparées par des virgules)',
                    border: OutlineInputBorder(),
                    hintText: 'Ex: , g, kg ou gousse, tête, g',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                final singularName = singularNameController.text.trim();
                final article = articleController.text.trim();
                if (singularName.isEmpty || article.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Le nom singulier et l\'article sont obligatoires'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                final units = unitsController.text.trim().split(',').map((u) => u.trim()).where((u) => u.isNotEmpty).toList();
                if (units.isEmpty) {
                  units.add(''); // Au moins une unité vide par défaut
                }

                final navigator = Navigator.of(context);
                final scaffoldMessenger = ScaffoldMessenger.of(context);

                try {
                  if (isEditing) {
                    final updatedIngredient = Ingredient(
                      id: ingredient.id,
                      userCreated: ingredient.userCreated,
                      dateCreated: ingredient.dateCreated,
                      userUpdated: ingredient.userUpdated,
                      dateUpdated: DateTime.now(),
                      singularName: singularName,
                      pluralName: pluralNameController.text.trim().isEmpty ? null : pluralNameController.text.trim(),
                      article: article,
                      units: units,
                    );
                    await _ingredientService.updateIngredient(updatedIngredient);
                  } else {
                    final newIngredient = Ingredient(
                      id: '', // Directus génère l'ID
                      userCreated: '',
                      dateCreated: DateTime.now(),
                      singularName: singularName,
                      pluralName: pluralNameController.text.trim().isEmpty ? null : pluralNameController.text.trim(),
                      article: article,
                      units: units,
                    );
                    await _ingredientService.createIngredient(newIngredient);
                  }

                  navigator.pop();
                  _loadIngredients();
                  
                  if (mounted) {
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text(isEditing ? 'Ingrédient modifié' : 'Ingrédient ajouté'),
                      ),
                    );
                  }
                } catch (e) {
                  navigator.pop();
                  
                  if (mounted) {
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text('Erreur: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: Text(isEditing ? 'Modifier' : 'Ajouter'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteDialog(Ingredient ingredient) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Supprimer l\'ingrédient'),
          content: Text('Êtes-vous sûr de vouloir supprimer "${ingredient.singularName}" ?'),
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
                
                try {
                  await _ingredientService.deleteIngredient(ingredient.id);
                  _loadIngredients();
                  if (mounted) {
                    scaffoldMessenger.showSnackBar(
                      const SnackBar(content: Text('Ingrédient supprimé')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text('Erreur lors de la suppression: $e'),
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

  // Fonction de rechargement supprimée - les ingrédients sont maintenant gérés dans Directus

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des ingrédients'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'add') {
                _showAddIngredientDialog();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'add',
                child: Row(
                  children: [
                    Icon(Icons.add),
                    SizedBox(width: 8),
                    Text('Ajouter un ingrédient'),
                  ],
                ),
              ),
            ],
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
                hintText: 'Rechercher un ingrédient...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          _filterIngredients('');
                        },
                        icon: const Icon(Icons.clear),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: _filterIngredients,
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

          // Statistiques
          if (!_isLoading) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Card(
                color: Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[700]),
                      const SizedBox(width: 12),
                      Text(
                        '${_allIngredients.length} ingrédients au total',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (_searchController.text.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Text(
                          '(${_filteredIngredients.length} affichés)',
                          style: TextStyle(color: Colors.blue[600]),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Liste des ingrédients
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredIngredients.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inventory_2,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchController.text.isNotEmpty
                                  ? 'Aucun ingrédient trouvé'
                                  : 'Aucun ingrédient disponible',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _searchController.text.isNotEmpty
                                  ? 'Essayez avec d\'autres mots-clés'
                                  : 'Commencez par ajouter votre premier ingrédient',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadIngredients,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          itemCount: _filteredIngredients.length,
                          itemBuilder: (context, index) {
                            final ingredient = _filteredIngredients[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary.withAlpha(25),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.inventory_2,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                                title: Text(
                                  ingredient.singularName,
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (ingredient.pluralName?.isNotEmpty == true) ...[
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(Icons.text_fields, size: 14, color: Colors.grey[600]),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Pluriel: ${ingredient.pluralName}',
                                            style: TextStyle(color: Colors.grey[600]),
                                          ),
                                        ],
                                      ),
                                    ],
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Icon(Icons.format_quote, size: 14, color: Colors.grey[600]),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Article: ${ingredient.article}',
                                          style: TextStyle(color: Colors.grey[600]),
                                        ),
                                      ],
                                    ),
                                    if (ingredient.units.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Icon(Icons.straighten, size: 14, color: Colors.grey[600]),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              'Unités: ${ingredient.units.where((u) => u.isNotEmpty).join(", ")}',
                                              style: TextStyle(color: Colors.grey[600]),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                                trailing: PopupMenuButton<String>(
                                  onSelected: (value) {
                                    if (value == 'edit') {
                                      _showEditIngredientDialog(ingredient);
                                    } else if (value == 'delete') {
                                      _showDeleteDialog(ingredient);
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
}