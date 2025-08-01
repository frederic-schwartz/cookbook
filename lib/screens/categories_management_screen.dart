import 'package:flutter/material.dart';
import '../models/category.dart';
import '../services/database_service.dart';

class CategoriesManagementScreen extends StatefulWidget {
  const CategoriesManagementScreen({super.key});

  @override
  State<CategoriesManagementScreen> createState() => _CategoriesManagementScreenState();
}

class _CategoriesManagementScreenState extends State<CategoriesManagementScreen> {
  final DatabaseService _databaseService = DatabaseService();
  
  List<Category> _allCategories = [];
  List<Category> _mainCategories = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final allCategories = await _databaseService.getCategories();
      final mainCategories = await _databaseService.getMainCategories();
      
      setState(() {
        _allCategories = allCategories;
        _mainCategories = mainCategories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du chargement des catégories: $e';
        _isLoading = false;
      });
    }
  }

  Future<List<Category>> _getSubcategories(int parentId) async {
    return await _databaseService.getSubcategories(parentId);
  }

  void _showAddCategoryDialog({Category? parentCategory}) {
    _showCategoryDialog(parentCategory: parentCategory);
  }

  void _showEditCategoryDialog(Category category) {
    _showCategoryDialog(category: category);
  }

  void _showCategoryDialog({Category? category, Category? parentCategory}) {
    final isEditing = category != null;
    final nameController = TextEditingController(text: category?.name ?? '');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            isEditing
                ? 'Modifier la catégorie'
                : parentCategory != null
                    ? 'Nouvelle sous-catégorie'
                    : 'Nouvelle catégorie principale'
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (parentCategory != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.category, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Sous-catégorie de: ${parentCategory.name}',
                            style: TextStyle(
                              color: Colors.blue[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nom *',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.words,
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
                final name = nameController.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Le nom est obligatoire'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                try {
                  if (isEditing) {
                    final updatedCategory = Category(
                      id: category!.id,
                      name: name,
                      parentId: category.parentId,
                    );
                    await _databaseService.updateCategory(updatedCategory);
                  } else {
                    // Pour une nouvelle catégorie, on trouve le prochain ID disponible
                    final maxId = _allCategories.isEmpty ? 0 : _allCategories.map((e) => e.id).reduce((a, b) => a > b ? a : b);
                    final newCategory = Category(
                      id: maxId + 1,
                      name: name,
                      parentId: parentCategory?.id,
                    );
                    await _databaseService.insertCategory(newCategory);
                  }

                  Navigator.of(context).pop();
                  _loadCategories();
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isEditing ? 'Catégorie modifiée' : 'Catégorie ajoutée'),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
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

  void _showDeleteDialog(Category category) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Supprimer la catégorie'),
          content: Text('Êtes-vous sûr de vouloir supprimer "${category.name}" ?\n\nCela supprimera aussi toutes ses sous-catégories.'),
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
                  await _databaseService.deleteCategory(category.id);
                  _loadCategories();
                  if (mounted) {
                    scaffoldMessenger.showSnackBar(
                      const SnackBar(content: Text('Catégorie supprimée')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des catégories'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'add_main') {
                _showAddCategoryDialog();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'add_main',
                child: Row(
                  children: [
                    Icon(Icons.add),
                    SizedBox(width: 8),
                    Text('Nouvelle catégorie principale'),
                  ],
                ),
              ),
            ],
            child: const Icon(Icons.add),
          ),
        ],
      ),
      body: Column(
        children: [
          // Message d'erreur
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
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
              padding: const EdgeInsets.all(16.0),
              child: Card(
                color: Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[700]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${_mainCategories.length} catégories principales, ${_allCategories.length - _mainCategories.length} sous-catégories',
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],

          // Liste des catégories
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _mainCategories.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.category,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Aucune catégorie disponible',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Commencez par ajouter votre première catégorie',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadCategories,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          itemCount: _mainCategories.length,
                          itemBuilder: (context, index) {
                            final mainCategory = _mainCategories[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Theme(
                                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                                child: ExpansionTile(
                                  leading: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primary.withAlpha(25),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.category,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                  title: Text(
                                    mainCategory.name,
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      PopupMenuButton<String>(
                                        onSelected: (value) {
                                          if (value == 'add_sub') {
                                            _showAddCategoryDialog(parentCategory: mainCategory);
                                          } else if (value == 'edit') {
                                            _showEditCategoryDialog(mainCategory);
                                          } else if (value == 'delete') {
                                            _showDeleteDialog(mainCategory);
                                          }
                                        },
                                        itemBuilder: (context) => [
                                          const PopupMenuItem(
                                            value: 'add_sub',
                                            child: Row(
                                              children: [
                                                Icon(Icons.add),
                                                SizedBox(width: 8),
                                                Text('Ajouter sous-catégorie'),
                                              ],
                                            ),
                                          ),
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
                                      const Icon(Icons.expand_more),
                                    ],
                                  ),
                                  children: [
                                    FutureBuilder<List<Category>>(
                                      future: _getSubcategories(mainCategory.id),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState == ConnectionState.waiting) {
                                          return const Padding(
                                            padding: EdgeInsets.all(16.0),
                                            child: Center(child: CircularProgressIndicator()),
                                          );
                                        }

                                        final subcategories = snapshot.data ?? [];
                                        if (subcategories.isEmpty) {
                                          return Padding(
                                            padding: const EdgeInsets.all(16.0),
                                            child: Text(
                                              'Aucune sous-catégorie',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                          );
                                        }

                                        return Column(
                                          children: subcategories.map((subcategory) {
                                            return ListTile(
                                              leading: const SizedBox(
                                                width: 40,
                                                child: Icon(Icons.subdirectory_arrow_right, color: Colors.grey),
                                              ),
                                              title: Text(subcategory.name),
                                              trailing: PopupMenuButton<String>(
                                                onSelected: (value) {
                                                  if (value == 'edit') {
                                                    _showEditCategoryDialog(subcategory);
                                                  } else if (value == 'delete') {
                                                    _showDeleteDialog(subcategory);
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
                                            );
                                          }).toList(),
                                        );
                                      },
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