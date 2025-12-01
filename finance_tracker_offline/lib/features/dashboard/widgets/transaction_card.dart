import 'package:finance_tracker_offline/core/utils/icon_utils.dart';
import 'package:finance_tracker_offline/core/widgets/full_screen_image_viewer.dart';
import 'package:finance_tracker_offline/features/settings/providers/settings_provider.dart';
import 'package:finance_tracker_offline/models/transaction.dart';
import 'package:finance_tracker_offline/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class TransactionCard extends ConsumerWidget {
  const TransactionCard({
    required this.transaction,
    super.key,
  });

  final Transaction transaction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final category = transaction.category.value;
    final isTransfer = transaction.isTransfer;
    final isExpense = transaction.isExpense;

    // 1. Color Logic
    final Color amountColor;
    if (isTransfer) {
      amountColor = AppColors.primaryBlack;
    } else {
      amountColor = isExpense ? AppColors.brandRed : AppColors.primaryBlack;
    }

    final amountPrefix = isTransfer ? '' : (isExpense ? '-' : '+');

    // 2. Title Logic
    final String title;
    if (isTransfer) {
      final targetName = transaction.transferAccount.value?.name ?? 'Unknown';
      title = 'Transfer to $targetName';
    } else {
      title = category?.name ?? 'Unknown';
    }

    // 3. Icon Logic
    final IconData iconData;
    
    if (isTransfer) {
      iconData = Icons.swap_horiz;
    } else {
      iconData = category != null
          ? IconUtils.getIconData(category.iconCode)
          : Icons.help_outline;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.brandDark,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              iconData,
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
                    color: AppColors.primaryBlack,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (transaction.note.isNotEmpty || (transaction.receiptPath?.isNotEmpty ?? false)) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (transaction.note.isNotEmpty)
                        Flexible(
                          child: Text(
                            transaction.note,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              color: AppColors.secondaryGrey,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      if (transaction.note.isNotEmpty && (transaction.receiptPath?.isNotEmpty ?? false))
                        const SizedBox(width: 8),
                      if (transaction.receiptPath?.isNotEmpty ?? false)
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => FullScreenImageViewer(
                                  imagePath: transaction.receiptPath!,
                                ),
                              ),
                            );
                          },
                          child: const Icon(Icons.attachment, size: 16, color: AppColors.secondaryGrey),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Text(
            '$amountPrefix${settings.currencySymbol} ${transaction.amount.toStringAsFixed(2)}',
            style: GoogleFonts.poppins(
              color: amountColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
