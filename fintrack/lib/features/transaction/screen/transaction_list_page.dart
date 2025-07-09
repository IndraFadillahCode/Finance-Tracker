import 'package:flutter/material.dart';
import 'package:fintrack/core/config/color.dart';
import 'package:fintrack/features/transaction/data/datasource/transactions_remote_datasource.dart';
import 'package:fintrack/features/transaction/data/models/response/transaction_item_model.dart';
import 'package:fintrack/features/transaction/screen/add_edit_transaction_page.dart';
import 'package:fintrack/features/transaction/data/models/response/transaction_detail_response_model.dart';
import 'package:fintrack/utils/category_helpers.dart';
import 'package:intl/intl.dart';

class TransactionListPage extends StatefulWidget {
  final int? categoryId;  
  final String? categoryName;
  final String? transactionType;

  const TransactionListPage({
    super.key,
    this.categoryId,
    this.categoryName,
    this.transactionType,
  });

  @override
  State<TransactionListPage> createState() => _TransactionListPageState();
}

class _TransactionListPageState extends State<TransactionListPage> {
  final TransactionRemoteDatasource _transactionDatasource =
      TransactionRemoteDatasource();

  Map<String, List<TransactionItemModel>> _groupedTransactions = {};
  List<String> _sortedGroupKeys = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedFilterType = 'all';

  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _currentSearchQuery = '';

  DateTime? _filterStartDate;
  DateTime? _filterEndDate;

  @override
  void initState() {
    super.initState();
    if (widget.transactionType != null && widget.transactionType!.isNotEmpty) {
      _selectedFilterType = widget.transactionType!;
    }
    _fetchTransactions();

    _searchController.addListener(() {
      if (_searchController.text != _currentSearchQuery) {
        setState(() {
          _currentSearchQuery = _searchController.text;
        });
        _fetchTransactions();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
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

  Future<void> _fetchTransactions() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _groupedTransactions = {};
      _sortedGroupKeys = [];
    });
    final result = await _transactionDatasource.getTransactions(
      type: _selectedFilterType == 'all' ? null : _selectedFilterType,
      categoryId: widget.categoryId,
      startDate:
          _filterStartDate != null
              ? DateFormat('yyyy-MM-dd').format(_filterStartDate!)
              : null,
      endDate:
          _filterEndDate != null
              ? DateFormat('yyyy-MM-dd').format(_filterEndDate!)
              : null,
    );

    if (!mounted) return;

    result.fold(
      (error) {
        print('Error fetching transactions: $error');
        setState(() {
          _errorMessage = 'Failed to load transactions: $error';
          _isLoading = false;
        });
        _showSnackBar('Error loading transactions: $error', isError: true);
      },
      (data) {
        if (mounted) {
          setState(() {
            List<TransactionItemModel> transactionsToFilter =
                data.results ?? [];

            if (_currentSearchQuery.isNotEmpty) {
              transactionsToFilter =
                  transactionsToFilter.where((t) {
                    final query = _currentSearchQuery.toLowerCase();
                    return (t.description?.toLowerCase().contains(query) ??
                            false) ||
                        (t.categoryName?.toLowerCase().contains(query) ??
                            false) ||
                        (t.walletName?.toLowerCase().contains(query) ??
                            false) ||
                        (t.tags?.any(
                              (tag) =>
                                  tag.tagName?.toLowerCase().contains(query) ??
                                  false,
                            ) ??
                            false);
                  }).toList();
            }

            _groupedTransactions = _groupTransactionsByDate(
              transactionsToFilter,
            );
            _sortedGroupKeys =
                _groupedTransactions.keys.toList()..sort((a, b) {
                  if (a == "Today") return -1;
                  if (b == "Today") return 1;
                  if (a == "Yesterday" && b != "Today") return -1;
                  if (b == "Yesterday" && a != "Today") return 1;

                  try {
                    DateTime dateA = DateFormat('MMM d,yyyy', 'en_US').parse(a);
                    DateTime dateB = DateFormat('MMM d,yyyy', 'en_US').parse(b);
                    return dateB.compareTo(dateA);
                  } catch (e) {
                    print(
                      'Warning: Failed to parse date string for sorting: $e - $a vs $b',
                    );
                    return a.compareTo(b);
                  }
                });
            _isLoading = false;
          });
          print('Transactions loaded: ${data.results?.length ?? 0} items');
        }
      },
    );
  }

  Map<String, List<TransactionItemModel>> _groupTransactionsByDate(
    List<TransactionItemModel> transactions,
  ) {
    Map<String, List<TransactionItemModel>> grouped = {};
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    DateTime yesterday = DateTime(now.year, now.month, now.day - 1);

    transactions.sort((a, b) {
      DateTime? dateA = DateTime.tryParse(a.transactionDate ?? '');
      DateTime? dateB = DateTime.tryParse(b.transactionDate ?? '');
      if (dateA == null || dateB == null) return 0;
      return dateB.compareTo(dateA);
    });

    for (var transaction in transactions) {
      if (transaction.transactionDate == null ||
          transaction.transactionDate!.isEmpty)
        continue;

      DateTime? transactionDate = DateTime.tryParse(
        transaction.transactionDate!,
      );

      if (transactionDate == null) {
        print(
          'Warning: Failed to parse transaction date: ${transaction.transactionDate}',
        );
        continue;
      }

      String groupKey;
      if (transactionDate.year == today.year &&
          transactionDate.month == today.month &&
          transactionDate.day == today.day) {
        groupKey = "Today";
      } else if (transactionDate.year == yesterday.year &&
          transactionDate.month == yesterday.month &&
          transactionDate.day == yesterday.day) {
        groupKey = "Yesterday";
      } else {
        groupKey = DateFormat('MMM d,yyyy', 'en_US').format(transactionDate);
      }

      if (!grouped.containsKey(groupKey)) {
        grouped[groupKey] = [];
      }
      grouped[groupKey]!.add(transaction);
    }
    return grouped;
  }

  Color _getAmountColor(String? type) {
    if (type == 'expense') {
      return Colors.red;
    } else if (type == 'income') {
      return Colors.green;
    } else if (type == 'transfer') {
      return Colors.blue;
    }
    return Colors.black;
  }

  String _formatCurrency(String? amountString, {bool withSign = true}) {
    double? amount = double.tryParse(amountString ?? '0');
    String formatted = NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount?.abs() ?? 0); 

    if (withSign && amount != null) {
      if (amount < 0) {
        return '- $formatted';
      } else if (amount > 0) {
        return '+ $formatted';
      }
    }
    return formatted;
  }

  Future<void> _showAdvancedFilterDialog() async {
    final DateTime? pickedStartDate = await showDatePicker(
      context: context,
      initialDate:
          _filterStartDate ?? DateTime.now().subtract(const Duration(days: 30)),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      helpText: 'Select Start Date',
    );

    if (pickedStartDate != null) {
      final DateTime? pickedEndDate = await showDatePicker(
        context: context,
        initialDate: _filterEndDate ?? DateTime.now(),
        firstDate: pickedStartDate,
        lastDate: DateTime(2101),
        helpText: 'Select End Date',
      );

      if (pickedEndDate != null) {
        setState(() {
          _filterStartDate = pickedStartDate;
          _filterEndDate = pickedEndDate;
        });
        _fetchTransactions();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Transactions',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: ColorsApp.primary),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
              });
            },
          ),
        ],
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          if (_isSearching)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search transactions...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ),
          // Filter Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildFilterPill('all', 'All'),
                const SizedBox(width: 8),
                _buildFilterPill('income', 'Income'),
                const SizedBox(width: 8),
                _buildFilterPill('expense', 'Expense'),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    side: BorderSide(color: Colors.grey[300]!),
                  ),
                  onPressed: _showAdvancedFilterDialog,
                  icon: const Icon(Icons.filter_alt, size: 18, color: Colors.black54),
                  label: const Text('Filter', style: TextStyle(color: Colors.black54)),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(child: Text(_errorMessage!))
                    : _groupedTransactions.isEmpty
                        ? const Center(child: Text('No transactions found.'))
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            itemCount: _sortedGroupKeys.length,
                            itemBuilder: (context, groupIdx) {
                              final groupKey = _sortedGroupKeys[groupIdx];
                              final group = _groupedTransactions[groupKey]!;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                    child: Text(
                                      groupKey,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                  ...group.map((transaction) => _buildTransactionCard(transaction)).toList(),
                                ],
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPill(String type, String label) {
    final bool selected = _selectedFilterType == type;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: selected ? Colors.white : Colors.black)),
      selected: selected,
      selectedColor: ColorsApp.primary,
      backgroundColor: Colors.grey[200],
      onSelected: (val) {
        setState(() {
          _selectedFilterType = type;
        });
        _fetchTransactions();
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      labelPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }

  Widget _buildTransactionCard(TransactionItemModel transaction) {
    final iconBg = CategoryDisplayHelpers.getCategoryIconBgColor(
      transaction.categoryName,
      transaction.categoryType,
      transaction.customCategoryColor,
    );
    final icon = CategoryDisplayHelpers.getCategoryIcon(
      transaction.categoryName,
      transaction.categoryType,
    );
    final iconColor = CategoryDisplayHelpers.getCategoryIconColor(
      transaction.categoryName,
      transaction.categoryType,
      transaction.customCategoryColor,
    );
    final bool isExpense = transaction.type == 'expense';
    final bool isIncome = transaction.type == 'income';
    final amountColor = isExpense
        ? Colors.red
        : isIncome
            ? Colors.green
            : Colors.black;
    final time = transaction.transactionDate != null && transaction.transactionDate!.length >= 16
        ? transaction.transactionDate!.substring(11, 16)
        : '';
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => AddEditTransactionPage(
                transactionToEdit: TransactionDetailResponseModel(
                  id: transaction.id,
                  wallet: transaction.wallet,
                  walletName: transaction.walletName,
                  category: transaction.category,
                  categoryName: transaction.categoryName,
                  categoryType: transaction.categoryType,
                  customCategoryColor: transaction.customCategoryColor,
                  amount: transaction.amount,
                  type: transaction.type,
                  description: transaction.description,
                  transactionDate: transaction.transactionDate,
                  tagIds: transaction.tagIds,
                  tags: transaction.tags,
                  createdAt: transaction.createdAt,
                  updatedAt: transaction.updatedAt,
                ),
                onTransactionChanged: _fetchTransactions,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          transaction.categoryName ?? '-',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          (isExpense ? 'Rp ' : 'Rp +') + (transaction.amount ?? '0'),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: amountColor,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      (transaction.walletName ?? '-') + (transaction.description != null ? ' • ${transaction.description}' : ''),
                      style: const TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      time,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
