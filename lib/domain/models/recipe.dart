import 'dart:convert';

/// Domain model for a recipe
class Recipe {
  final String id;
  final String title;
  final String? imageLocalPath;
  final List<String> ingredients;
  final List<String> instructions;
  final String? yield_;
  final List<String> tags;
  final String? sourceUrl;
  final DateTime createdAt;
  final String? prepTime;
  final String? cookTime;

  const Recipe({
    required this.id,
    required this.title,
    this.imageLocalPath,
    required this.ingredients,
    required this.instructions,
    this.yield_,
    required this.tags,
    this.sourceUrl,
    required this.createdAt,
    this.prepTime,
    this.cookTime,
  });

  /// Convert from raw SQLite map
  factory Recipe.fromMap(Map<String, dynamic> map, {List<String>? tags}) {
    final ingredientsRaw = map['ingredients'] as String? ?? '';
    final instructionsRaw = map['instructions'] as String? ?? '';

    List<String> ingredientsList;
    List<String> instructionsList;

    // Try JSON decode first, fall back to newline-split
    try {
      final decoded = jsonDecode(ingredientsRaw);
      if (decoded is List) {
        ingredientsList = decoded.map((e) => e.toString()).toList();
      } else {
        ingredientsList = ingredientsRaw.split('\n').where((s) => s.isNotEmpty).toList();
      }
    } catch (_) {
      ingredientsList = ingredientsRaw.split('\n').where((s) => s.isNotEmpty).toList();
    }

    try {
      final decoded = jsonDecode(instructionsRaw);
      if (decoded is List) {
        instructionsList = decoded.map((e) => e.toString()).toList();
      } else {
        instructionsList = instructionsRaw.split('\n\n').where((s) => s.isNotEmpty).toList();
      }
    } catch (_) {
      instructionsList = instructionsRaw.split('\n\n').where((s) => s.isNotEmpty).toList();
    }

    return Recipe(
      id: map['id'] as String,
      title: map['title'] as String? ?? '',
      imageLocalPath: map['image_path'] as String?,
      ingredients: ingredientsList,
      instructions: instructionsList,
      yield_: map['yield'] as String?,
      tags: tags ?? [],
      sourceUrl: map['url'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (map['created_at'] as int?) ?? 0,
      ),
      prepTime: map['prep_time'] as String?,
      cookTime: map['cook_time'] as String?,
    );
  }

  /// Convert to raw SQLite map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'url': sourceUrl,
      'image_path': imageLocalPath,
      'ingredients': jsonEncode(ingredients),
      'instructions': jsonEncode(instructions),
      'yield': yield_,
      'prep_time': prepTime,
      'cook_time': cookTime,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  Recipe copyWith({
    String? id,
    String? title,
    String? imageLocalPath,
    List<String>? ingredients,
    List<String>? instructions,
    String? yield_,
    List<String>? tags,
    String? sourceUrl,
    DateTime? createdAt,
    String? prepTime,
    String? cookTime,
  }) {
    return Recipe(
      id: id ?? this.id,
      title: title ?? this.title,
      imageLocalPath: imageLocalPath ?? this.imageLocalPath,
      ingredients: ingredients ?? this.ingredients,
      instructions: instructions ?? this.instructions,
      yield_: yield_ ?? this.yield_,
      tags: tags ?? this.tags,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      createdAt: createdAt ?? this.createdAt,
      prepTime: prepTime ?? this.prepTime,
      cookTime: cookTime ?? this.cookTime,
    );
  }
}
