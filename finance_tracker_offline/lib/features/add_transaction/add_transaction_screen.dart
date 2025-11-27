import 'package:finance_tracker_offline/core/database/db_service.dart';
import 'package:finance_tracker_offline/features/add_transaction/providers/category_provider.dart';
import 'package:finance_tracker_offline/models/category.dart';
import 'package:finance_tracker_offline/models/transaction.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  final Transaction? transactionToEdit;

  const AddTransactionScreen({super.key, this.transactionToEdit});

  @override
  ConsumerState<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  late bool _isExpense;
  late DateTime _selectedDate;
  Category? _selectedCategory;
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize state based on whether we are editing or creating
    if (widget.transactionToEdit != null) {
      final txn = widget.transactionToEdit!;
      _isExpense = txn.isExpense;
      _selectedDate = txn.date;
      _amountController.text = txn.amount.toString();
      _noteController.text = txn.note;
      // We load the category in the build method once providers are ready
      // But we set the initial reference here
      _selectedCategory = txn.category.value;
    } else {
      _isExpense = true;
      _selectedDate = DateTime.now();
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _saveTransaction() async {
    if (_formKey.currentState!.validate() && _selectedCategory != null) {
      final amount = double.parse(_amountController.text);
      final dbService = ref.read(dbServiceProvider);

      if (widget.transactionToEdit != null) {
        // UPDATE Existing
        final txn = widget.transactionToEdit!;
        
        // Capture old values for balance reversal
        final oldAmount = txn.amount;
        final oldIsExpense = txn.isExpense;
        final oldAccount = txn.account.value;

        // Update fields
        txn.amount = amount;
        txn.isExpense = _isExpense;
        txn.date = _selectedDate;
        txn.note = _noteController.text;
        txn.category.value = _selectedCategory;

        await dbService.updateTransaction(
          txn,
          oldAmount: oldAmount,
          oldIsExpense: oldIsExpense,
          oldAccount: oldAccount,
        );
      } else {
        // CREATE New
        final txn = Transaction()
          ..amount = amount
          ..isExpense = _isExpense
          ..date = _selectedDate
          ..note = _noteController.text;
        
        txn.category.value = _selectedCategory;
        // Ideally link to a default account or allow account selection here
        // For now, we leave account null or link to default if you have one logic
        // But the prompt asked for basic flow first. 
        
        await dbService.addTransaction(txn);
      }

      if (mounted) {
        context.pop();
      }
    } else if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.transactionToEdit == null ? 'Add Transaction' : 'Edit Transaction'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Toggle Type
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: true, label: Text('Expense'), icon: Icon(Icons.arrow_downward)),
                  ButtonSegment(value: false, label: Text('Income'), icon: Icon(Icons.arrow_upward)),
                ],
                selected: {_isExpense},
                onSelectionChanged: (Set<bool> newSelection) {
                  setState(() {
                    _isExpense = newSelection.first;
                    _selectedCategory = null; // Reset category when switching type
                  });
                },
              ),
              const SizedBox(height: 24),

              // 2. Amount
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixText: '₹ ',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter amount';
                  if (double.tryParse(value) == null) return 'Invalid amount';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 3. Category Dropdown
              categoriesAsync.when(
                data: (allCategories) {
                  // Filter categories by type
                  final filteredCategories = allCategories
                      .where((c) => c.isExpense == _isExpense)
                      .toList();

                  // FIX: Ensure selected category is valid in the filtered list
                  // We compare by ID because objects might be different instances
                  if (_selectedCategory != null) {
                    final exists = filteredCategories.any((c) => c.id == _selectedCategory!.id);
                    if (!exists) {
                      // If the category doesn't exist in the filtered list (e.g. type mismatch), reset it
                      _selectedCategory = null;
                    } else {
                      // Update _selectedCategory to reference the object from the list
                      // This makes DropdownButton happy (Instance Equality)
                      _selectedCategory = filteredCategories.firstWhere((c) => c.id == _selectedCategory!.id);
                    }
                  }

                  return DropdownButtonFormField<Category>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                    items: filteredCategories.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Row(
                          children: [
                            Icon(IconData(
                              // Basic mapping for now, ideally store proper codepoint/font
                              category.iconCode == 'fastfood' ? 0xe25a : 
                              category.iconCode == 'directions_bus' ? 0xe1d5 :
                              category.iconCode == 'shopping_bag' ? 0xf1cc :
                              category.iconCode == 'payments' ? 0xe481 :
                              category.iconCode == 'work' ? 0xe6f4 :
                              category.iconCode == 'help_outline' ? 0xe887 : 0xe887, // Fallback
                              fontFamily: 'MaterialIcons'
                            )),
                            const SizedBox(width: 10),
                            Text(category.name),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value;
                      });
                    },
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (err, stack) => Text('Error: $err'),
              ),
              const SizedBox(height: 16),

              // 4. Date Picker
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setState(() {
                      _selectedDate = picked;
                    });
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(DateFormat('dd MMM yyyy').format(_selectedDate)),
                ),
              ),
              const SizedBox(height: 16),

              // 5. Note
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Note',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),

              // 6. Save Button
              FilledButton(
                onPressed: _saveTransaction,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Save Transaction', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}