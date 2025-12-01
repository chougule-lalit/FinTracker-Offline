import 'package:finance_tracker_offline/features/settings/providers/backup_provider.dart';
import 'package:finance_tracker_offline/features/settings/providers/settings_provider.dart';
import 'package:finance_tracker_offline/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Settings', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSettingsItem(
            context: context,
            icon: Icons.dark_mode,
            title: 'Dark Mode',
            subtitle: 'Toggle application theme',
            onTap: () {
              ref.read(settingsProvider.notifier).toggleTheme(settings.themeMode != ThemeMode.dark);
            },
            trailing: Switch(
              value: settings.themeMode == ThemeMode.dark,
              onChanged: (value) {
                ref.read(settingsProvider.notifier).toggleTheme(value);
              },
              activeColor: Theme.of(context).iconTheme.color,
            ),
          ),
          _buildSettingsItem(
            context: context,
            icon: Icons.currency_exchange,
            title: 'Currency',
            subtitle: '${settings.currencyCode} (${settings.currencySymbol})',
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => SimpleDialog(
                  title: Text('Select Currency', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
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
          _buildSettingsItem(
            context: context,
            icon: Icons.save_alt,
            title: 'Backup Data',
            subtitle: 'Export data to JSON',
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
          _buildSettingsItem(
            context: context,
            icon: Icons.restore,
            title: 'Restore Data',
            subtitle: 'Import JSON and replace DB',
            onTap: () => _confirmRestore(context, ref),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final subtitleColor = textColor?.withOpacity(0.6);
    final iconBgColor = isDark ? const Color(0xFF2C2C2C) : AppColors.brandDark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: textColor,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: subtitleColor,
                    ),
                  ),
                ],
              ),
            ),
            trailing ?? Icon(Icons.chevron_right, color: subtitleColor),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmRestore(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Warning: Data Loss', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text(
            'This will wipe all current data and replace it with the backup. Are you sure?',
            style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Restore', style: GoogleFonts.poppins(color: AppColors.brandRed)),
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
      child: Text('$code ($symbol)', style: GoogleFonts.poppins()),
    );
  }
}
