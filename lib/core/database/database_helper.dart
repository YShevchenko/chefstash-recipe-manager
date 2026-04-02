import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

/// SQLite database helper for ChefStash
/// Manages local recipe storage with zero backend dependency
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  final _uuid = const Uuid();

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('chefstash.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const intType = 'INTEGER NOT NULL';

    // Recipes table - stores extracted recipe data
    await db.execute('''
CREATE TABLE recipes (
  id $idType,
  title $textType,
  url TEXT,
  image_path TEXT,
  ingredients $textType,
  instructions $textType,
  yield TEXT,
  prep_time TEXT,
  cook_time TEXT,
  created_at $intType,
  last_viewed INTEGER
)
    ''');

    // Tags table - stores custom categorization tags (Premium feature)
    await db.execute('''
CREATE TABLE tags (
  id $idType,
  name $textType UNIQUE
)
    ''');

    // Recipe-Tag junction table (many-to-many relationship)
    await db.execute('''
CREATE TABLE recipe_tags (
  recipe_id TEXT NOT NULL,
  tag_id TEXT NOT NULL,
  PRIMARY KEY (recipe_id, tag_id),
  FOREIGN KEY (recipe_id) REFERENCES recipes (id) ON DELETE CASCADE,
  FOREIGN KEY (tag_id) REFERENCES tags (id) ON DELETE CASCADE
)
    ''');

    // Create indexes for faster queries
    await db.execute('CREATE INDEX idx_recipes_created_at ON recipes(created_at DESC)');
    await db.execute('CREATE INDEX idx_recipes_title ON recipes(title)');
  }

  // Recipe CRUD operations
  Future<String> insertRecipe(Map<String, dynamic> recipe) async {
    final db = await database;
    final id = _uuid.v4();

    await db.insert('recipes', {
      'id': id,
      'title': recipe['title'] ?? '',
      'url': recipe['url'],
      'image_path': recipe['image'],
      'ingredients': recipe['ingredients'] ?? '',
      'instructions': recipe['instructions'] ?? '',
      'yield': recipe['yield'],
      'prep_time': recipe['prepTime'],
      'cook_time': recipe['cookTime'],
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'last_viewed': null,
    });

    return id;
  }

  Future<List<Map<String, dynamic>>> getAllRecipes() async {
    final db = await database;
    return await db.query(
      'recipes',
      orderBy: 'created_at DESC',
    );
  }

  Future<Map<String, dynamic>?> getRecipe(String id) async {
    final db = await database;
    final results = await db.query(
      'recipes',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (results.isEmpty) return null;

    // Update last_viewed timestamp
    await db.update(
      'recipes',
      {'last_viewed': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [id],
    );

    return results.first;
  }

  Future<int> getRecipeCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM recipes');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> deleteRecipe(String id) async {
    final db = await database;
    await db.delete(
      'recipes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateRecipe(String id, Map<String, dynamic> updates) async {
    final db = await database;
    await db.update(
      'recipes',
      updates,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> searchRecipes(String query) async {
    final db = await database;
    return await db.query(
      'recipes',
      where: 'title LIKE ? OR ingredients LIKE ? OR instructions LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'created_at DESC',
    );
  }

  // Tag operations (Premium feature)
  Future<String> insertTag(String name) async {
    final db = await database;
    final id = _uuid.v4();

    await db.insert(
      'tags',
      {'id': id, 'name': name},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );

    return id;
  }

  Future<String?> getTagId(String name) async {
    final db = await database;
    final results = await db.query(
      'tags',
      columns: ['id'],
      where: 'name = ?',
      whereArgs: [name],
    );

    if (results.isEmpty) return null;
    return results.first['id'] as String;
  }

  Future<void> addTagToRecipe(String recipeId, String tagName) async {
    final db = await database;

    // Insert tag if it doesn't exist
    await insertTag(tagName);

    // Get tag ID
    final tagId = await getTagId(tagName);
    if (tagId == null) return;

    // Create relationship
    await db.insert(
      'recipe_tags',
      {'recipe_id': recipeId, 'tag_id': tagId},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<List<String>> getRecipeTags(String recipeId) async {
    final db = await database;
    final results = await db.rawQuery('''
      SELECT t.name
      FROM tags t
      INNER JOIN recipe_tags rt ON t.id = rt.tag_id
      WHERE rt.recipe_id = ?
    ''', [recipeId]);

    return results.map((row) => row['name'] as String).toList();
  }

  Future<void> removeTagFromRecipe(String recipeId, String tagName) async {
    final db = await database;
    final tagId = await getTagId(tagName);
    if (tagId == null) return;

    await db.delete(
      'recipe_tags',
      where: 'recipe_id = ? AND tag_id = ?',
      whereArgs: [recipeId, tagId],
    );
  }

  // Export/Import (Premium feature)
  Future<String> exportAllRecipesAsJson() async {
    final db = await database;
    final recipes = await db.query('recipes');

    // Get tags for each recipe
    final List<Map<String, dynamic>> exportData = [];
    for (final recipe in recipes) {
      final tags = await getRecipeTags(recipe['id'] as String);
      exportData.add({
        ...recipe,
        'tags': tags,
      });
    }

    return jsonEncode(exportData);
  }

  Future<int> importRecipesFromJson(String jsonString) async {
    final List<dynamic> data = jsonDecode(jsonString);
    int imported = 0;

    for (final item in data) {
      try {
        final recipeId = await insertRecipe(item as Map<String, dynamic>);

        // Add tags if present
        final tags = item['tags'] as List<dynamic>?;
        if (tags != null) {
          for (final tag in tags) {
            await addTagToRecipe(recipeId, tag as String);
          }
        }
        imported++;
      } catch (e) {
        print('Error importing recipe: $e');
      }
    }

    return imported;
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
