import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_manager/core/database/database_helper.dart';

void main() {
  group('DatabaseHelper', () {
    late DatabaseHelper db;

    setUp(() async {
      db = DatabaseHelper.instance;
    });

    test('insert and retrieve recipe', () async {
      // Create test recipe
      final testRecipe = {
        'title': 'Test Recipe',
        'url': 'https://example.com',
        'image': null,
        'ingredients': '1 cup flour\n2 eggs',
        'instructions': 'Mix everything\n\nBake at 350F',
        'yield': '4 servings',
        'prepTime': '10 mins',
        'cookTime': '20 mins',
      };

      // Insert recipe
      final id = await db.insertRecipe(testRecipe);
      expect(id, isNotEmpty);

      // Retrieve recipe
      final retrieved = await db.getRecipe(id);
      expect(retrieved, isNotNull);
      expect(retrieved!['title'], 'Test Recipe');
      expect(retrieved['ingredients'], '1 cup flour\n2 eggs');

      // Cleanup
      await db.deleteRecipe(id);
    });

    test('get recipe count', () async {
      final initialCount = await db.getRecipeCount();

      // Add recipe
      final id = await db.insertRecipe({
        'title': 'Count Test',
        'ingredients': 'test',
        'instructions': 'test',
      });

      final newCount = await db.getRecipeCount();
      expect(newCount, initialCount + 1);

      // Cleanup
      await db.deleteRecipe(id);
    });

    test('search recipes', () async {
      // Insert test recipes
      final id1 = await db.insertRecipe({
        'title': 'Chocolate Cake',
        'ingredients': 'chocolate, flour',
        'instructions': 'Bake',
      });

      final id2 = await db.insertRecipe({
        'title': 'Vanilla Cake',
        'ingredients': 'vanilla, flour',
        'instructions': 'Bake',
      });

      // Search for chocolate
      final results = await db.searchRecipes('chocolate');
      expect(results.length, greaterThanOrEqualTo(1));
      expect(results.any((r) => r['title'] == 'Chocolate Cake'), true);

      // Cleanup
      await db.deleteRecipe(id1);
      await db.deleteRecipe(id2);
    });

    test('add and retrieve tags', () async {
      final recipeId = await db.insertRecipe({
        'title': 'Tagged Recipe',
        'ingredients': 'test',
        'instructions': 'test',
      });

      // Add tags
      await db.addTagToRecipe(recipeId, 'dessert');
      await db.addTagToRecipe(recipeId, 'quick');

      // Retrieve tags
      final tags = await db.getRecipeTags(recipeId);
      expect(tags.length, 2);
      expect(tags.contains('dessert'), true);
      expect(tags.contains('quick'), true);

      // Cleanup
      await db.deleteRecipe(recipeId);
    });

    test('export and import recipes', () async {
      // Insert test recipe
      final id1 = await db.insertRecipe({
        'title': 'Export Test Recipe',
        'ingredients': 'test ingredients',
        'instructions': 'test instructions',
      });

      await db.addTagToRecipe(id1, 'exported');

      // Export
      final json = await db.exportAllRecipesAsJson();
      expect(json, isNotEmpty);

      // Delete original
      await db.deleteRecipe(id1);

      // Import
      final imported = await db.importRecipesFromJson(json);
      expect(imported, greaterThan(0));

      // Verify imported recipe exists
      final allRecipes = await db.getAllRecipes();
      final found = allRecipes.any((r) => r['title'] == 'Export Test Recipe');
      expect(found, true);

      // Cleanup
      for (final recipe in allRecipes) {
        if (recipe['title'] == 'Export Test Recipe') {
          await db.deleteRecipe(recipe['id'] as String);
        }
      }
    });
  });
}
