import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/services/iap_service.dart';
import '../../../vault/presentation/screens/vault_screen.dart';

/// Settings screen with export/import and premium features
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isExporting = false;
  bool _isImporting = false;

  Future<void> _exportRecipes() async {
    if (!IAPService.instance.isPremium) {
      _showPremiumRequiredDialog('Export Recipes');
      return;
    }

    setState(() {
      _isExporting = true;
    });

    try {
      // Export recipes as JSON
      final jsonString = await DatabaseHelper.instance.exportAllRecipesAsJson();

      // Create temp file
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final file = File('${directory.path}/chefstash_backup_$timestamp.json');
      await file.writeAsString(jsonString);

      // Share file
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'ChefStash Recipe Backup',
        text: 'My ChefStash recipes exported on $timestamp',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recipes exported successfully!')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  Future<void> _importRecipes() async {
    if (!IAPService.instance.isPremium) {
      _showPremiumRequiredDialog('Import Recipes');
      return;
    }

    setState(() {
      _isImporting = true;
    });

    try {
      // Pick JSON file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.single.path == null) {
        if (mounted) {
          setState(() {
            _isImporting = false;
          });
        }
        return;
      }

      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();

      // Import recipes
      final imported = await DatabaseHelper.instance.importRecipesFromJson(jsonString);

      // Refresh recipes list
      ref.invalidate(recipesProvider);
      ref.invalidate(recipeCountProvider);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Imported $imported recipes successfully!')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Import failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isImporting = false;
        });
      }
    }
  }

  void _showPremiumRequiredDialog(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Premium Feature'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.lock,
              size: 64,
              color: Color(0xFFE67E22),
            ),
            const SizedBox(height: 16),
            Text(
              '$feature is a premium feature.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Upgrade to Premium for unlimited recipes, custom tags, and export/import functionality.',
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
                setState(() {}); // Refresh premium status
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

  @override
  Widget build(BuildContext context) {
    final isPremium = IAPService.instance.isPremium;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Premium Status Section
          if (!isPremium)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE67E22).withOpacity(0.1),
                border: Border.all(color: const Color(0xFFE67E22), width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.workspace_premium,
                    size: 48,
                    color: Color(0xFFE67E22),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Upgrade to Premium',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• Unlimited recipes\n• Custom tags\n• Export/Import backups',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      final success = await IAPService.instance.purchase();
                      if (!context.mounted) return;

                      if (success) {
                        setState(() {}); // Refresh premium status
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Premium unlocked! Thank you!')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE67E22),
                    ),
                    child: const Text('Upgrade for \$19.99'),
                  ),
                ],
              ),
            ),

          // Data Management Section
          const ListTile(
            title: Text(
              'DATA MANAGEMENT',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          ListTile(
            leading: Icon(
              Icons.upload_file,
              color: isPremium ? const Color(0xFFE67E22) : Colors.grey,
            ),
            title: const Text('Export Recipes'),
            subtitle: Text(
              isPremium ? 'Backup all recipes as JSON' : 'Premium only',
              style: TextStyle(color: isPremium ? null : Colors.grey),
            ),
            trailing: _isExporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.chevron_right),
            onTap: _isExporting ? null : _exportRecipes,
          ),
          ListTile(
            leading: Icon(
              Icons.download,
              color: isPremium ? const Color(0xFFE67E22) : Colors.grey,
            ),
            title: const Text('Import Recipes'),
            subtitle: Text(
              isPremium ? 'Restore from JSON backup' : 'Premium only',
              style: TextStyle(color: isPremium ? null : Colors.grey),
            ),
            trailing: _isImporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.chevron_right),
            onTap: _isImporting ? null : _importRecipes,
          ),
          const Divider(),

          // About Section
          const ListTile(
            title: Text(
              'ABOUT',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Version'),
            subtitle: Text('1.0.0 (Build 1)'),
          ),
          const ListTile(
            leading: Icon(Icons.business),
            title: Text('Publisher'),
            subtitle: Text('Heldig Lab'),
          ),
          const ListTile(
            leading: Icon(Icons.email_outlined),
            title: Text('Contact'),
            subtitle: Text('heldig.lab@pm.me'),
          ),
          const ListTile(
            leading: Icon(Icons.privacy_tip_outlined),
            title: Text('Privacy'),
            subtitle: Text('100% offline, no data collection'),
          ),
        ],
      ),
    );
  }
}
