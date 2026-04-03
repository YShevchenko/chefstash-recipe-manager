import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:recipe_manager/main.dart';
import 'package:recipe_manager/features/vault/presentation/screens/vault_screen.dart';

void main() {
  group('VaultScreen Widget Tests', () {
    Widget buildSubject() {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => RecipeListNotifier()),
        ],
        child: const MaterialApp(
          home: VaultScreen(),
        ),
      );
    }

    testWidgets('shows Scaffold', (WidgetTester tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(); // one frame — don't wait for async DB
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('has app bar', (WidgetTester tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('has floating action button', (WidgetTester tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.text('Add Recipe'), findsOneWidget);
    });

    testWidgets('has settings icon', (WidgetTester tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();
      expect(find.byIcon(Icons.settings), findsOneWidget);
    });
  });
}
