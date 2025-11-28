import 'dart:io';
import 'package:finance_tracker_offline/core/database/db_service.dart';
import 'package:finance_tracker_offline/features/accounts/providers/account_provider.dart';
import 'package:finance_tracker_offline/features/add_transaction/providers/category_provider.dart';
import 'package:finance_tracker_offline/features/add_transaction/providers/receipt_provider.dart';
import 'package:finance_tracker_offline/models/account.dart';
import 'package:finance_tracker_offline/models/category.dart';
import 'package:finance_tracker_offline/models/transaction.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

enum TransactionType { income, expense, transfer }

class AddTransactionScreen extends ConsumerStatefulWidget {
  final Transaction? transactionToEdit;

  const AddTransactionScreen({super.key, this.transactionToEdit});

  @override
  ConsumerState<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  TransactionType _transactionType = TransactionType.expense;
  late DateTime _selectedDate;
  Category? _selectedCategory;
  Account? _selectedAccount;
  Account? _targetAccount;
  String? _receiptPath;
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize state based on whether we are editing or creating
    if (widget.transactionToEdit != null) {
      final txn = widget.transactionToEdit!;
      if (txn.isTransfer) {
        _transactionType = TransactionType.transfer;
        _targetAccount = txn.transferAccount.value;
      } else {
        _transactionType = txn.isExpense ? TransactionType.expense : TransactionType.income;
      }
      _selectedDate = txn.date;
      _amountController.text = txn.amount.toString();
      _noteController.text = txn.note;
      _selectedCategory = txn.category.value;
      _selectedAccount = txn.account.value;
      _receiptPath = txn.receiptPath;
    } else {
      _transactionType = TransactionType.expense;
      _selectedDate = DateTime.now();
    }
  }

  Future<void> _pickReceipt() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () async {
                Navigator.pop(context);
                final path = await ref.read(receiptServiceProvider).pickReceipt(ImageSource.camera);
                if (path != null) {
                  setState(() => _receiptPath = path);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () async {
                Navigator.pop(context);
                final path = await ref.read(receiptServiceProvider).pickReceipt(ImageSource.gallery);
                if (path != null) {
                  setState(() => _receiptPath = path);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _saveTransaction() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedAccount == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an account')),
        );
        return;
      }

      if (_transactionType == TransactionType.transfer) {
        if (_targetAccount == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a target account')),
          );
          return;
        }
        if (_selectedAccount!.id == _targetAccount!.id) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Source and Target accounts cannot be the same')),
          );
          return;
        }
      } else {
        if (_selectedCategory == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a category')),
          );
          return;
        }
      }

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
        txn.isExpense = _transactionType == TransactionType.expense || _transactionType == TransactionType.transfer;
        txn.isTransfer = _transactionType == TransactionType.transfer;
        txn.date = _selectedDate;
        txn.note = _noteController.text;
        txn.receiptPath = _receiptPath;
        txn.category.value = _selectedCategory;
        txn.account.value = _selectedAccount;
        if (_transactionType == TransactionType.transfer) {
          txn.transferAccount.value = _targetAccount;
        }

        await dbService.updateTransaction(
          txn,
          oldAmount: oldAmount,
          oldIsExpense: oldIsExpense,
          oldAccount: oldAccount,
        );
      } else {
        // CREATE New
        if (_transactionType == TransactionType.transfer) {
          await dbService.addTransfer(
            _selectedAccount!,
            _targetAccount!,
            amount,
            _selectedDate,
            _noteController.text,
            receiptPath: _receiptPath,
          );
        } else {
          final txn = Transaction()
            ..amount = amount
            ..isExpense = _transactionType == TransactionType.expense
            ..date = _selectedDate
            ..note = _noteController.text
            ..receiptPath = _receiptPath;
          
          txn.category.value = _selectedCategory;
          txn.account.value = _selectedAccount;
          
          await dbService.addTransaction(txn);
        }
      }

      if (mounted) {
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final accountsAsync = ref.watch(accountsProvider);

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
              SegmentedButton<TransactionType>(
                segments: const [
                  ButtonSegment(value: TransactionType.expense, label: Text('Expense'), icon: Icon(Icons.arrow_downward)),
                  ButtonSegment(value: TransactionType.income, label: Text('Income'), icon: Icon(Icons.arrow_upward)),
                  ButtonSegment(value: TransactionType.transfer, label: Text('Transfer'), icon: Icon(Icons.swap_horiz)),
                ],
                selected: {_transactionType},
                onSelectionChanged: (Set<TransactionType> newSelection) {
                  setState(() {
                    _transactionType = newSelection.first;
                    _selectedCategory = null; // Reset category when switching type
                    if (_transactionType != TransactionType.transfer) {
                      _targetAccount = null;
                    }
                  });
                },
              ),
              const SizedBox(height: 24),

              // 2. Account Dropdown (Source)
              accountsAsync.when(
                data: (accounts) {
                  if (accounts.isEmpty) {
                    return const Text('No accounts available. Please add an account first.');
                  }
                  
                  // Ensure selected account is valid and matches the instance in the list
                  if (_selectedAccount != null) {
                    final exists = accounts.any((a) => a.id == _selectedAccount!.id);
                    if (!exists) {
                      _selectedAccount = null;
                    } else {
                      // Update _selectedAccount to reference the object from the list
                      _selectedAccount = accounts.firstWhere((a) => a.id == _selectedAccount!.id);
                    }
                  }
                  
                  // Default to first account if null and adding new
                  if (_selectedAccount == null && widget.transactionToEdit == null) {
                    _selectedAccount = accounts.first;
                  }

                  return DropdownButtonFormField<Account>(
                    value: _selectedAccount,
                    decoration: const InputDecoration(
                      labelText: 'Paying from',
                      border: OutlineInputBorder(),
                    ),
                    items: accounts.map((account) {
                      return DropdownMenuItem(
                        value: account,
                        child: Text(account.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedAccount = value;
                        // Reset target account if it matches the new source account
                        if (_targetAccount?.id == value?.id) {
                          _targetAccount = null;
                        }
                      });
                    },
                    validator: (value) => value == null ? 'Please select an account' : null,
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (err, stack) => Text('Error loading accounts: $err'),
              ),
              const SizedBox(height: 16),

              // 3. Amount
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

              // 4. Category OR Target Account
              if (_transactionType == TransactionType.transfer)
                accountsAsync.when(
                  data: (accounts) {
                    // Filter out the selected source account
                    final targetAccounts = accounts.where((a) => a.id != _selectedAccount?.id).toList();

                    // Ensure selected target account is valid and matches the instance in the list
                    if (_targetAccount != null) {
                      final exists = targetAccounts.any((a) => a.id == _targetAccount!.id);
                      if (!exists) {
                        _targetAccount = null;
                      } else {
                        // Update _targetAccount to reference the object from the list
                        _targetAccount = targetAccounts.firstWhere((a) => a.id == _targetAccount!.id);
                      }
                    }

                    return DropdownButtonFormField<Account>(
                      value: _targetAccount,
                      decoration: const InputDecoration(
                        labelText: 'Transfer to',
                        border: OutlineInputBorder(),
                      ),
                      items: targetAccounts.map((account) {
                        return DropdownMenuItem(
                          value: account,
                          child: Text(account.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _targetAccount = value;
                        });
                      },
                      validator: (value) => value == null ? 'Please select target account' : null,
                    );
                  },
                  loading: () => const SizedBox(),
                  error: (_, __) => const SizedBox(),
                )
              else
                categoriesAsync.when(
                  data: (allCategories) {
                    // Filter categories by type
                    final isExpense = _transactionType == TransactionType.expense;
                    final filteredCategories = allCategories
                        .where((c) => c.isExpense == isExpense)
                        .toList();

                    // FIX: Ensure selected category is valid in the filtered list
                    if (_selectedCategory != null) {
                      final exists = filteredCategories.any((c) => c.id == _selectedCategory!.id);
                      if (!exists) {
                        _selectedCategory = null;
                      } else {
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
                      validator: (value) => value == null ? 'Please select a category' : null,
                    );
                  },
                  loading: () => const LinearProgressIndicator(),
                  error: (err, stack) => Text('Error: $err'),
                ),
              const SizedBox(height: 16),

              // 5. Date Picker
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

              // 6. Note
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Note',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // 7. Receipt Attachment
              if (_receiptPath == null)
                TextButton.icon(
                  onPressed: _pickReceipt,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Attach Receipt'),
                )
              else
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(_receiptPath!),
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _receiptPath = null;
                        });
                      },
                      icon: const Icon(Icons.close),
                      tooltip: 'Remove Receipt',
                    ),
                  ],
                ),
              const SizedBox(height: 24),

              // 8. Save Button
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