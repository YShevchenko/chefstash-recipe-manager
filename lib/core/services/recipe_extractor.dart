import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart';

/// Service to extract recipes from URLs using schema.org/Recipe data
class RecipeExtractor {
  static final RecipeExtractor instance = RecipeExtractor._();
  RecipeExtractor._();

  Future<Map<String, dynamic>?> extractRecipe(String url) async {
    try {
      // Fetch HTML
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        return null;
      }

      // Parse HTML
      final document = parser.parse(response.body);

      // Try to find schema.org/Recipe JSON-LD
      final recipe = _extractFromJsonLd(document);
      if (recipe != null) {
        recipe['url'] = url;
        return recipe;
      }

      // Fallback: try to extract from microdata
      final microdataRecipe = _extractFromMicrodata(document);
      if (microdataRecipe != null) {
        microdataRecipe['url'] = url;
        return microdataRecipe;
      }

      return null;
    } catch (e) {
      debugPrint('Error extracting recipe: $e');
      return null;
    }
  }

  Map<String, dynamic>? _extractFromJsonLd(Document document) {
    try {
      // Find all script tags with type="application/ld+json"
      final scripts = document.querySelectorAll('script[type="application/ld+json"]');

      for (final script in scripts) {
        final jsonText = script.text;
        if (jsonText.isEmpty) continue;

        try {
          final data = jsonDecode(jsonText);

          // Handle both single object and array of objects
          final recipes = <Map<String, dynamic>>[];
          if (data is List) {
            recipes.addAll(data.whereType<Map<String, dynamic>>());
          } else if (data is Map<String, dynamic>) {
            recipes.add(data);
          }

          // Find Recipe object
          for (final item in recipes) {
            if (_isRecipeType(item)) {
              return _normalizeRecipe(item);
            }

            // Check nested @graph
            if (item.containsKey('@graph') && item['@graph'] is List) {
              for (final graphItem in item['@graph']) {
                if (graphItem is Map<String, dynamic> && _isRecipeType(graphItem)) {
                  return _normalizeRecipe(graphItem);
                }
              }
            }
          }
        } catch (e) {
          continue;
        }
      }
    } catch (e) {
      debugPrint('Error extracting from JSON-LD: $e');
    }
    return null;
  }

  bool _isRecipeType(Map<String, dynamic> data) {
    final type = data['@type'];
    if (type == null) return false;
    if (type is String) return type == 'Recipe';
    if (type is List) return type.contains('Recipe');
    return false;
  }

  Map<String, dynamic> _normalizeRecipe(Map<String, dynamic> raw) {
    return {
      'title': _extractString(raw['name']),
      'image': _extractImage(raw['image']),
      'ingredients': _extractIngredients(raw['recipeIngredient']),
      'instructions': _extractInstructions(raw['recipeInstructions']),
      'yield': _extractString(raw['recipeYield']),
      'prepTime': _extractString(raw['prepTime']),
      'cookTime': _extractString(raw['cookTime']),
    };
  }

  String _extractString(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is List && value.isNotEmpty) return value.first.toString();
    return value.toString();
  }

  String _extractImage(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is Map) {
      return value['url'] ?? value['@id'] ?? '';
    }
    if (value is List && value.isNotEmpty) {
      final first = value.first;
      if (first is String) return first;
      if (first is Map) return first['url'] ?? first['@id'] ?? '';
    }
    return '';
  }

  String _extractIngredients(dynamic value) {
    if (value == null) return '';
    if (value is List) {
      return value.map((e) => e.toString()).join('\n');
    }
    return value.toString();
  }

  String _extractInstructions(dynamic value) {
    if (value == null) return '';

    if (value is String) return value;

    if (value is List) {
      return value.map((item) {
        if (item is String) return item;
        if (item is Map) {
          return item['text'] ?? item['name'] ?? item.toString();
        }
        return item.toString();
      }).join('\n\n');
    }

    if (value is Map) {
      return value['text'] ?? value['name'] ?? value.toString();
    }

    return value.toString();
  }

  Map<String, dynamic>? _extractFromMicrodata(Document document) {
    // Fallback: Try to find elements with itemtype="http://schema.org/Recipe"
    final recipeElements = document.querySelectorAll('[itemtype*="schema.org/Recipe"]');
    if (recipeElements.isEmpty) return null;

    final element = recipeElements.first;

    return {
      'title': _extractMicrodataProperty(element, 'name'),
      'image': _extractMicrodataProperty(element, 'image'),
      'ingredients': _extractMicrodataList(element, 'recipeIngredient'),
      'instructions': _extractMicrodataList(element, 'recipeInstructions'),
      'yield': _extractMicrodataProperty(element, 'recipeYield'),
      'prepTime': _extractMicrodataProperty(element, 'prepTime'),
      'cookTime': _extractMicrodataProperty(element, 'cookTime'),
    };
  }

  String _extractMicrodataProperty(Element element, String property) {
    final prop = element.querySelector('[itemprop="$property"]');
    if (prop == null) return '';
    return prop.attributes['content'] ?? prop.text.trim();
  }

  String _extractMicrodataList(Element element, String property) {
    final props = element.querySelectorAll('[itemprop="$property"]');
    if (props.isEmpty) return '';
    return props.map((e) => e.text.trim()).join('\n');
  }
}
