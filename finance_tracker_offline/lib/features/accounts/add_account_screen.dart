import 'package:finance_tracker_offline/core/database/db_service.dart';
import 'package:finance_tracker_offline/features/accounts/providers/account_provider.dart';
import 'package:finance_tracker_offline/models/account.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Account'),
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
                decoration: const InputDecoration(
                  labelText: 'Account Name',
                  hintText: 'e.g., HDFC Salary',
                  border: OutlineInputBorder(),
                ),
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
                decoration: const InputDecoration(
                  labelText: 'Account Type',
                  border: OutlineInputBorder(),
                ),
                items: _accountTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type),
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
                decoration: const InputDecoration(
                  labelText: 'SMS Matching Digits',
                  hintText: 'Last 4 digits of account/card',
                  border: OutlineInputBorder(),
                  counterText: "",
                ),
                keyboardType: TextInputType.number,
                maxLength: 4,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _initialBalanceController,
                decoration: const InputDecoration(
                  labelText: 'Initial Balance',
                  border: OutlineInputBorder(),
                  prefixText: '₹ ',
                ),
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
              const Text(
                'Color',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                            ? Border.all(color: Colors.black, width: 3)
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
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Save Account',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
