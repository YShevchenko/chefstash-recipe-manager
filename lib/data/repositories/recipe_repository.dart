import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/database/database_helper.dart';
import '../../domain/models/recipe.dart';

/// Repository for recipe CRUD operations
/// Wraps DatabaseHelper with domain-model conversions and image downloading
class RecipeRepository {
  static final RecipeRepository instance = RecipeRepository._();
  RecipeRepository._();

  final _uuid = const Uuid();

  /// Insert a new recipe, downloading the image if [imageUrl] is provided.
  Future<String> addRecipe({
    required String title,
    required List<String> ingredients,
    required List<String> instructions,
    String? imageUrl,
    String? sourceUrl,
    String? yield_,
    String? prepTime,
    String? cookTime,
    List<String> tags = const [],
  }) async {
    // Download image if URL provided
    String? localImagePath;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      localImagePath = await _downloadImage(imageUrl);
    }

    final recipeMap = {
      'title': title,
      'url': sourceUrl,
      'image': localImagePath,
      'ingredients': jsonEncode(ingredients),
      'instructions': jsonEncode(instructions),
      'yield': yield_,
      'prepTime': prepTime,
      'cookTime': cookTime,
    };

    final id = await DatabaseHelper.instance.insertRecipe(recipeMap);

    // Add tags
    for (final tag in tags) {
      await DatabaseHelper.instance.addTagToRecipe(id, tag);
    }

    return id;
  }

  /// Download image from URL and save to documents directory
  Future<String?> _downloadImage(String imageUrl) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode != 200) return null;

      final dir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${dir.path}/recipes/images');
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      final filename = '${_uuid.v4()}.jpg';
      final file = File('${imagesDir.path}/$filename');
      await file.writeAsBytes(response.bodyBytes);

      return file.path;
    } catch (e) {
      debugPrint('Error downloading image: $e');
      return null;
    }
  }

  /// Get all recipes with their tags
  Future<List<Recipe>> getAllRecipes() async {
    final maps = await DatabaseHelper.instance.getAllRecipes();
    final recipes = <Recipe>[];

    for (final map in maps) {
      final tags = await DatabaseHelper.instance.getRecipeTags(map['id'] as String);
      recipes.add(Recipe.fromMap(map, tags: tags));
    }

    return recipes;
  }

  /// Get a single recipe by ID
  Future<Recipe?> getRecipe(String id) async {
    final map = await DatabaseHelper.instance.getRecipe(id);
    if (map == null) return null;
    final tags = await DatabaseHelper.instance.getRecipeTags(id);
    return Recipe.fromMap(map, tags: tags);
  }

  /// Search recipes by title or ingredient
  Future<List<Recipe>> searchRecipes(String query) async {
    final maps = await DatabaseHelper.instance.searchRecipes(query);
    final recipes = <Recipe>[];
    for (final map in maps) {
      final tags = await DatabaseHelper.instance.getRecipeTags(map['id'] as String);
      recipes.add(Recipe.fromMap(map, tags: tags));
    }
    return recipes;
  }

  /// Update an existing recipe
  Future<void> updateRecipe(Recipe recipe) async {
    await DatabaseHelper.instance.updateRecipe(recipe.id, {
      'title': recipe.title,
      'url': recipe.sourceUrl,
      'image_path': recipe.imageLocalPath,
      'ingredients': jsonEncode(recipe.ingredients),
      'instructions': jsonEncode(recipe.instructions),
      'yield': recipe.yield_,
      'prep_time': recipe.prepTime,
      'cook_time': recipe.cookTime,
    });
  }

  /// Delete a recipe and its local image
  Future<void> deleteRecipe(String id) async {
    final recipe = await getRecipe(id);
    if (recipe?.imageLocalPath != null) {
      final file = File(recipe!.imageLocalPath!);
      if (await file.exists()) {
        await file.delete();
      }
    }
    await DatabaseHelper.instance.deleteRecipe(id);
  }

  /// Get total recipe count
  Future<int> getRecipeCount() => DatabaseHelper.instance.getRecipeCount();

  /// Add a tag to a recipe
  Future<void> addTag(String recipeId, String tagName) =>
      DatabaseHelper.instance.addTagToRecipe(recipeId, tagName);

  /// Remove a tag from a recipe
  Future<void> removeTag(String recipeId, String tagName) =>
      DatabaseHelper.instance.removeTagFromRecipe(recipeId, tagName);

  /// Export all recipes as JSON string
  Future<String> exportAllAsJson() =>
      DatabaseHelper.instance.exportAllRecipesAsJson();

  /// Import recipes from JSON string
  Future<int> importFromJson(String jsonString) =>
      DatabaseHelper.instance.importRecipesFromJson(jsonString);
}
