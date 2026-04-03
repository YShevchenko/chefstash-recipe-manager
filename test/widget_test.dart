import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:recipe_manager/main.dart';

void main() {
  testWidgets('App has ChefStash title', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => RecipeListNotifier()),
        ],
        child: MaterialApp(
          home: Scaffold(
            appBar: AppBar(title: Text('ChefStash')),
          ),
        ),
      ),
    );
    expect(find.text('ChefStash'), findsOneWidget);
  });
}
