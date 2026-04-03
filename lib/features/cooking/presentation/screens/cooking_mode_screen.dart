import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../../../domain/models/recipe.dart';

/// Cooking Mode screen — FR-021, FR-022, FR-023
/// Enlarged typography, wakelock, ingredient checkboxes
class CookingModeScreen extends StatefulWidget {
  final Recipe recipe;

  const CookingModeScreen({super.key, required this.recipe});

  @override
  State<CookingModeScreen> createState() => _CookingModeScreenState();
}

class _CookingModeScreenState extends State<CookingModeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Set<int> _checkedIngredients = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ingredients = widget.recipe.ingredients;
    final instructions = widget.recipe.instructions;

    return Scaffold(
      backgroundColor: const Color(0xFF2C3E50),
      appBar: AppBar(
        title: Text(
          widget.recipe.title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: const Color(0xFF2C3E50),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFFE67E22),
          unselectedLabelColor: Colors.white70,
          indicatorColor: const Color(0xFFE67E22),
          tabs: const [
            Tab(text: 'INGREDIENTS'),
            Tab(text: 'INSTRUCTIONS'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Ingredients tab — FR-023: tap to strike through
          ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: ingredients.length,
            itemBuilder: (context, index) {
              final ingredient = ingredients[index].trim();
              if (ingredient.isEmpty) return const SizedBox.shrink();

              final isChecked = _checkedIngredients.contains(index);

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      if (isChecked) {
                        _checkedIngredients.remove(index);
                      } else {
                        _checkedIngredients.add(index);
                      }
                    });
                  },
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: isChecked,
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              _checkedIngredients.add(index);
                            } else {
                              _checkedIngredients.remove(index);
                            }
                          });
                        },
                        activeColor: const Color(0xFFE67E22),
                        checkColor: Colors.white,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          ingredient,
                          style: TextStyle(
                            fontSize: 20,
                            height: 1.5,
                            color:
                                isChecked ? Colors.white54 : Colors.white,
                            decoration: isChecked
                                ? TextDecoration.lineThrough
                                : null,
                            decorationColor: Colors.white54,
                            decorationThickness: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Instructions tab
          ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: instructions.length,
            itemBuilder: (context, index) {
              final instruction = instructions[index].trim();
              if (instruction.isEmpty) return const SizedBox.shrink();

              return Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE67E22),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        instruction,
                        style: const TextStyle(
                          fontSize: 20,
                          height: 1.6,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
