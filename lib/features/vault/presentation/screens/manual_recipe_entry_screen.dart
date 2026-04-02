import 'package:flutter/material.dart';
import '../../../../core/database/database_helper.dart';

/// Manual recipe entry screen for sites without schema.org markup
class ManualRecipeEntryScreen extends StatefulWidget {
  const ManualRecipeEntryScreen({super.key});

  @override
  State<ManualRecipeEntryScreen> createState() => _ManualRecipeEntryScreenState();
}

class _ManualRecipeEntryScreenState extends State<ManualRecipeEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _urlController = TextEditingController();
  final _ingredientsController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _yieldController = TextEditingController();
  final _prepTimeController = TextEditingController();
  final _cookTimeController = TextEditingController();

  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _urlController.dispose();
    _ingredientsController.dispose();
    _instructionsController.dispose();
    _yieldController.dispose();
    _prepTimeController.dispose();
    _cookTimeController.dispose();
    super.dispose();
  }

  Future<void> _saveRecipe() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final recipe = {
        'title': _titleController.text.trim(),
        'url': _urlController.text.trim().isEmpty ? null : _urlController.text.trim(),
        'image': null,
        'ingredients': _ingredientsController.text.trim(),
        'instructions': _instructionsController.text.trim(),
        'yield': _yieldController.text.trim().isEmpty ? null : _yieldController.text.trim(),
        'prepTime': _prepTimeController.text.trim().isEmpty ? null : _prepTimeController.text.trim(),
        'cookTime': _cookTimeController.text.trim().isEmpty ? null : _cookTimeController.text.trim(),
      };

      await DatabaseHelper.instance.insertRecipe(recipe);

      if (!mounted) return;

      // Return success
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
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Recipe Manually'),
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
            // Title (Required)
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

            // URL (Optional)
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

            // Yield (Optional)
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

            // Prep Time (Optional)
            TextFormField(
              controller: _prepTimeController,
              decoration: const InputDecoration(
                labelText: 'Prep Time (optional)',
                hintText: 'e.g., 15 minutes',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.timer),
              ),
            ),
            const SizedBox(height: 16),

            // Cook Time (Optional)
            TextFormField(
              controller: _cookTimeController,
              decoration: const InputDecoration(
                labelText: 'Cook Time (optional)',
                hintText: 'e.g., 30 minutes',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.local_fire_department),
              ),
            ),
            const SizedBox(height: 16),

            // Ingredients (Required)
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
            const SizedBox(height: 8),
            Text(
              'Tip: Enter one ingredient per line',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),

            // Instructions (Required)
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
            const SizedBox(height: 8),
            Text(
              'Tip: Separate each step with a blank line for better readability in cooking mode',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),

            // Save button (mobile-friendly, bottom area)
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
