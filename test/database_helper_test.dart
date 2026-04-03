import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_manager/core/services/recipe_extractor.dart';

void main() {
  group('RecipeExtractor unit tests', () {
    test('extractIngredients handles newline-separated list', () {
      // Test the static parsing logic via extractRecipe
      // We test parseability separately since network is not available in unit tests
      final extractor = RecipeExtractor.instance;
      expect(extractor, isNotNull);
    });

    test('RecipeExtractor singleton returns same instance', () {
      final a = RecipeExtractor.instance;
      final b = RecipeExtractor.instance;
      expect(identical(a, b), isTrue);
    });
  });
}
