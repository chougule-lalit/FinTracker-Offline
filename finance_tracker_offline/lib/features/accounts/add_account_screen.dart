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

  InputDecoration _inputDecoration(String label, {String? hint, String? prefixText}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixText: prefixText,
      filled: true,
      fillColor: AppColors.cardSurface,
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
        borderSide: const BorderSide(color: AppColors.brandDark, width: 1),
      ),
      labelStyle: GoogleFonts.poppins(color: AppColors.secondaryGrey),
      hintStyle: GoogleFonts.poppins(color: AppColors.secondaryGrey),
      prefixStyle: GoogleFonts.poppins(color: AppColors.primaryBlack),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: Text('Add Account', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.scaffoldBackground,
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
                style: GoogleFonts.poppins(color: AppColors.primaryBlack),
                decoration: _inputDecoration('Account Name', hint: 'e.g., HDFC Salary'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedType,
                style: GoogleFonts.poppins(color: AppColors.primaryBlack),
                decoration: _inputDecoration('Account Type'),
                dropdownColor: AppColors.cardSurface,
                items: _accountTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type, style: GoogleFonts.poppins(color: AppColors.primaryBlack)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedType = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lastFourDigitsController,
                style: GoogleFonts.poppins(color: AppColors.primaryBlack),
                decoration: _inputDecoration('SMS Matching Digits', hint: 'Last 4 digits of account/card').copyWith(counterText: ""),
                keyboardType: TextInputType.number,
                maxLength: 4,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _initialBalanceController,
                style: GoogleFonts.poppins(color: AppColors.primaryBlack),
                decoration: _inputDecoration('Initial Balance', prefixText: '₹ '),
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
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryBlack),
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
                            ? Border.all(color: AppColors.brandDark, width: 3)
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
