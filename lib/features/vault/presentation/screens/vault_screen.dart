import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/services/recipe_extractor.dart';
import '../../../../core/services/iap_service.dart';
import '../../../cooking/presentation/screens/cooking_mode_screen.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import 'manual_recipe_entry_screen.dart';

/// Provider for recipes list
final recipesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return await DatabaseHelper.instance.getAllRecipes();
});

/// Provider for recipe count
final recipeCountProvider = FutureProvider<int>((ref) async {
  return await DatabaseHelper.instance.getRecipeCount();
});

/// Main home screen - The Vault
/// Displays a grid of saved recipes with search and add functionality
class VaultScreen extends ConsumerStatefulWidget {
  const VaultScreen({super.key});

  @override
  ConsumerState<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends ConsumerState<VaultScreen> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>>? _searchResults;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _onSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = null;
      });
      return;
    }

    final results = await DatabaseHelper.instance.searchRecipes(query);
    setState(() {
      _searchResults = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    final recipesAsync = ref.watch(recipesProvider);
    final recipes = _searchResults ?? recipesAsync.value;

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
              );
            },
          ),
        ],
      ),
      body: recipesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error loading recipes: $error'),
        ),
        data: (data) {
          final displayRecipes = recipes ?? data;

          if (displayRecipes.isEmpty) {
            return _buildEmptyState(context);
          }

          return Column(
            children: [
              // Search bar
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
              // Recipe grid
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: displayRecipes.length,
                  itemBuilder: (context, index) {
                    final recipe = displayRecipes[index];
                    return _buildRecipeCard(context, recipe);
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showAddRecipeDialog(context);
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Recipe'),
        backgroundColor: const Color(0xFFE67E22),
      ),
    );
  }

  Widget _buildRecipeCard(BuildContext context, Map<String, dynamic> recipe) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          // Navigate to cooking mode
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CookingModeScreen(recipe: recipe),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recipe image with caching
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: recipe['image_path'] != null && (recipe['image_path'] as String).isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: recipe['image_path'] as String,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[300],
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[300],
                          child: const Center(
                            child: Icon(
                              Icons.restaurant,
                              size: 48,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      )
                    : Container(
                        color: Colors.grey[300],
                        child: const Center(
                          child: Icon(
                            Icons.restaurant,
                            size: 48,
                            color: Colors.grey,
                          ),
                        ),
                      ),
              ),
            ),
            // Recipe title
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe['title'] as String? ?? 'Untitled Recipe',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (recipe['url'] != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      recipe['url'] as String,
                      style: TextStyle(
                        fontSize: 12,
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

  Future<void> _showAddRecipeDialog(BuildContext context) async {
    // Check recipe count and premium status
    final recipeCount = await DatabaseHelper.instance.getRecipeCount();
    final isPremium = IAPService.instance.isPremium;

    // Check if user hit free tier limit
    if (!isPremium && recipeCount >= 10) {
      _showPremiumUpgradeDialog(context);
      return;
    }

    final urlController = TextEditingController();

    if (!context.mounted) return;

    showDialog(
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

          // Close dialog
          Navigator.pop(context);

          // Show loading
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
            // Extract recipe
            final extractedRecipe = await RecipeExtractor.instance.extractRecipe(url);

            if (!context.mounted) return;

            // Close loading dialog
            Navigator.pop(context);

            if (extractedRecipe == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Could not extract recipe from URL. Please try adding manually.'),
                  duration: Duration(seconds: 3),
                ),
              );
              return;
            }

            // Save to database
            await DatabaseHelper.instance.insertRecipe(extractedRecipe);

            // Refresh recipes list
            ref.invalidate(recipesProvider);
            ref.invalidate(recipeCountProvider);

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Recipe added successfully!')),
            );
          } catch (e) {
            if (!context.mounted) return;

            // Close loading dialog
            Navigator.pop(context);

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: $e')),
            );
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
              // Trigger IAP purchase
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

  const _AddRecipeDialog({
    required this.urlController,
    required this.onExtract,
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
              helperText: 'Enter URL from NYT Cooking, AllRecipes, etc.',
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
          onPressed: () async {
            Navigator.pop(context);

            // Navigate to manual entry screen
            final result = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (context) => const ManualRecipeEntryScreen(),
              ),
            );

            // Refresh if recipe was added
            if (result == true && context.mounted) {
              // Trigger refresh - this will be handled by the caller
            }
          },
          child: const Text('Or add manually'),
        ),
        ElevatedButton(
          onPressed: onExtract,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE67E22),
          ),
          child: const Text('Extract Recipe'),
        ),
      ],
    );
  }
}
