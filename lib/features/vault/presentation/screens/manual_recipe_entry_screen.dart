import 'package:flutter/material.dart';
import '../../../../core/services/iap_service.dart';
import '../../../../data/repositories/recipe_repository.dart';

/// Manual recipe entry screen.
/// Can be pre-filled with data from URL extraction (FR-004).
class ManualRecipeEntryScreen extends StatefulWidget {
  /// Pre-filled data from RecipeExtractor (may be null for blank entry)
  final Map<String, dynamic>? prefillData;

  /// The original URL that was extracted from
  final String? sourceUrl;

  const ManualRecipeEntryScreen({
    super.key,
    this.prefillData,
    this.sourceUrl,
  });

  @override
  State<ManualRecipeEntryScreen> createState() =>
      _ManualRecipeEntryScreenState();
}

class _ManualRecipeEntryScreenState extends State<ManualRecipeEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _urlController;
  late final TextEditingController _ingredientsController;
  late final TextEditingController _instructionsController;
  late final TextEditingController _yieldController;
  late final TextEditingController _prepTimeController;
  late final TextEditingController _cookTimeController;
  late final TextEditingController _tagsController;

  bool _isSaving = false;
  String? _imageUrl;

  bool get _isPrefilled => widget.prefillData != null;

  @override
  void initState() {
    super.initState();
    final p = widget.prefillData;

    _titleController =
        TextEditingController(text: p?['title'] as String? ?? '');
    _urlController =
        TextEditingController(text: widget.sourceUrl ?? (p?['url'] as String? ?? ''));
    _ingredientsController =
        TextEditingController(text: p?['ingredients'] as String? ?? '');
    _instructionsController =
        TextEditingController(text: p?['instructions'] as String? ?? '');
    _yieldController =
        TextEditingController(text: p?['yield'] as String? ?? '');
    _prepTimeController =
        TextEditingController(text: p?['prepTime'] as String? ?? '');
    _cookTimeController =
        TextEditingController(text: p?['cookTime'] as String? ?? '');
    _tagsController = TextEditingController();

    _imageUrl = p?['image'] as String?;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _urlController.dispose();
    _ingredientsController.dispose();
    _instructionsController.dispose();
    _yieldController.dispose();
    _prepTimeController.dispose();
    _cookTimeController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _saveRecipe() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      // Parse ingredients list (one per line)
      final ingredients = _ingredientsController.text
          .split('\n')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      // Parse instructions list (double-newline separated steps)
      final instructions = _instructionsController.text
          .split('\n\n')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      // Parse tags (comma separated), only for premium
      List<String> tags = [];
      if (IAPService.instance.isPremium) {
        tags = _tagsController.text
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
      }

      await RecipeRepository.instance.addRecipe(
        title: _titleController.text.trim(),
        ingredients: ingredients,
        instructions: instructions,
        imageUrl: _imageUrl,
        sourceUrl: _urlController.text.trim().isEmpty
            ? null
            : _urlController.text.trim(),
        yield_: _yieldController.text.trim().isEmpty
            ? null
            : _yieldController.text.trim(),
        prepTime: _prepTimeController.text.trim().isEmpty
            ? null
            : _prepTimeController.text.trim(),
        cookTime: _cookTimeController.text.trim().isEmpty
            ? null
            : _cookTimeController.text.trim(),
        tags: tags,
      );

      if (!mounted) return;

      Navigator.pop(context, true);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recipe saved successfully!')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving recipe: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = IAPService.instance.isPremium;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isPrefilled ? 'Confirm & Edit Recipe' : 'Add Recipe Manually'),
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveRecipe,
              child: const Text(
                'SAVE',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Extraction notice if pre-filled
            if (_isPrefilled) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE67E22).withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: const Color(0xFFE67E22).withAlpha(80)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.auto_awesome,
                        color: Color(0xFFE67E22), size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Recipe extracted from URL — review and edit before saving.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Title
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Recipe Title *',
                hintText: 'e.g., Classic Spaghetti Carbonara',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Title is required';
                }
                return null;
              },
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),

            // Source URL
            TextFormField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'Source URL (optional)',
                hintText: 'https://example.com/recipe',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.link),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 16),

            // Image section
            if (_imageUrl != null && _imageUrl!.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(Icons.image, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Image will be downloaded from URL',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _imageUrl = null),
                    tooltip: 'Remove image',
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            // Step photos note (FR-033, Premium only)
            if (isPremium) ...[
              OutlinedButton.icon(
                icon: const Icon(Icons.photo_camera),
                label: const Text('Attach Step Photo (coming soon)'),
                onPressed: null, // placeholder
              ),
              const SizedBox(height: 16),
            ],

            // Yield
            TextFormField(
              controller: _yieldController,
              decoration: const InputDecoration(
                labelText: 'Servings (optional)',
                hintText: 'e.g., 4 servings',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.people),
              ),
            ),
            const SizedBox(height: 16),

            // Times row
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _prepTimeController,
                    decoration: const InputDecoration(
                      labelText: 'Prep Time',
                      hintText: 'PT15M',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.timer_outlined),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _cookTimeController,
                    decoration: const InputDecoration(
                      labelText: 'Cook Time',
                      hintText: 'PT30M',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.local_fire_department),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Tags (Premium only, FR-013)
            if (isPremium) ...[
              TextFormField(
                controller: _tagsController,
                decoration: const InputDecoration(
                  labelText: 'Tags (Premium)',
                  hintText: 'Dinner, Vegan, Quick (comma-separated)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.label_outline),
                ),
              ),
              const SizedBox(height: 16),
            ] else ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lock_outline, size: 16, color: Colors.grey),
                    SizedBox(width: 8),
                    Text(
                      'Custom tags — Premium feature',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Ingredients
            TextFormField(
              controller: _ingredientsController,
              decoration: const InputDecoration(
                labelText: 'Ingredients *',
                hintText: 'One ingredient per line',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Ingredients are required';
                }
                return null;
              },
              maxLines: 10,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 4),
            Text(
              'Tip: One ingredient per line',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),

            // Instructions
            TextFormField(
              controller: _instructionsController,
              decoration: const InputDecoration(
                labelText: 'Instructions *',
                hintText: 'Separate steps with blank lines',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Instructions are required';
                }
                return null;
              },
              maxLines: 15,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 4),
            Text(
              'Tip: Separate each step with a blank line for cooking mode',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),

            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveRecipe,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(_isSaving ? 'Saving...' : 'Save Recipe'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE67E22),
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
