import 'package:finance_tracker_offline/core/database/db_service.dart';
import 'package:finance_tracker_offline/features/accounts/providers/account_provider.dart';
import 'package:finance_tracker_offline/models/account.dart';
import 'package:finance_tracker_offline/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class AddAccountScreen extends ConsumerStatefulWidget {
  const AddAccountScreen({super.key});

  @override
  ConsumerState<AddAccountScreen> createState() => _AddAccountScreenState();
}

class _AddAccountScreenState extends ConsumerState<AddAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _lastFourDigitsController = TextEditingController();
  final _initialBalanceController = TextEditingController();
  
  String _selectedType = 'Bank';
  String _selectedColor = 'FF42A5F5'; // Default Blue

  final List<String> _accountTypes = ['Cash', 'Bank', 'Card'];
  
  final List<Map<String, String>> _colors = [
    {'name': 'Blue', 'hex': 'FF42A5F5'},
    {'name': 'Red', 'hex': 'FFEF5350'},
    {'name': 'Green', 'hex': 'FF66BB6A'},
    {'name': 'Orange', 'hex': 'FFFFA726'},
    {'name': 'Purple', 'hex': 'FFAB47BC'},
    {'name': 'Teal', 'hex': 'FF26A69A'},
    {'name': 'Brown', 'hex': 'FF8D6E63'},
    {'name': 'Grey', 'hex': 'FF78909C'},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _lastFourDigitsController.dispose();
    _initialBalanceController.dispose();
    super.dispose();
  }

  Future<void> _saveAccount() async {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text.trim();
      final lastFourDigits = _lastFourDigitsController.text.trim();
      final initialBalance = double.tryParse(_initialBalanceController.text) ?? 0.0;

      final account = Account()
        ..name = name
        ..type = _selectedType
        ..lastFourDigits = lastFourDigits.isNotEmpty ? lastFourDigits : null
        ..initialBalance = initialBalance
        ..currentBalance = initialBalance // Initially same as initial balance
        ..colorHex = _selectedColor;

      await ref.read(dbServiceProvider).addAccount(account);
      
      // Refresh the list
      ref.invalidate(accountsProvider);

      if (mounted) {
        context.pop();
      }
    }
  }

  InputDecoration _inputDecoration(BuildContext context, String label, {String? hint, String? prefixText}) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? AppColors.primaryBlack;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? Colors.white : AppColors.brandDark;

    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixText: prefixText,
      filled: true,
      fillColor: Theme.of(context).cardTheme.color,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: borderColor, width: 1),
      ),
      labelStyle: GoogleFonts.poppins(color: AppColors.secondaryGrey),
      hintStyle: GoogleFonts.poppins(color: AppColors.secondaryGrey),
      prefixStyle: GoogleFonts.poppins(color: textColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? AppColors.primaryBlack;
    final borderColor = isDark ? Colors.white : AppColors.brandDark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Add Account', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                style: GoogleFonts.poppins(color: textColor),
                decoration: _inputDecoration(context, 'Account Name', hint: 'e.g., HDFC Salary'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (context) {
                      return SafeArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 16),
                            Text(
                              'Select Account Type',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ..._accountTypes.map((type) {
                              return ListTile(
                                title: Text(
                                  type,
                                  style: GoogleFonts.poppins(color: textColor),
                                ),
                                trailing: _selectedType == type
                                    ? Icon(Icons.check, color: borderColor)
                                    : null,
                                onTap: () {
                                  setState(() {
                                    _selectedType = type;
                                  });
                                  Navigator.pop(context);
                                },
                              );
                            }),
                            const SizedBox(height: 16),
                          ],
                        ),
                      );
                    },
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _selectedType,
                          style: GoogleFonts.poppins(color: textColor, fontSize: 16),
                        ),
                      ),
                      Icon(Icons.keyboard_arrow_down, color: textColor),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lastFourDigitsController,
                style: GoogleFonts.poppins(color: textColor),
                decoration: _inputDecoration(context, 'SMS Matching Digits', hint: 'Last 4 digits of account/card').copyWith(counterText: ""),
                keyboardType: TextInputType.number,
                maxLength: 4,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _initialBalanceController,
                style: GoogleFonts.poppins(color: textColor),
                decoration: _inputDecoration(context, 'Initial Balance', prefixText: '₹ '),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter initial balance';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Text(
                'Color',
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _colors.map((color) {
                  final isSelected = _selectedColor == color['hex'];
                  final colorValue = int.parse(color['hex']!, radix: 16);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedColor = color['hex']!;
                      });
                    },
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Color(colorValue),
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: borderColor, width: 3)
                            : null,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white)
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saveAccount,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandRed,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: const StadiumBorder(),
                ),
                child: Text(
                  'Save Account',
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
