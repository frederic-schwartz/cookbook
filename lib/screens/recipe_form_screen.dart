import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/recipe.dart';
import '../models/category.dart';
import '../models/step.dart' as recipe_step;
import '../models/ingredient.dart';
import '../services/recipe_service.dart';
import '../services/auth_service.dart';
import '../services/category_service.dart';
import '../services/step_service.dart';
import '../services/ingredient_service.dart';

// Fonction utilitaire pour formater les quantités sans décimales inutiles
String _formatQuantity(String? quantity) {
  if (quantity == null || quantity.isEmpty) return '';
  
  // Essayer de parser comme double
  final double? doubleValue = double.tryParse(quantity);
  if (doubleValue == null) return quantity; // Retourner tel quel si ce n'est pas un nombre
  
  // Si c'est un nombre entier, afficher sans décimales
  if (doubleValue == doubleValue.toInt()) {
    return doubleValue.toInt().toString();
  }
  
  // Sinon, retourner le nombre avec ses décimales mais sans les zéros inutiles
  return doubleValue.toString();
}

// Classe pour gérer les données d'un ingrédient dans le formulaire
class _IngredientFormData {
  Ingredient? ingredient;
  String? recipeIngredientId; // ID de l'ingrédient de recette existant (pour les modifications)
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController unitController = TextEditingController();
  final TextEditingController additionalInfoController = TextEditingController();
  final TextEditingController ingredientController = TextEditingController();
  String? selectedUnit;
  
  _IngredientFormData({this.ingredient, this.recipeIngredientId, String? quantity, String? unit, String? additionalInfo}) {
    quantityController.text = _formatQuantity(quantity);
    unitController.text = unit ?? '';
    additionalInfoController.text = additionalInfo ?? '';
    ingredientController.text = ingredient?.displayName ?? '';
    selectedUnit = unit;
  }
  
  void dispose() {
    quantityController.dispose();
    unitController.dispose();
    additionalInfoController.dispose();
    ingredientController.dispose();
  }
}

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
  final StepService _stepService = StepService();
  final IngredientService _ingredientService = IngredientService();

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
  final List<TextEditingController> _stepControllers = [];
  
  // Variables pour les ingrédients
  List<Ingredient> _availableIngredients = [];
  final List<_IngredientFormData> _ingredientFormData = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final futures = await Future.wait([
        _categoryService.getCategories(),
        _ingredientService.getIngredients(),
      ]);
      
      final categories = futures[0] as List<Category>;
      final ingredients = futures[1] as List<Ingredient>;
      
      setState(() {
        _categories = categories;
        _availableIngredients = ingredients;
      });
      
      // Peupler le formulaire après avoir chargé les données si on modifie une recette
      if (widget.recipe != null) {
        await _loadSteps();
        await _loadRecipeIngredients();
        _populateForm();
      } else {
        // Ajouter une étape vide pour les nouvelles recettes
        _addStep();
        // Ajouter un ingrédient vide pour les nouvelles recettes
        _addIngredient();
      }
    } catch (e) {
      // Gérer l'erreur de chargement des données
    }
  }

  Future<void> _loadSteps() async {
    if (widget.recipe == null) return;
    
    try {
      final steps = await _stepService.getStepsByRecipe(widget.recipe!.id);
      setState(() {
        _stepControllers.clear();
        for (final step in steps) {
          final controller = TextEditingController(text: step.description);
          _stepControllers.add(controller);
        }
      });
    } catch (e) {
      // Gérer l'erreur de chargement des étapes
    }
  }

  Future<void> _loadRecipeIngredients() async {
    if (widget.recipe == null) return;
    
    try {
      final recipeIngredients = await _recipeService.getRecipeIngredients(widget.recipe!.id);
      setState(() {
        _ingredientFormData.clear();
        for (final recipeIngredient in recipeIngredients) {
          Ingredient? ingredient;
          String ingredientDisplayName;
          
          if (recipeIngredient.isCustomIngredient) {
            // Ingrédient personnalisé
            ingredient = null;
            ingredientDisplayName = recipeIngredient.customIngredientName ?? 'Ingrédient personnalisé';
          } else {
            // Ingrédient de la base de données
            ingredient = _availableIngredients.firstWhere(
              (ing) => ing.id == recipeIngredient.idIngredient,
              orElse: () => Ingredient(
                id: recipeIngredient.idIngredient,
                userCreated: '',
                dateCreated: DateTime.now(),
                singularName: 'Ingrédient inconnu',
                article: '',
                units: [],
              ),
            );
            ingredientDisplayName = ingredient.displayName;
          }
          
          final formData = _IngredientFormData(
            ingredient: ingredient,
            recipeIngredientId: recipeIngredient.id,
            quantity: recipeIngredient.quantity,
            unit: recipeIngredient.unit,
            additionalInfo: recipeIngredient.additionalInformation,
          );
          
          // Définir le nom d'affichage dans le contrôleur
          formData.ingredientController.text = ingredientDisplayName;
          
          _ingredientFormData.add(formData);
        }
      });
    } catch (e) {
      // Gérer l'erreur de chargement des ingrédients
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

  void _addStep() {
    setState(() {
      _stepControllers.add(TextEditingController());
    });
  }

  void _removeStep(int index) {
    setState(() {
      if (_stepControllers.length > 1) { // Toujours garder au moins une étape
        _stepControllers[index].dispose();
        _stepControllers.removeAt(index);
      }
    });
  }

  void _moveStepUp(int index) {
    if (index > 0) {
      setState(() {
        final controller = _stepControllers.removeAt(index);
        _stepControllers.insert(index - 1, controller);
      });
    }
  }

  void _moveStepDown(int index) {
    if (index < _stepControllers.length - 1) {
      setState(() {
        final controller = _stepControllers.removeAt(index);
        _stepControllers.insert(index + 1, controller);
      });
    }
  }

  void _addIngredient() {
    setState(() {
      _ingredientFormData.add(_IngredientFormData());
    });
  }

  void _removeIngredient(int index) {
    setState(() {
      if (_ingredientFormData.length > 1) {
        _ingredientFormData[index].dispose();
        _ingredientFormData.removeAt(index);
      }
    });
  }

  void _moveIngredientUp(int index) {
    if (index > 0) {
      setState(() {
        final formData = _ingredientFormData.removeAt(index);
        _ingredientFormData.insert(index - 1, formData);
      });
    }
  }

  void _moveIngredientDown(int index) {
    if (index < _ingredientFormData.length - 1) {
      setState(() {
        final formData = _ingredientFormData.removeAt(index);
        _ingredientFormData.insert(index + 1, formData);
      });
    }
  }

  void _updateUnitsForIngredient(_IngredientFormData formData, Ingredient ingredient) {
    // Réinitialiser l'unité sélectionnée si nouvel ingrédient
    if (ingredient.units.isNotEmpty) {
      // Garder l'ancienne unité si elle existe dans les nouvelles unités disponibles
      if (formData.selectedUnit != null && ingredient.units.contains(formData.selectedUnit!)) {
        // L'unité actuelle est compatible, on la garde
        formData.unitController.text = formData.selectedUnit!;
      } else {
        // Prendre la première unité disponible
        formData.selectedUnit = ingredient.units.first;
        formData.unitController.text = ingredient.units.first;
      }
    } else {
      formData.selectedUnit = null;
      formData.unitController.text = '';
    }
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
    for (final controller in _stepControllers) {
      controller.dispose();
    }
    for (final formData in _ingredientFormData) {
      formData.dispose();
    }
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

      Recipe savedRecipe;
      if (widget.recipe == null) {
        // Création
        savedRecipe = await _recipeService.createRecipe(recipe);
      } else {
        // Modification
        savedRecipe = await _recipeService.updateRecipe(recipe);
      }

      // Sauvegarder les étapes
      await _saveSteps(savedRecipe.id, currentUser);
      
      // Sauvegarder les ingrédients
      await _saveIngredients(savedRecipe.id, currentUser);

      if (mounted) {
        Navigator.of(context).pop(true); // Retourner true pour indiquer une sauvegarde réussie
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

  Future<void> _saveSteps(String recipeId, currentUser) async {
    // Supprimer les anciennes étapes en cas de modification
    if (widget.recipe != null) {
      await _stepService.deleteAllStepsForRecipe(recipeId);
    }

    // Créer les nouvelles étapes
    for (int i = 0; i < _stepControllers.length; i++) {
      final description = _stepControllers[i].text.trim();
      if (description.isNotEmpty) {
        final step = recipe_step.Step(
          id: '', // Sera généré par l'API
          userCreated: currentUser.id,
          dateCreated: DateTime.now(),
          idCookbook: currentUser.cookbookId!,
          idRecipe: recipeId,
          description: description,
          order: i + 1,
        );
        await _stepService.createStep(step);
      }
    }
  }

  Future<void> _saveIngredients(String recipeId, currentUser) async {

    // Récupérer la liste des ingrédients existants pour les modifications
    List<RecipeIngredient> existingIngredients = [];
    if (widget.recipe != null) {
      existingIngredients = await _recipeService.getRecipeIngredients(recipeId);
    }

    // Créer une liste des IDs d'ingrédients de recette qui seront conservés
    final Set<String> preservedIds = {};

    // Traiter chaque ingrédient du formulaire
    for (int i = 0; i < _ingredientFormData.length; i++) {
      final formData = _ingredientFormData[i];
      final quantity = formData.quantityController.text.trim();
      final ingredientName = formData.ingredientController.text.trim();
      
      
      if (quantity.isNotEmpty && ingredientName.isNotEmpty) {
        final unit = formData.selectedUnit ?? formData.unitController.text.trim();
        final additionalInfo = formData.additionalInfoController.text.trim().isEmpty 
            ? null 
            : formData.additionalInfoController.text.trim();


        // Déterminer si c'est un ingrédient personnalisé ou de la base
        final bool isCustom = formData.ingredient == null;
        final String idIngredient = isCustom ? '' : formData.ingredient!.id;
        final String? article = isCustom ? null : formData.ingredient!.article;
        

        if (formData.recipeIngredientId != null) {
          // Mettre à jour un ingrédient existant
          final recipeIngredient = RecipeIngredient(
            id: formData.recipeIngredientId!,
            userCreated: currentUser.id,
            dateCreated: DateTime.now(),
            userUpdated: currentUser.id,
            dateUpdated: DateTime.now(),
            idIngredient: idIngredient,
            quantity: quantity,
            unit: unit.isEmpty ? null : unit,
            article: article,
            idRecipe: recipeId,
            idCookbook: currentUser.cookbookId!,
            additionalInformation: additionalInfo,
            isCustomIngredient: isCustom,
            customIngredientName: isCustom ? ingredientName : null,
          );
          await _recipeService.updateRecipeIngredient(recipeIngredient);
          preservedIds.add(formData.recipeIngredientId!);
        } else {
          // Créer un nouvel ingrédient
          final recipeIngredient = RecipeIngredient(
            id: '', // Sera généré par l'API
            userCreated: currentUser.id,
            dateCreated: DateTime.now(),
            idIngredient: idIngredient,
            quantity: quantity,
            unit: unit.isEmpty ? null : unit,
            article: article,
            idRecipe: recipeId,
            idCookbook: currentUser.cookbookId!,
            additionalInformation: additionalInfo,
            isCustomIngredient: isCustom,
            customIngredientName: isCustom ? ingredientName : null,
          );
          final createdIngredient = await _recipeService.addRecipeIngredient(recipeIngredient);
          if (createdIngredient != null) {
            // Mettre à jour l'ID pour les futures modifications
            formData.recipeIngredientId = createdIngredient.id;
            preservedIds.add(createdIngredient.id);
          }
        }
      }
    }

    // Supprimer les ingrédients qui ne sont plus dans le formulaire
    for (final existing in existingIngredients) {
      if (!preservedIds.contains(existing.id)) {
        await _recipeService.deleteRecipeIngredient(existing.id);
      }
    }
  }

  List<Widget> _buildStepsSection() {
    List<Widget> stepWidgets = [];
    
    for (int i = 0; i < _stepControllers.length; i++) {
      stepWidgets.add(
        Card(
          margin: const EdgeInsets.only(bottom: 8.0),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Numéro de l'étape
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Champ de description
                Expanded(
                  child: TextFormField(
                    controller: _stepControllers[i],
                    decoration: const InputDecoration(
                      labelText: 'Description de l\'étape',
                      border: OutlineInputBorder(),
                      hintText: 'Décrivez cette étape...',
                    ),
                    maxLines: 2,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'La description de l\'étape est obligatoire';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                
                // Boutons d'action
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Bouton monter
                    IconButton(
                      onPressed: i > 0 ? () => _moveStepUp(i) : null,
                      icon: const Icon(Icons.keyboard_arrow_up),
                      iconSize: 20,
                    ),
                    // Bouton descendre
                    IconButton(
                      onPressed: i < _stepControllers.length - 1 ? () => _moveStepDown(i) : null,
                      icon: const Icon(Icons.keyboard_arrow_down),
                      iconSize: 20,
                    ),
                    // Bouton supprimer
                    IconButton(
                      onPressed: _stepControllers.length > 1 ? () => _removeStep(i) : null,
                      icon: const Icon(Icons.delete, color: Colors.red),
                      iconSize: 20,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    // Bouton pour ajouter une étape
    stepWidgets.add(
      Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: OutlinedButton.icon(
          onPressed: _addStep,
          icon: const Icon(Icons.add),
          label: const Text('Ajouter une étape'),
        ),
      ),
    );
    
    return stepWidgets;
  }

  List<Widget> _buildIngredientsSection() {
    List<Widget> ingredientWidgets = [];
    
    for (int i = 0; i < _ingredientFormData.length; i++) {
      final formData = _ingredientFormData[i];
      
      ingredientWidgets.add(
        Card(
          margin: const EdgeInsets.only(bottom: 8.0),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Numéro de l'ingrédient
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${i + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Sélection de l'ingrédient avec autocomplétion
                    Expanded(
                      flex: 3,
                      child: Autocomplete<Ingredient>(
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          if (textEditingValue.text == '') {
                            return _availableIngredients;
                          }
                          return _availableIngredients.where((Ingredient ingredient) {
                            return ingredient.displayName
                                .toLowerCase()
                                .contains(textEditingValue.text.toLowerCase());
                          });
                        },
                        displayStringForOption: (Ingredient ingredient) => ingredient.displayName,
                        fieldViewBuilder: (BuildContext context, TextEditingController textEditingController, FocusNode focusNode, VoidCallback onFieldSubmitted) {
                          // Synchroniser avec notre contrôleur
                          if (textEditingController.text != formData.ingredientController.text) {
                            textEditingController.text = formData.ingredientController.text;
                          }
                          
                          return TextFormField(
                            controller: textEditingController,
                            focusNode: focusNode,
                            decoration: InputDecoration(
                              labelText: 'Ingrédient',
                              border: const OutlineInputBorder(),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              hintText: 'Tapez pour rechercher...',
                              suffixIcon: formData.ingredient == null && formData.ingredientController.text.isNotEmpty
                                  ? const Icon(Icons.add_circle, color: Colors.green)
                                  : null,
                              helperText: formData.ingredient == null && formData.ingredientController.text.isNotEmpty
                                  ? 'Nouvel ingrédient personnalisé'
                                  : null,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Saisissez un ingrédient';
                              }
                              return null;
                            },
                            onChanged: (value) {
                              formData.ingredientController.text = value;
                              // Rechercher l'ingrédient correspondant
                              final matchingIngredient = _availableIngredients.firstWhere(
                                (ingredient) => ingredient.displayName.toLowerCase() == value.toLowerCase(),
                                orElse: () => Ingredient(
                                  id: '',
                                  userCreated: '',
                                  dateCreated: DateTime.now(),
                                  singularName: '',
                                  article: '',
                                  units: [],
                                ),
                              );
                              setState(() {
                                if (matchingIngredient.id.isNotEmpty) {
                                  // Ingrédient trouvé dans la liste
                                  formData.ingredient = matchingIngredient;
                                  _updateUnitsForIngredient(formData, matchingIngredient);
                                } else {
                                  // Ingrédient personnalisé (pas dans la liste)
                                  formData.ingredient = null;
                                  formData.selectedUnit = null;
                                  formData.unitController.text = '';
                                }
                              });
                            },
                          );
                        },
                        onSelected: (Ingredient ingredient) {
                          setState(() {
                            formData.ingredient = ingredient;
                            formData.ingredientController.text = ingredient.displayName;
                            _updateUnitsForIngredient(formData, ingredient);
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    
                    // Boutons d'action
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Bouton monter
                        IconButton(
                          onPressed: i > 0 ? () => _moveIngredientUp(i) : null,
                          icon: const Icon(Icons.keyboard_arrow_up),
                          iconSize: 20,
                        ),
                        // Bouton descendre
                        IconButton(
                          onPressed: i < _ingredientFormData.length - 1 ? () => _moveIngredientDown(i) : null,
                          icon: const Icon(Icons.keyboard_arrow_down),
                          iconSize: 20,
                        ),
                        // Bouton supprimer
                        IconButton(
                          onPressed: _ingredientFormData.length > 1 ? () => _removeIngredient(i) : null,
                          icon: const Icon(Icons.delete, color: Colors.red),
                          iconSize: 20,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Quantité et unité
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: formData.quantityController,
                        decoration: const InputDecoration(
                          labelText: 'Quantité',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Quantité obligatoire';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    
                    Expanded(
                      flex: 2,
                      child: formData.ingredient != null && formData.ingredient!.units.isNotEmpty
                          ? DropdownButtonFormField<String>(
                              value: formData.selectedUnit != null && formData.ingredient!.units.contains(formData.selectedUnit!) 
                                  ? formData.selectedUnit 
                                  : null,
                              decoration: const InputDecoration(
                                labelText: 'Unité',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              items: [
                                // Option vide pour permettre de ne pas sélectionner d'unité
                                const DropdownMenuItem<String>(
                                  value: null,
                                  child: Text('(aucune unité)', style: TextStyle(fontStyle: FontStyle.italic)),
                                ),
                                // Units disponibles pour cet ingrédient
                                ...formData.ingredient!.units.map((unit) {
                                  return DropdownMenuItem<String>(
                                    value: unit,
                                    child: Text(unit),
                                  );
                                }),
                              ],
                              onChanged: (unit) {
                                setState(() {
                                  formData.selectedUnit = unit;
                                  formData.unitController.text = unit ?? '';
                                });
                              },
                            )
                          : TextFormField(
                              controller: formData.unitController,
                              decoration: const InputDecoration(
                                labelText: 'Unité (personnalisée)',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                hintText: 'Ex: pincée, au goût...',
                              ),
                            ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Informations additionnelles
                TextFormField(
                  controller: formData.additionalInfoController,
                  decoration: const InputDecoration(
                    labelText: 'Informations additionnelles (optionnel)',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    hintText: 'Ex: coupés en dés, épluché...',
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    // Bouton pour ajouter un ingrédient
    ingredientWidgets.add(
      Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: OutlinedButton.icon(
          onPressed: _addIngredient,
          icon: const Icon(Icons.add),
          label: const Text('Ajouter un ingrédient'),
        ),
      ),
    );
    
    return ingredientWidgets;
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

              // Ingrédients
              Text(
                'Ingrédients',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              
              ..._buildIngredientsSection(),
              
              const SizedBox(height: 24),

              // Étapes
              Text(
                'Étapes de préparation',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              
              ..._buildStepsSection(),
              
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