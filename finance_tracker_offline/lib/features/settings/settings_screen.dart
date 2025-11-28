import 'package:finance_tracker_offline/features/settings/providers/backup_provider.dart';
import 'package:finance_tracker_offline/features/settings/providers/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.currency_exchange),
            title: const Text('Currency'),
            subtitle: Text('${settings.currencyCode} (${settings.currencySymbol})'),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => SimpleDialog(
                  title: const Text('Select Currency'),
                  children: [
                    _buildCurrencyOption(context, ref, 'INR', '₹'),
                    _buildCurrencyOption(context, ref, 'USD', '\$'),
                    _buildCurrencyOption(context, ref, 'EUR', '€'),
                    _buildCurrencyOption(context, ref, 'GBP', '£'),
                  ],
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.save_alt),
            title: const Text('Backup Data'),
            subtitle: const Text('Export data to JSON'),
            onTap: () async {
              try {
                await ref.read(backupServiceProvider).createBackup();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Backup file generated')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Backup failed: $e')),
                  );
                }
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.restore),
            title: const Text('Restore Data'),
            subtitle: const Text('Import JSON and replace DB'),
            onTap: () => _confirmRestore(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmRestore(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Warning: Data Loss'),
        content: const Text(
            'This will wipe all current data and replace it with the backup. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Restore', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Restoring...')),
        );

        final success = await ref.read(backupServiceProvider).restoreBackup();

        if (context.mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Data restored successfully')),
            );
          } else {
            // User cancelled file picker
          }
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Restore failed: $e')),
          );
        }
      }
    }
  }

  Widget _buildCurrencyOption(
    BuildContext context,
    WidgetRef ref,
    String code,
    String symbol,
  ) {
    return SimpleDialogOption(
      onPressed: () {
        ref.read(settingsProvider.notifier).updateCurrency(code, symbol);
        Navigator.pop(context);
      },
      child: Text('$code ($symbol)'),
    );
  }
}
