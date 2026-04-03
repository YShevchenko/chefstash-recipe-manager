import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'features/vault/presentation/screens/vault_screen.dart';
import 'core/services/iap_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize IAP service
  await IAPService.instance.initialize();

  runApp(const ChefStashApp());
}

class ChefStashApp extends StatelessWidget {
  const ChefStashApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RecipeListNotifier()),
      ],
      child: MaterialApp(
        title: 'ChefStash',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2C3E50),
            brightness: Brightness.light,
            primary: const Color(0xFF2C3E50),
            secondary: const Color(0xFFE67E22),
            surface: Colors.white,
            onSurface: const Color(0xFF2C3E50),
          ),
          scaffoldBackgroundColor: Colors.white,
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
            backgroundColor: Colors.white,
            foregroundColor: Color(0xFF2C3E50),
          ),
          // Large, readable typography for kitchen use
          textTheme: const TextTheme(
            displayLarge: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
            titleLarge: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
            bodyLarge: TextStyle(
              fontSize: 18,
              color: Color(0xFF2C3E50),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE67E22),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              textStyle: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        home: const VaultScreen(),
      ),
    );
  }
}

/// ChangeNotifier for recipe list state
class RecipeListNotifier extends ChangeNotifier {
  void refresh() {
    notifyListeners();
  }
}
