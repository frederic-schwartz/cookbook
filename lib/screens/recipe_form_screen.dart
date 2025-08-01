import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/recipe.dart';
import '../models/category.dart';
import '../services/recipe_service.dart';
import '../services/auth_service.dart';
import '../services/category_service.dart';

class RecipeFormScreen extends StatefulWidget {
  final Recipe? recipe; // null pour création, recipe pour modification

  const RecipeFormScreen({super.key, this.recipe});

  @override
  State<RecipeFormScreen> createState() => _RecipeFormScreenState();
}

class _RecipeFormScreenState extends State<RecipeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final RecipeService _recipeService = RecipeService();
  final AuthService _authService = AuthService();
  final CategoryService _categoryService = CategoryService();

  // Controllers pour les champs du formulaire
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _subtitleController = TextEditingController();
  final TextEditingController _presentationController = TextEditingController();
  final TextEditingController _preparationTimeController = TextEditingController();
  final TextEditingController _cookingTimeController = TextEditingController();
  final TextEditingController _restingTimeController = TextEditingController();
  final TextEditingController _numberPeopleController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  final TextEditingController _internalCommentController = TextEditingController();

  int? _selectedDifficulty;
  int? _selectedCost;
  int? _selectedCategory;
  bool _isSharedEveryone = false;
  bool _isLoading = false;
  List<Category> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _categoryService.getCategories();
      setState(() {
        _categories = categories;
      });
      
      // Peupler le formulaire après avoir chargé les catégories si on modifie une recette
      if (widget.recipe != null) {
        _populateForm();
      }
    } catch (e) {
      // Gérer l'erreur de chargement des catégories
    }
  }

  List<DropdownMenuItem<int>> _buildCategoryItems() {
    final List<DropdownMenuItem<int>> items = [];
    final Set<int> addedIds = {};
    
    // Ajouter une option vide
    items.add(const DropdownMenuItem<int>(
      value: null,
      child: Text('Aucune catégorie'),
    ));
    
    // Ajouter les catégories parentes
    final parentCategories = _categoryService.getParentCategories(_categories);
    for (final parent in parentCategories) {
      if (!addedIds.contains(parent.id)) {
        items.add(DropdownMenuItem<int>(
          value: parent.id,
          child: Text(parent.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        ));
        addedIds.add(parent.id);
      }
      
      // Ajouter les sous-catégories avec indentation
      final subCategories = _categoryService.getSubCategories(_categories, parent.id);
      for (final sub in subCategories) {
        if (!addedIds.contains(sub.id)) {
          items.add(DropdownMenuItem<int>(
            value: sub.id,
            child: Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: Text('• ${sub.name}'),
            ),
          ));
          addedIds.add(sub.id);
        }
      }
    }
    
    return items;
  }

  void _populateForm() {
    final recipe = widget.recipe!;
    _titleController.text = recipe.title;
    _subtitleController.text = recipe.subtitle ?? '';  
    _presentationController.text = recipe.presentationText ?? '';
    _preparationTimeController.text = recipe.preparationTime?.toString() ?? '';
    _cookingTimeController.text = recipe.cookingTime?.toString() ?? '';
    _restingTimeController.text = recipe.restingTime?.toString() ?? '';
    _numberPeopleController.text = recipe.numberPeople?.toString() ?? '';
    _tagsController.text = recipe.tags.join(', ');
    _internalCommentController.text = recipe.internalComment ?? '';
    _selectedDifficulty = recipe.difficultyLevel;
    _selectedCost = recipe.cost;
    
    // Vérifier si la catégorie existe dans la liste des catégories disponibles
    if (recipe.idCategory != null && 
        _categories.any((category) => category.id == recipe.idCategory)) {
      _selectedCategory = recipe.idCategory;
    } else {
      _selectedCategory = null; // Réinitialiser si la catégorie n'existe pas
    }
    
    _isSharedEveryone = recipe.isSharedEveryone;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _presentationController.dispose();
    _preparationTimeController.dispose();
    _cookingTimeController.dispose();
    _restingTimeController.dispose();
    _numberPeopleController.dispose();
    _tagsController.dispose();
    _internalCommentController.dispose();
    super.dispose();
  }

  Future<void> _saveRecipe() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw Exception('Utilisateur non connecté');
      }
      
      if (currentUser.cookbookId == null) {
        throw Exception('Aucun cookbook associé à votre compte');
      }

      // Préparer les tags
      final tags = _tagsController.text
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();

      final recipe = Recipe(
        id: widget.recipe?.id ?? '', // Sera généré par l'API pour une nouvelle recette
        userCreated: currentUser.id,
        dateCreated: widget.recipe?.dateCreated ?? DateTime.now(),
        userUpdated: widget.recipe != null ? currentUser.id : null,
        dateUpdated: widget.recipe != null ? DateTime.now() : null,
        idCookbook: currentUser.cookbookId!,
        title: _titleController.text.trim(),
        subtitle: _subtitleController.text.trim().isEmpty ? null : _subtitleController.text.trim(),
        preparationTime: _preparationTimeController.text.isEmpty ? null : int.tryParse(_preparationTimeController.text),
        cookingTime: _cookingTimeController.text.isEmpty ? null : int.tryParse(_cookingTimeController.text),
        idCategory: _selectedCategory,
        difficultyLevel: _selectedDifficulty,
        tags: tags,
        cost: _selectedCost,
        presentationText: _presentationController.text.trim().isEmpty ? null : _presentationController.text.trim(),
        numberPeople: _numberPeopleController.text.isEmpty ? null : int.tryParse(_numberPeopleController.text),
        isSharedEveryone: _isSharedEveryone,
        internalComment: _internalCommentController.text.trim().isEmpty ? null : _internalCommentController.text.trim(),
        restingTime: _restingTimeController.text.isEmpty ? null : int.tryParse(_restingTimeController.text),
        photo: widget.recipe?.photo, // TODO: Gérer l'upload de photo
      );

      if (widget.recipe == null) {
        // Création
        await _recipeService.createRecipe(recipe);
      } else {
        // Modification
        await _recipeService.updateRecipe(recipe);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.recipe == null ? 'Recette créée avec succès' : 'Recette modifiée avec succès'),
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
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recipe == null ? 'Nouvelle recette' : 'Modifier la recette'),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _saveRecipe,
              child: const Text('Sauvegarder'),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Titre (obligatoire)
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Titre *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le titre est obligatoire';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Sous-titre
              TextFormField(
                controller: _subtitleController,
                decoration: const InputDecoration(
                  labelText: 'Sous-titre',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Présentation
              TextFormField(
                controller: _presentationController,
                decoration: const InputDecoration(
                  labelText: 'Présentation',
                  border: OutlineInputBorder(),
                  hintText: 'Décrivez votre recette...',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // Section Temps
              Text(
                'Temps de préparation',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _preparationTimeController,
                      decoration: const InputDecoration(
                        labelText: 'Préparation (min)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _cookingTimeController,
                      decoration: const InputDecoration(
                        labelText: 'Cuisson (min)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              TextFormField(
                controller: _restingTimeController,
                decoration: const InputDecoration(
                  labelText: 'Temps de repos (min)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 24),

              // Section Informations
              Text(
                'Informations',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _numberPeopleController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre de personnes',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _selectedDifficulty,
                      decoration: const InputDecoration(
                        labelText: 'Difficulté',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 1, child: Text('Facile')),
                        DropdownMenuItem(value: 2, child: Text('Moyen')),
                        DropdownMenuItem(value: 3, child: Text('Difficile')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedDifficulty = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<int>(
                value: _selectedCost,
                decoration: const InputDecoration(
                  labelText: 'Coût',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 1, child: Text('€ - Économique')),
                  DropdownMenuItem(value: 2, child: Text('€€ - Moyen')),
                  DropdownMenuItem(value: 3, child: Text('€€€ - Cher')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedCost = value;
                  });
                },
              ),
              const SizedBox(height: 12),

              // Catégorie
              DropdownButtonFormField<int>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Catégorie',
                  border: OutlineInputBorder(),
                ),
                items: _buildCategoryItems(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                },
              ),
              const SizedBox(height: 24),

              // Tags
              TextFormField(
                controller: _tagsController,
                decoration: const InputDecoration(
                  labelText: 'Tags',
                  border: OutlineInputBorder(),
                  hintText: 'Séparez les tags par des virgules (ex: dessert, chocolat, facile)',
                ),
              ),
              const SizedBox(height: 24),

              // Options
              Text(
                'Options',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              SwitchListTile(
                title: const Text('Partager avec tout le monde'),
                subtitle: const Text('Rendre cette recette visible par tous les utilisateurs'),
                value: _isSharedEveryone,
                onChanged: (value) {
                  setState(() {
                    _isSharedEveryone = value;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Commentaire interne
              TextFormField(
                controller: _internalCommentController,
                decoration: const InputDecoration(
                  labelText: 'Commentaire interne',
                  border: OutlineInputBorder(),
                  hintText: 'Notes personnelles sur cette recette...',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 32),

              // Bouton de sauvegarde (version mobile)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveRecipe,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(widget.recipe == null ? 'Créer la recette' : 'Sauvegarder les modifications'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}