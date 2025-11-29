import 'package:finance_tracker_offline/core/database/db_service.dart';
import 'package:finance_tracker_offline/features/accounts/providers/account_provider.dart';
import 'package:finance_tracker_offline/core/widgets/full_screen_image_viewer.dart';
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
    // Basic validation since we removed the Form wrapping some fields
    if (_amountController.text.isEmpty || double.tryParse(_amountController.text) == null) {
       ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid amount')),
        );
        return;
    }

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

  void _showTypePicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: TransactionType.values.map((type) {
              return ListTile(
                leading: Icon(
                  type == TransactionType.expense ? Icons.arrow_downward :
                  type == TransactionType.income ? Icons.arrow_upward : Icons.swap_horiz
                ),
                title: Text(type.name.toUpperCase()),
                onTap: () {
                  setState(() {
                    _transactionType = type;
                    _selectedCategory = null;
                    if (_transactionType != TransactionType.transfer) {
                      _targetAccount = null;
                    }
                  });
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _showAccountPicker(List<Account> accounts) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return ListView.builder(
          shrinkWrap: true,
          itemCount: accounts.length,
          itemBuilder: (context, index) {
            final account = accounts[index];
            return ListTile(
              title: Text(account.name),
              onTap: () {
                setState(() {
                  _selectedAccount = account;
                  if (_targetAccount?.id == account.id) {
                    _targetAccount = null;
                  }
                });
                Navigator.pop(context);
              },
            );
          },
        );
      },
    );
  }

  void _showTargetAccountPicker(List<Account> accounts) {
     final targetAccounts = accounts.where((a) => a.id != _selectedAccount?.id).toList();
     showModalBottomSheet(
      context: context,
      builder: (context) {
        return ListView.builder(
          shrinkWrap: true,
          itemCount: targetAccounts.length,
          itemBuilder: (context, index) {
            final account = targetAccounts[index];
            return ListTile(
              title: Text(account.name),
              onTap: () {
                setState(() {
                  _targetAccount = account;
                });
                Navigator.pop(context);
              },
            );
          },
        );
      },
    );
  }

  void _showCategoryPicker(List<Category> categories) {
     final isExpense = _transactionType == TransactionType.expense;
     final filteredCategories = categories.where((c) => c.isExpense == isExpense).toList();
     
     showModalBottomSheet(
      context: context,
      builder: (context) {
        return ListView.builder(
          shrinkWrap: true,
          itemCount: filteredCategories.length,
          itemBuilder: (context, index) {
            final category = filteredCategories[index];
            return ListTile(
              leading: Icon(IconData(
                  category.iconCode == 'fastfood' ? 0xe25a : 
                  category.iconCode == 'directions_bus' ? 0xe1d5 :
                  category.iconCode == 'shopping_bag' ? 0xf1cc :
                  category.iconCode == 'payments' ? 0xe481 :
                  category.iconCode == 'work' ? 0xe6f4 :
                  category.iconCode == 'help_outline' ? 0xe887 : 0xe887, // Fallback
                  fontFamily: 'MaterialIcons'
                )),
              title: Text(category.name),
              onTap: () {
                setState(() {
                  _selectedCategory = category;
                });
                Navigator.pop(context);
              },
            );
          },
        );
      },
    );
  }

  void _showNoteEditor() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Note'),
        content: TextFormField(
          controller: _noteController,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Enter note'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {}); // Refresh UI to show new note
            },
            child: const Text('Done'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final accountsAsync = ref.watch(accountsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text('Add Transaction', style: TextStyle(color: Colors.black)),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    // Amount Display
                    Center(
                      child: IntrinsicWidth(
                        child: TextField(
                          controller: _amountController,
                          style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.black),
                          textAlign: TextAlign.center,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: '0',
                            prefixText: '₹ ',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Pills Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Pill 1: Transaction Type
                        GestureDetector(
                          onTap: _showTypePicker,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Text(_transactionType.name.toUpperCase()),
                                const SizedBox(width: 4),
                                const Icon(Icons.arrow_drop_down, size: 20),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Pill 2: Account
                        GestureDetector(
                          onTap: () {
                            accountsAsync.whenData((accounts) => _showAccountPicker(accounts));
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Text(_selectedAccount?.name ?? 'Select Account'),
                                const SizedBox(width: 4),
                                const Icon(Icons.arrow_drop_down, size: 20),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Form Group
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          // Item 1: Category OR Target Account
                          if (_transactionType == TransactionType.transfer)
                             ListTile(
                                leading: const Icon(Icons.account_balance_wallet),
                                title: Text(_targetAccount?.name ?? 'Select Target Account'),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () {
                                   accountsAsync.whenData((accounts) => _showTargetAccountPicker(accounts));
                                },
                             )
                          else
                             ListTile(
                                leading: const Icon(Icons.category),
                                title: Text(_selectedCategory?.name ?? 'Select Category'),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () {
                                   categoriesAsync.whenData((categories) => _showCategoryPicker(categories));
                                },
                             ),
                          
                          const Divider(height: 1),
                          
                          // Item 2: Date
                          ListTile(
                            leading: const Icon(Icons.calendar_today),
                            title: Text(DateFormat('dd MMM yyyy').format(_selectedDate)),
                            trailing: const Icon(Icons.chevron_right),
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
                          ),
                          
                          const Divider(height: 1),
                          
                          // Item 3: Note
                          ListTile(
                            leading: const Icon(Icons.edit),
                            title: Text(_noteController.text.isEmpty ? 'Add Note' : _noteController.text),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: _showNoteEditor,
                          ),

                           const Divider(height: 1),

                           // Item 4: Receipt
                           ListTile(
                            leading: const Icon(Icons.camera_alt),
                            title: Text(_receiptPath == null ? 'Attach Receipt' : 'Receipt Attached'),
                            trailing: _receiptPath == null ? const Icon(Icons.chevron_right) : IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => _receiptPath = null)),
                            onTap: _receiptPath == null ? _pickReceipt : () {
                               Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => FullScreenImageViewer(imagePath: _receiptPath!),
                                ),
                              );
                            },
                           ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Footer
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: _saveTransaction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1C1C1E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Save Expense', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}