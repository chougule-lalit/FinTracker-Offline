import 'package:finance_tracker_offline/core/database/db_service.dart';
import 'package:finance_tracker_offline/features/accounts/providers/account_provider.dart';
import 'package:finance_tracker_offline/core/widgets/full_screen_image_viewer.dart';
import 'package:finance_tracker_offline/features/add_transaction/providers/category_provider.dart';
import 'package:finance_tracker_offline/features/add_transaction/providers/receipt_provider.dart';
import 'package:finance_tracker_offline/models/account.dart';
import 'package:finance_tracker_offline/models/category.dart';
import 'package:finance_tracker_offline/models/transaction.dart';
import 'package:finance_tracker_offline/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
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

  Widget _buildTransactionTypeSelector() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? AppColors.primaryBlack;

    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(100),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final segmentWidth = constraints.maxWidth / 3;
          final selectedIndex = _transactionType == TransactionType.expense
              ? 0
              : _transactionType == TransactionType.income
                  ? 1
                  : 2;

          return Stack(
            children: [
              // Layer 2 (Active Indicator)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                left: segmentWidth * selectedIndex,
                top: 0,
                bottom: 0,
                width: segmentWidth,
                child: Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.brandBeige : AppColors.brandDark,
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ),
              // Layer 3 (Text/Icons)
              Row(
                children: [
                  _buildSelectorItem(TransactionType.expense, 'Expense', isDark, textColor),
                  _buildSelectorItem(TransactionType.income, 'Income', isDark, textColor),
                  _buildSelectorItem(TransactionType.transfer, 'Transfer', isDark, textColor),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSelectorItem(TransactionType type, String label, bool isDark, Color textColor) {
    final isSelected = _transactionType == type;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          setState(() {
            _transactionType = type;
            _selectedCategory = null;
            if (_transactionType != TransactionType.transfer) {
              _targetAccount = null;
            }
          });
        },
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: isSelected ? (isDark ? AppColors.brandDark : Colors.white) : textColor,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final accountsAsync = ref.watch(accountsProvider);
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? AppColors.primaryBlack;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Text('Add Transaction', style: GoogleFonts.poppins(color: textColor, fontWeight: FontWeight.w600)),
        iconTheme: IconThemeData(color: textColor),
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
                          style: GoogleFonts.poppins(fontSize: 48, fontWeight: FontWeight.bold, color: textColor),
                          textAlign: TextAlign.center,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: '0',
                            prefixText: '₹ ',
                            hintStyle: GoogleFonts.poppins(color: AppColors.secondaryGrey),
                            prefixStyle: GoogleFonts.poppins(color: textColor, fontSize: 48, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Segmented Control for Transaction Type
                    _buildTransactionTypeSelector(),
                    
                    const SizedBox(height: 16),

                    // Account Selector
                    GestureDetector(
                      onTap: () {
                        accountsAsync.whenData((accounts) => _showAccountPicker(accounts));
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardTheme.color,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.account_balance_wallet, color: textColor),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _selectedAccount?.name ?? 'Select Account',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                              ),
                            ),
                            Icon(Icons.arrow_drop_down, color: textColor),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Form Group
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          // Item 1: Category OR Target Account
                          if (_transactionType == TransactionType.transfer)
                             ListTile(
                                leading: Icon(Icons.account_balance_wallet, color: textColor),
                                title: Text(_targetAccount?.name ?? 'Select Target Account', style: GoogleFonts.poppins(color: textColor)),
                                trailing: const Icon(Icons.chevron_right, color: AppColors.secondaryGrey),
                                onTap: () {
                                   accountsAsync.whenData((accounts) => _showTargetAccountPicker(accounts));
                                },
                             )
                          else
                             ListTile(
                                leading: Icon(Icons.category, color: textColor),
                                title: Text(_selectedCategory?.name ?? 'Select Category', style: GoogleFonts.poppins(color: textColor)),
                                trailing: const Icon(Icons.chevron_right, color: AppColors.secondaryGrey),
                                onTap: () {
                                   categoriesAsync.whenData((categories) => _showCategoryPicker(categories));
                                },
                             ),
                          
                          const Divider(height: 1, color: AppColors.divider),
                          
                          // Item 2: Date
                          ListTile(
                            leading: Icon(Icons.calendar_today, color: textColor),
                            title: Text(DateFormat('dd MMM yyyy').format(_selectedDate), style: GoogleFonts.poppins(color: textColor)),
                            trailing: const Icon(Icons.chevron_right, color: AppColors.secondaryGrey),
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
                          
                          const Divider(height: 1, color: AppColors.divider),
                          
                          // Item 3: Note
                          ListTile(
                            leading: Icon(Icons.edit, color: textColor),
                            title: Text(_noteController.text.isEmpty ? 'Add Note' : _noteController.text, style: GoogleFonts.poppins(color: textColor)),
                            trailing: const Icon(Icons.chevron_right, color: AppColors.secondaryGrey),
                            onTap: _showNoteEditor,
                          ),

                           const Divider(height: 1, color: AppColors.divider),

                           // Item 4: Receipt
                           ListTile(
                            leading: Icon(Icons.camera_alt, color: textColor),
                            title: Text(_receiptPath == null ? 'Attach Receipt' : 'Receipt Attached', style: GoogleFonts.poppins(color: textColor)),
                            trailing: _receiptPath == null ? const Icon(Icons.chevron_right, color: AppColors.secondaryGrey) : IconButton(icon: Icon(Icons.close, color: textColor), onPressed: () => setState(() => _receiptPath = null)),
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
                  backgroundColor: AppColors.brandRed,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: const StadiumBorder(),
                ),
                child: Text('Save Expense', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}