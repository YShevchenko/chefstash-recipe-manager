import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/recipe_extractor.dart';
import '../../../../core/services/iap_service.dart';
import '../../../../data/repositories/recipe_repository.dart';
import '../../../../domain/models/recipe.dart';
import '../../../../main.dart';
import '../../../cooking/presentation/screens/cooking_mode_screen.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import 'manual_recipe_entry_screen.dart';

/// Main home screen - The Vault
class VaultScreen extends StatefulWidget {
  const VaultScreen({super.key});

  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> {
  final _searchController = TextEditingController();
  List<Recipe>? _allRecipes;
  List<Recipe>? _searchResults;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRecipes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRecipes() async {
    try {
      final recipes = await RecipeRepository.instance.getAllRecipes();
      if (mounted) {
        setState(() {
          _allRecipes = recipes;
          _loading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _onSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = null;
      });
      return;
    }

    final results = await RecipeRepository.instance.searchRecipes(query);
    if (mounted) {
      setState(() {
        _searchResults = results;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen for refresh signals
    context.watch<RecipeListNotifier>();

    final displayRecipes = _searchResults ?? _allRecipes ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ChefStash',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              ).then((_) => _loadRecipes());
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error loading recipes: $_error'))
              : (_allRecipes?.isEmpty ?? true)
                  ? _buildEmptyState(context)
                  : Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: TextField(
                            controller: _searchController,
                            onChanged: _onSearch,
                            decoration: InputDecoration(
                              hintText: 'Search recipes...',
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        _searchController.clear();
                                        _onSearch('');
                                      },
                                    )
                                  : null,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.grey[100],
                            ),
                          ),
                        ),
                        Expanded(
                          child: GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 0.72,
                            ),
                            itemCount: displayRecipes.length,
                            itemBuilder: (context, index) {
                              return _buildRecipeCard(
                                  context, displayRecipes[index]);
                            },
                          ),
                        ),
                      ],
                    ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddRecipeDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Recipe'),
        backgroundColor: const Color(0xFFE67E22),
      ),
    );
  }

  Widget _buildRecipeCard(BuildContext context, Recipe recipe) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CookingModeScreen(recipe: recipe),
            ),
          );
        },
        onLongPress: () => _showRecipeOptions(context, recipe),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recipe image
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: _buildRecipeImage(recipe),
              ),
            ),
            // Recipe info
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.title.isNotEmpty ? recipe.title : 'Untitled Recipe',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (recipe.tags.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      children: recipe.tags
                          .take(2)
                          .map(
                            (tag) => Chip(
                              label: Text(
                                tag,
                                style: const TextStyle(fontSize: 10),
                              ),
                              padding: EdgeInsets.zero,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                              backgroundColor:
                                  const Color(0xFFE67E22).withAlpha(30),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                  if (recipe.sourceUrl != null &&
                      recipe.sourceUrl!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      recipe.sourceUrl!,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipeImage(Recipe recipe) {
    if (recipe.imageLocalPath != null && recipe.imageLocalPath!.isNotEmpty) {
      final file = File(recipe.imageLocalPath!);
      return FutureBuilder<bool>(
        future: file.exists(),
        builder: (context, snapshot) {
          if (snapshot.data == true) {
            return Image.file(
              file,
              fit: BoxFit.cover,
              width: double.infinity,
              errorBuilder: (context, error, stack) => _placeholderImage(),
            );
          }
          return _placeholderImage();
        },
      );
    }
    return _placeholderImage();
  }

  Widget _placeholderImage() {
    return Container(
      color: Colors.grey[300],
      child: const Center(
        child: Icon(
          Icons.restaurant,
          size: 48,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.restaurant_menu,
            size: 100,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 24),
          Text(
            'Your vault is empty',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Paste a URL or add a recipe manually to get started',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showRecipeOptions(BuildContext context, Recipe recipe) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.kitchen),
              title: const Text('Cook Now'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CookingModeScreen(recipe: recipe),
                  ),
                );
              },
            ),
            if (IAPService.instance.isPremium)
              ListTile(
                leading: const Icon(Icons.label),
                title: const Text('Manage Tags'),
                onTap: () {
                  Navigator.pop(context);
                  _showTagsDialog(context, recipe);
                },
              )
            else
              ListTile(
                leading: const Icon(Icons.label_outlined),
                title: const Text('Manage Tags (Premium)'),
                subtitle: const Text('Upgrade to add custom tags'),
                onTap: () {
                  Navigator.pop(context);
                  _showPremiumUpgradeDialog(context);
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Delete Recipe',
                  style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                await _confirmDelete(context, recipe);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Recipe recipe) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Recipe?'),
        content: Text('Delete "${recipe.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await RecipeRepository.instance.deleteRecipe(recipe.id);
      _loadRecipes();
    }
  }

  void _showTagsDialog(BuildContext context, Recipe recipe) {
    final tagController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Manage Tags'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                children: recipe.tags
                    .map(
                      (tag) => Chip(
                        label: Text(tag),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () async {
                          await RecipeRepository.instance
                              .removeTag(recipe.id, tag);
                          // Reload the recipe tags
                          final updated =
                              await RecipeRepository.instance
                                  .getRecipe(recipe.id);
                          if (updated != null && context.mounted) {
                            setDialogState(() {
                              recipe.tags.clear();
                              recipe.tags.addAll(updated.tags);
                            });
                          }
                        },
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: tagController,
                      decoration: const InputDecoration(
                        hintText: 'Add tag (e.g., Dinner)',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) async {
                        final tag = tagController.text.trim();
                        if (tag.isNotEmpty) {
                          await RecipeRepository.instance
                              .addTag(recipe.id, tag);
                          tagController.clear();
                          final updated =
                              await RecipeRepository.instance
                                  .getRecipe(recipe.id);
                          if (updated != null && context.mounted) {
                            setDialogState(() {
                              recipe.tags.clear();
                              recipe.tags.addAll(updated.tags);
                            });
                          }
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () async {
                      final tag = tagController.text.trim();
                      if (tag.isNotEmpty) {
                        await RecipeRepository.instance
                            .addTag(recipe.id, tag);
                        tagController.clear();
                        final updated =
                            await RecipeRepository.instance
                                .getRecipe(recipe.id);
                        if (updated != null && context.mounted) {
                          setDialogState(() {
                            recipe.tags.clear();
                            recipe.tags.addAll(updated.tags);
                          });
                        }
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _loadRecipes();
              },
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddRecipeDialog(BuildContext context) async {
    // Check recipe count and premium status
    final recipeCount = await RecipeRepository.instance.getRecipeCount();
    final isPremium = IAPService.instance.isPremium;

    if (!isPremium && recipeCount >= 10) {
      // ignore: use_build_context_synchronously
      if (mounted) _showPremiumUpgradeDialog(context);
      return;
    }

    final urlController = TextEditingController();

    if (!mounted) return;

    showDialog(
      // ignore: use_build_context_synchronously
      context: context,
      builder: (context) => _AddRecipeDialog(
        urlController: urlController,
        onExtract: () async {
          final url = urlController.text.trim();
          if (url.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please enter a URL')),
            );
            return;
          }

          Navigator.pop(context);

          // Show loading indicator
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Extracting recipe...'),
                    ],
                  ),
                ),
              ),
            ),
          );

          try {
            final extractedRecipe =
                await RecipeExtractor.instance.extractRecipe(url);

            if (!context.mounted) return;
            Navigator.pop(context); // close loading

            // Navigate to ManualRecipeEntryScreen pre-filled with extracted data
            final saved = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (context) => ManualRecipeEntryScreen(
                  prefillData: extractedRecipe,
                  sourceUrl: url,
                ),
              ),
            );

            if (saved == true) {
              _loadRecipes();
            }
          } catch (e) {
            if (!context.mounted) return;
            Navigator.pop(context); // close loading
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: $e')),
            );
          }
        },
        onManual: () async {
          Navigator.pop(context);
          final saved = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) => const ManualRecipeEntryScreen(),
            ),
          );
          if (saved == true) {
            _loadRecipes();
          }
        },
      ),
    );
  }

  void _showPremiumUpgradeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upgrade to Premium'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock,
              size: 64,
              color: Color(0xFFE67E22),
            ),
            SizedBox(height: 16),
            Text(
              'You\'ve reached the free tier limit of 10 recipes.',
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'Upgrade to Premium for unlimited recipes, custom tags, and export functionality.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Maybe Later'),
          ),
          ElevatedButton(
            onPressed: () async {
              final success = await IAPService.instance.purchase();
              if (!context.mounted) return;
              Navigator.pop(context);
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Premium unlocked! Thank you!')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE67E22),
            ),
            child: const Text('Upgrade (\$19.99)'),
          ),
        ],
      ),
    );
  }
}

/// Dialog widget for adding recipes
class _AddRecipeDialog extends StatelessWidget {
  final TextEditingController urlController;
  final VoidCallback onExtract;
  final VoidCallback onManual;

  const _AddRecipeDialog({
    required this.urlController,
    required this.onExtract,
    required this.onManual,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Recipe'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: urlController,
            decoration: const InputDecoration(
              hintText: 'Paste recipe URL',
              prefixIcon: Icon(Icons.link),
              helperText: 'Enter URL from AllRecipes, NYT Cooking, etc.',
            ),
            autofocus: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => onExtract(),
          ),
          const SizedBox(height: 16),
          const Text(
            'Free tier: 10 recipes\nPremium: Unlimited recipes',
            style: TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: onManual,
          child: const Text('Add Manually'),
        ),
        ElevatedButton(
          onPressed: onExtract,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE67E22),
          ),
          child: const Text('Extract'),
        ),
      ],
    );
  }
}
