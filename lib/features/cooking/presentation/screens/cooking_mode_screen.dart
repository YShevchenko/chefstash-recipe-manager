import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Cooking Mode screen with giant text and screen wakelock
class CookingModeScreen extends StatefulWidget {
  final Map<String, dynamic> recipe;

  const CookingModeScreen({super.key, required this.recipe});

  @override
  State<CookingModeScreen> createState() => _CookingModeScreenState();
}

class _CookingModeScreenState extends State<CookingModeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Set<int> _checkedIngredients = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _enableWakelock();
  }

  @override
  void dispose() {
    _disableWakelock();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _enableWakelock() async {
    await WakelockPlus.enable();
  }

  Future<void> _disableWakelock() async {
    await WakelockPlus.disable();
  }

  @override
  Widget build(BuildContext context) {
    final ingredients = (widget.recipe['ingredients'] as String?)?.split('\n') ?? [];
    final instructions = (widget.recipe['instructions'] as String?)?.split('\n\n') ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFF2C3E50),
      appBar: AppBar(
        title: const Text(
          'Cooking Mode',
          style: TextStyle(color: Colors.white),
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
          // Ingredients tab
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
                            color: Colors.white,
                            decoration: isChecked ? TextDecoration.lineThrough : null,
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
