import 'package:flutter/material.dart';
import 'package:fintrack/features/category/data/datasource/category_remote_datasource.dart';
import 'package:fintrack/features/category/data/models/category_item_model.dart';
import 'package:fintrack/features/tag/data/datasource/tag_remote_datasource.dart';
import 'package:fintrack/features/tag/data/models/request/tag_request_model.dart';
import 'package:fintrack/features/tag/data/models/response/tag_item_model.dart';
import 'package:fintrack/features/transaction/data/datasource/transactions_remote_datasource.dart';
import 'package:fintrack/features/transaction/data/models/request/transaction_request_model.dart';
import 'package:fintrack/features/transaction/data/models/response/transaction_detail_response_model.dart';
import 'package:intl/intl.dart';
import 'package:fintrack/features/wallet/data/datasource/wallet_remote_datasource.dart';
import 'package:fintrack/features/wallet/data/models/response/list_wallet_response_model.dart';
import 'package:fintrack/core/config/color.dart';
import 'package:dartz/dartz.dart' hide State;
import 'package:collection/collection.dart';
import 'package:flutter/services.dart';

class AddEditTransactionPage extends StatefulWidget {
  final VoidCallback? onTransactionChanged;
  final TransactionDetailResponseModel? transactionToEdit;

  const AddEditTransactionPage({
    super.key,
    this.onTransactionChanged,
    this.transactionToEdit,
  });

  @override
  State<AddEditTransactionPage> createState() => _AddEditTransactionPageState();
}

class _AddEditTransactionPageState extends State<AddEditTransactionPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TransactionRemoteDatasource _transactionDatasource =
      TransactionRemoteDatasource();
  final WalletRemoteDatasource _walletDatasource = WalletRemoteDatasource();
  final CategoryRemoteDatasource _categoryDatasource =
      CategoryRemoteDatasource();
  final TagRemoteDatasource _tagDatasource = TagRemoteDatasource();

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _tagsDisplayController = TextEditingController();

  String _transactionType = 'expense';
  int? _selectedWalletId;
  int? _selectedCategoryId;
  DateTime _selectedDate = DateTime.now();
  List<int> _selectedTagIds = [];
  List<String> _selectedTagNames = [];

  List<Result> _wallets = [];
  List<CategoryItemModel> _categories = [];
  List<TagItemModel> _availableTags = [];
  bool _isLoadingDropdownData = true;
  bool _isSaving = false;
  bool _isDeleting = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeInOut);
    _animController.forward();
    _initializeFormForEdit();
    _fetchDropdownData().then((_) {
      if (widget.transactionToEdit != null && mounted) {
        setState(() {
          _ensureSelectedIdsAreValid();
        });
      }
    });
  }

  void _initializeFormForEdit() {
    if (widget.transactionToEdit != null) {
      final transaction = widget.transactionToEdit!;
      _amountController.text = transaction.amount ?? '';
      _descriptionController.text = transaction.description ?? '';
      _transactionType = transaction.type ?? 'expense';
      _selectedDate =
          DateTime.tryParse(transaction.transactionDate ?? '') ??
          DateTime.now();

      _selectedWalletId = transaction.wallet;
      _selectedCategoryId = transaction.category;

      _selectedTagIds = transaction.tagIds ?? [];
      _selectedTagNames =
          transaction.tags?.map((t) => t.tagName ?? '').toList() ?? [];
      _tagsDisplayController.text = _selectedTagNames.join(', ');
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    _tagsDisplayController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> _fetchDropdownData() async {
    if (!mounted) return;
    setState(() {
      _isLoadingDropdownData = true;
    });

    await Future.wait([_fetchWallets(), _fetchCategories(), _fetchTags()]);

    if (!mounted) return;
    setState(() {
      _isLoadingDropdownData = false;
      _ensureSelectedIdsAreValid();
    });
  }

  void _ensureSelectedIdsAreValid() {
    if (widget.transactionToEdit != null) {
      if (_selectedWalletId != null &&
          !_wallets.any((w) => w.id == _selectedWalletId)) {
        _selectedWalletId = null;
      }
      if (_selectedCategoryId != null &&
          !_categories.any((c) => c.id == _selectedCategoryId)) {
        _selectedCategoryId = null;
      }

      if (_selectedWalletId == null &&
          widget.transactionToEdit!.wallet != null) {
        _selectedWalletId =
            _wallets
                .firstWhereOrNull(
                  (w) => w.id == widget.transactionToEdit!.wallet,
                )
                ?.id;
      }
      if (_selectedCategoryId == null &&
          widget.transactionToEdit!.category != null) {
        _selectedCategoryId =
            _categories
                .firstWhereOrNull(
                  (c) => c.id == widget.transactionToEdit!.category,
                )
                ?.id;
      }
    } else {
      if (_selectedWalletId == null && _wallets.isNotEmpty) {
        _selectedWalletId = _wallets.first.id;
      }
      if (_selectedCategoryId == null && _categories.isNotEmpty) {
        _selectedCategoryId = _categories.first.id;
      }
    }
  }

  Future<void> _fetchWallets() async {
    final walletResult = await _walletDatasource.getWallet();
    walletResult.fold(
      (error) {
        print('Error fetching wallets for dropdown: $error');
        _showSnackBar('Error loading wallets: $error', isError: true);
      },
      (data) {
        if (!mounted) return;
        setState(() {
          _wallets =
              data.results?.where((wallet) => wallet.id != null).toList() ?? [];
        });
      },
    );
  }

  Future<void> _fetchCategories() async {
    final categoryResult = await _categoryDatasource.getCategories();
    categoryResult.fold(
      (error) {
        print('Error fetching categories for dropdown: $error');
        _showSnackBar('Error loading categories: $error', isError: true);
      },
      (data) {
        if (!mounted) return;
        setState(() {
          _categories =
              data.results?.where((category) => category.id != null).toList() ??
              [];
        });
      },
    );
  }

  Future<void> _fetchTags() async {
    final tagResult = await _tagDatasource.getTags();
    tagResult.fold(
      (error) {
        print('Error fetching tags for dropdown: $error');
        _showSnackBar('Error loading tags: $error', isError: true);
      },
      (data) {
        if (!mounted) return;
        setState(() {
          _availableTags = data.results ?? [];
        });
      },
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      if (!mounted) return;
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _showTagSelectionSheet() async {
    List<int> currentSelectedTagIds = List.from(_selectedTagIds);
    List<String> currentSelectedTagNames = List.from(_selectedTagNames);

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                child: Scaffold(
                  appBar: AppBar(
                    title: const Text('Select Tags'),
                    backgroundColor: ColorsApp.primary,
                    foregroundColor: Colors.white,
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () async {
                          final newTagName = await _showAddTagDialog(context);
                          if (newTagName != null && newTagName.isNotEmpty) {
                            final createResult = await _tagDatasource.createTag(
                              TagRequestModel(name: newTagName),
                            );
                            createResult.fold(
                              (error) {
                                _showSnackBar(
                                  'Failed to add tag: $error',
                                  isError: true,
                                );
                              },
                              (successMessage) async {
                                _showSnackBar(successMessage);
                                await _fetchTags();
                                setModalState(() {});
                              },
                            );
                          }
                        },
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop({
                            'ids': currentSelectedTagIds,
                            'names': currentSelectedTagNames,
                          });
                        },
                        child: const Text(
                          'Done',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  body:
                      _availableTags.isEmpty && _isLoadingDropdownData
                          ? const Center(child: CircularProgressIndicator())
                          : _availableTags.isEmpty
                          ? const Center(
                            child: Text(
                              'No tags available. Tap "+" to add one!',
                            ),
                          )
                          : ListView.builder(
                            itemCount: _availableTags.length,
                            itemBuilder: (context, index) {
                              final tag = _availableTags[index];
                              final isSelected = currentSelectedTagIds.contains(
                                tag.id,
                              );
                              return CheckboxListTile(
                                title: Text(tag.name ?? 'Unknown Tag'),
                                value: isSelected,
                                onChanged: (bool? value) {
                                  if (tag.id == null) return;
                                  setModalState(() {
                                    if (value == true) {
                                      currentSelectedTagIds.add(tag.id!);
                                      currentSelectedTagNames.add(
                                        tag.name ?? 'Unknown Tag',
                                      );
                                    } else {
                                      currentSelectedTagIds.remove(tag.id!);
                                      currentSelectedTagNames.remove(
                                        tag.name ?? 'Unknown Tag',
                                      );
                                    }
                                  });
                                },

                                secondary: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, size: 20),
                                      onPressed: () async {
                                        await _editTagDialog(
                                          tag,
                                          setModalState,
                                        );
                                      },
                                      tooltip: 'Edit Tag',
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        size: 20,
                                        color: Colors.red,
                                      ),
                                      onPressed: () async {
                                        await _deleteTagDialog(
                                          tag,
                                          setModalState,
                                        );
                                      },
                                      tooltip: 'Delete Tag',
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                ),
              ),
            );
          },
        );
      },
    );

    if (result != null) {
      if (!mounted) return;
      setState(() {
        _selectedTagIds = result['ids'];
        _selectedTagNames = result['names'];
        _tagsDisplayController.text = _selectedTagNames.join(', ');
      });
    }
  }

  Future<String?> _showAddTagDialog(BuildContext context) async {
    String? newTagName;
    return showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Add New Tag'),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Tag Name'),
            onChanged: (value) {
              newTagName = value;
            },
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text('Add'),
              onPressed: () {
                Navigator.of(dialogContext).pop(newTagName);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _editTagDialog(
    TagItemModel tag,
    StateSetter setModalState,
  ) async {
    String? newTagName = tag.name;
    final TextEditingController tagEditController = TextEditingController(
      text: tag.name,
    );

    final bool? confirmEdit = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Edit Tag'),
          content: TextField(
            controller: tagEditController,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'New Tag Name'),
            onChanged: (value) {
              newTagName = value;
            },
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
            ),
            TextButton(
              child: const Text('Save'),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (confirmEdit == true &&
        (newTagName?.isNotEmpty ?? false) &&
        newTagName != tag.name) {
      if (!mounted) return;
      final result = await _tagDatasource.updateTag(
        tag.id!,
        TagRequestModel(name: newTagName!),
      );

      result.fold(
        (error) {
          _showSnackBar('Failed to update tag: $error', isError: true);
        },
        (successMessage) async {
          _showSnackBar(successMessage);
          await _fetchTags();
          if (_selectedTagIds.contains(tag.id)) {
            setState(() {
              int index = _selectedTagNames.indexOf(tag.name ?? '');
              if (index != -1) {
                _selectedTagNames[index] = newTagName!;
              } else {
                _selectedTagNames.add(newTagName!);
              }
              _tagsDisplayController.text = _selectedTagNames.join(', ');
            });
          }
          setModalState(() {});
        },
      );
    }
    tagEditController.dispose();
  }

  Future<void> _deleteTagDialog(
    TagItemModel tag,
    StateSetter setModalState,
  ) async {
    final bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Tag'),
          content: Text(
            'Are you sure you want to delete "${tag.name}"? This cannot be undone and will remove it from all transactions.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      if (!mounted) return;
      final result = await _tagDatasource.deleteTag(tag.id!);

      result.fold(
        (error) {
          _showSnackBar('Failed to delete tag: $error', isError: true);
        },
        (successMessage) async {
          _showSnackBar(successMessage);
          await _fetchTags();
          setState(() {
            _selectedTagIds.remove(tag.id);
            _selectedTagNames.remove(tag.name);
            _tagsDisplayController.text = _selectedTagNames.join(', ');
          });
          setModalState(() {});
        },
      );
    }
  }

  void _saveTransaction() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedWalletId == null || _selectedCategoryId == null) {
      _showSnackBar('Please select a wallet and category.', isError: true);
      return;
    }

    if (!mounted) return;
    setState(() {
      _isSaving = true;
    });

    final transactionRequest = TransactionRequestModel(
      wallet: _selectedWalletId!,
      category: _selectedCategoryId!,
      amount: _amountController.text,
      type: _transactionType,
      description: _descriptionController.text,
      transactionDate: DateFormat('yyyy-MM-dd').format(_selectedDate),
      tagIds: _selectedTagIds.isEmpty ? null : _selectedTagIds,
    );

    Either<String, String> result;
    if (widget.transactionToEdit == null) {
      result = await _transactionDatasource.createTransaction(
        transactionRequest,
      );
    } else {
      result = await _transactionDatasource.updateTransaction(
        widget.transactionToEdit!.id!,
        transactionRequest,
      );
    }

    if (!mounted) return;
    setState(() {
      _isSaving = false;
    });

    result.fold(
      (error) {
        print('Transaction save error: $error');
        _showSnackBar('Failed to save transaction: $error', isError: true);
      },
      (successMessage) {
        print('Transaction save success: $successMessage');
        _showSnackBar(successMessage);
        Navigator.of(context).pop();
        widget.onTransactionChanged?.call();
      },
    );
  }

  Future<void> _deleteTransaction() async {
    if (widget.transactionToEdit == null ||
        widget.transactionToEdit!.id == null) {
      _showSnackBar('Transaction ID is missing for deletion.', isError: true);
      return;
    }

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Transaction'),
          content: Text(
            'Are you sure you want to delete this transaction (amount: ${widget.transactionToEdit!.amount})? This action cannot be undone.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      if (!mounted) return;
      setState(() {
        _isDeleting = true;
      });

      final result = await _transactionDatasource.deleteTransaction(
        widget.transactionToEdit!.id!,
      );

      if (!mounted) return;
      setState(() {
        _isDeleting = false;
      });

      result.fold(
        (error) {
          print('Error deleting transaction: $error');
          _showSnackBar('Failed to delete transaction: $error', isError: true);
        },
        (_) {
          print('Transaction deleted successfully!');
          _showSnackBar('Transaction deleted successfully!');
          Navigator.of(context).pop();
          widget.onTransactionChanged?.call();
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.dark,
        ),
        title: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(
            widget.transactionToEdit == null
                ? 'Add Transaction'
                : 'Edit Transaction',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        toolbarHeight: kToolbarHeight + 20,
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: true,
        leading: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: ColorsApp.primary),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ),
        actions: [
          if (widget.transactionToEdit != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: AnimatedBuilder(
                animation: _fadeAnim,
                builder: (context, child) => Transform.scale(
                  scale: 0.95 + 0.05 * _fadeAnim.value,
                  child: Opacity(opacity: _fadeAnim.value, child: child),
                ),
                child: IconButton(
                  icon: _isDeleting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.red,
                            ),
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.delete, color: Colors.red),
                  onPressed: _isDeleting ? null : _deleteTransaction,
                  tooltip: 'Delete Transaction',
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: AnimatedBuilder(
              animation: _fadeAnim,
              builder: (context, child) => Transform.scale(
                scale: 0.95 + 0.05 * _fadeAnim.value,
                child: Opacity(opacity: _fadeAnim.value, child: child),
              ),
              child: IconButton(
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.save, color: ColorsApp.primary),
                onPressed:
                    _isSaving || _isLoadingDropdownData ? null : _saveTransaction,
                tooltip: 'Save Transaction',
              ),
            ),
          ),
        ],
      ),
      body: _isLoadingDropdownData
          ? const Center(child: CircularProgressIndicator())
          : FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(_fadeAnim),
                child: Center(
                  child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: SingleChildScrollView(
                        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildTypePill('Expense', 'expense'),
                                  const SizedBox(width: 10),
                                  _buildTypePill('Income', 'income'),
                                ],
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _amountController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Amount',
                                  prefixIcon: Icon(Icons.attach_money, color: ColorsApp.primary),
                                  prefixText: 'Rp ',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Amount cannot be empty';
                                  }
                                  if (double.tryParse(value) == null) {
                                    return 'Enter a valid number';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              DropdownButtonFormField<int>(
                                value: _selectedCategoryId,
                                items: _categories.where((c) => c.id != null).map((category) {
                                  return DropdownMenuItem<int>(
                                    value: category.id!,
                                    child: Row(
                                      children: [
                                        Icon(Icons.category, color: ColorsApp.primary),
                                        const SizedBox(width: 8),
                                        Text(category.name ?? ''),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (!mounted) return;
                                  setState(() {
                                    _selectedCategoryId = value;
                                  });
                                },
                                decoration: InputDecoration(
                                  labelText: 'Category',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                                validator: (value) {
                                  if (value == null) {
                                    return 'Please select a category';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              DropdownButtonFormField<int>(
                                value: _selectedWalletId,
                                items: _wallets.where((w) => w.id != null).map((wallet) {
                                  return DropdownMenuItem<int>(
                                    value: wallet.id!,
                                    child: Row(
                                      children: [
                                        Icon(Icons.account_balance_wallet, color: ColorsApp.primary),
                                        const SizedBox(width: 8),
                                        Text(wallet.name ?? ''),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (!mounted) return;
                                  setState(() {
                                    _selectedWalletId = value;
                                  });
                                },
                                decoration: InputDecoration(
                                  labelText: 'Wallet',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                                validator: (value) {
                                  if (value == null) {
                                    return 'Please select a wallet';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: TextEditingController(
                                  text: DateFormat('dd/MM/yyyy').format(_selectedDate),
                                ),
                                readOnly: true,
                                onTap: () => _selectDate(context),
                                decoration: InputDecoration(
                                  labelText: 'Date',
                                  suffixIcon: Icon(Icons.calendar_today, color: ColorsApp.primary),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _descriptionController,
                                maxLines: 3,
                                decoration: InputDecoration(
                                  labelText: 'Description',
                                  hintText: 'Add note (optional)',
                                  prefixIcon: Icon(Icons.description, color: ColorsApp.primary),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _tagsDisplayController,
                                readOnly: true,
                                onTap: _showTagSelectionSheet,
                                decoration: InputDecoration(
                                  labelText: 'Tags',
                                  hintText: 'Select tags (optional)',
                                  prefixIcon: Icon(Icons.label, color: ColorsApp.primary),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                                  suffixIcon: IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: _showTagSelectionSheet,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Flexible(
                                    child: AnimatedBuilder(
                                      animation: _fadeAnim,
                                      builder: (context, child) => Transform.scale(
                                        scale: 0.95 + 0.05 * _fadeAnim.value,
                                        child: Opacity(opacity: _fadeAnim.value, child: child),
                                      ),
                                      child: TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        child: Text(
                                          'Cancel',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.red,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Flexible(
                                    child: AnimatedBuilder(
                                      animation: _fadeAnim,
                                      builder: (context, child) => Transform.scale(
                                        scale: 0.95 + 0.05 * _fadeAnim.value,
                                        child: Opacity(opacity: _fadeAnim.value, child: child),
                                      ),
                                      child: TextButton(
                                        onPressed: _isSaving || _isLoadingDropdownData ? null : _saveTransaction,
                                        child: Text(
                                          widget.transactionToEdit != null ? 'Update' : 'Save',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: ColorsApp.primary,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildTypePill(String text, String type) {
    final bool selected = _transactionType == type;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: ChoiceChip(
          label: Text(text, style: TextStyle(fontWeight: FontWeight.bold, color: selected ? Colors.white : Colors.black)),
          selected: selected,
          selectedColor: ColorsApp.primary,
          backgroundColor: Colors.grey[200],
          onSelected: (val) {
            setState(() {
              _transactionType = type;
            });
          },
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          labelPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        ),
      ),
    );
  }
}
