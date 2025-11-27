import 'package:finance_tracker_offline/core/database/db_service.dart';
import 'package:finance_tracker_offline/features/add_transaction/providers/category_provider.dart';
import 'package:finance_tracker_offline/models/category.dart';
import 'package:finance_tracker_offline/models/transaction.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  ConsumerState<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  bool isExpense = true;
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  Category? _selectedCategory;
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  IconData _getIconData(String iconCode) {
    switch (iconCode) {
      case 'fastfood':
        return Icons.fastfood;
      case 'directions_bus':
        return Icons.directions_bus;
      case 'shopping_bag':
        return Icons.shopping_bag;
      case 'payments':
        return Icons.payments;
      case 'work':
        return Icons.work;
      default:
        return Icons.category;
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveTransaction() async {
    if (_amountController.text.isEmpty || _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter amount and select category')),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid amount')),
      );
      return;
    }

    final txn = Transaction()
      ..amount = amount
      ..note = _noteController.text
      ..date = _selectedDate
      ..isExpense = isExpense
      ..category.value = _selectedCategory;

    await ref.read(dbServiceProvider).addTransaction(txn);

    if (mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Transaction'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Toggle Buttons
            ToggleButtons(
              isSelected: [isExpense, !isExpense],
              onPressed: (int index) {
                setState(() {
                  isExpense = index == 0;
                  _selectedCategory = null; // Reset category on toggle
                });
              },
              children: const [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Text('Expense'),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Text('Income'),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Amount TextField
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Amount',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // Category Dropdown
            categoriesAsync.when(
              data: (categories) {
                final filteredCategories = categories
                    .where((c) => c.isExpense == isExpense)
                    .toList();

                return DropdownButtonFormField<Category>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: filteredCategories.map((Category category) {
                    return DropdownMenuItem<Category>(
                      value: category,
                      child: Row(
                        children: [
                          Icon(_getIconData(category.iconCode)),
                          const SizedBox(width: 10),
                          Text(category.name),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (Category? newValue) {
                    setState(() {
                      _selectedCategory = newValue;
                    });
                  },
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (err, stack) => Text('Error: $err'),
            ),
            const SizedBox(height: 20),

            // Date Picker
            InkWell(
              onTap: () => _selectDate(context),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date',
                  border: OutlineInputBorder(),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(DateFormat.yMMMd().format(_selectedDate)),
                    const Icon(Icons.calendar_today),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Note TextField
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Note (Optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const Spacer(),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saveTransaction,
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
