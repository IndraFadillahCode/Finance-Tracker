import 'package:flutter/material.dart';
import 'package:fintrack/core/config/color.dart';
import 'package:fintrack/features/widgets/monthly_overview_section.dart';
import 'package:fintrack/features/widgets/my_wallets.dart';
import 'package:fintrack/features/widgets/user_balance_summary.dart';
import 'package:fintrack/features/transaction/data/datasource/transactions_remote_datasource.dart';
import 'package:fintrack/features/transaction/data/models/response/transaction_item_model.dart';
import 'package:fintrack/features/transaction/screen/transaction_list_page.dart';
import 'package:fintrack/utils/category_helpers.dart';
import 'package:intl/intl.dart';
import 'package:fintrack/core/config/token_storage.dart';
import 'package:fintrack/features/auth/screen/login_page.dart';
import 'package:fintrack/features/dashboard/data/datasource/dashboard_remote_datasource.dart';
import 'package:fintrack/features/dashboard/data/models/response/profile_response_model.dart';
import 'dart:math';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> with TickerProviderStateMixin {
  final dashboard = DashboardRemoteDatasource();
  ProfileResponseModel? profile;
  final TransactionRemoteDatasource _transactionRemoteDatasource =
      TransactionRemoteDatasource();

  List<TransactionItemModel> _recentTransactions = [];
  bool _isLoadingRecentTransactions = true;
  String? _recentTransactionsErrorMessage;

  late AnimationController _sectionAnimController;
  late Animation<double> _sectionFadeAnim;
  late AnimationController _listAnimController;

  @override
  void initState() {
    super.initState();
    _sectionAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _sectionFadeAnim = CurvedAnimation(
      parent: _sectionAnimController,
      curve: Curves.easeInOut,
    );
    _listAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _getProfile();
    _fetchRecentTransactions();
    _sectionAnimController.forward();
  }


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchRecentTransactions();
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

  void _getProfile() async {
    final result = await dashboard.getProfile();
    result.fold(
      (error) {
        if (mounted) {
          _showSnackBar('Error loading profile: $error', isError: true);

          if (error.contains('Unauthorized') || error.contains('re-login')) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const LoginPage()),
              (Route<dynamic> route) => false,
            );
          }
        }
      },
      (data) {
        if (mounted) {
          setState(() {
            profile = data;
          });
        }
      },
    );
  }

  Future<void> _fetchRecentTransactions() async {
    if (!mounted) return;
    setState(() {
      _isLoadingRecentTransactions = true;
      _recentTransactionsErrorMessage = null;
    });

    try {
      final result = await _transactionRemoteDatasource.getTransactions();
      result.fold(
        (error) {
          print('Recent Transactions Error: $error');
          if (mounted) {
            setState(() {
              _isLoadingRecentTransactions = false;
              _recentTransactionsErrorMessage =
                  'Failed to load transactions: $error';
            });
            _showSnackBar(
              'Failed to load recent transactions: $error',
              isError: true,
            );
          }
        },
        (data) {
          if (mounted) {
            setState(() {

              List<TransactionItemModel> allTransactions = data.results ?? [];
              allTransactions.sort((a, b) {
                DateTime? dateA = DateTime.tryParse(a.transactionDate ?? '');
                DateTime? dateB = DateTime.tryParse(b.transactionDate ?? '');
                if (dateA == null || dateB == null) return 0;
                return dateB.compareTo(
                  dateA,
                );
              });
              _recentTransactions =
                  allTransactions.take(3).toList();
              _isLoadingRecentTransactions = false;
            });
            print(
              'Recent transactions loaded: ${_recentTransactions.length} items',
            );
          }
        },
      );
    } catch (e) {
      print('Unhandled exception in _fetchRecentTransactions: $e');
      if (mounted) {
        setState(() {
          _isLoadingRecentTransactions = false;
          _recentTransactionsErrorMessage =
              'An unexpected error occurred: ${e.toString()}';
        });
        _showSnackBar(
          'An unexpected error occurred: ${e.toString()}',
          isError: true,
        );
      }
    }
  }


  String _getDateLabel(String? transactionDateString) {
    if (transactionDateString == null || transactionDateString.isEmpty) {
      return 'N/A';
    }
    DateTime? transactionDate = DateTime.tryParse(transactionDateString);
    if (transactionDate == null) return 'N/A';

    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    DateTime yesterday = DateTime(now.year, now.month, now.day - 1);

    if (transactionDate.year == today.year &&
        transactionDate.month == today.month &&
        transactionDate.day == today.day) {
      return "Today";
    } else if (transactionDate.year == yesterday.year &&
        transactionDate.month == yesterday.month &&
        transactionDate.day == yesterday.day) {
      return "Yesterday";
    } else {
      return DateFormat(
        'MMM d, yyyy',
        'en_US',
      ).format(transactionDate);
    }
  }

  Color _getAmountColor(String? type) {
    if (type == 'expense') {
      return Colors.red;
    } else if (type == 'income') {
      return Colors.green;
    }
    return Colors.black;
  }

  String _formatCurrency(String? amountString, {bool withSign = true}) {
    double? amount = double.tryParse(amountString ?? '0');
    String formatted = NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount?.abs() ?? 0); // Selalu format nilai absolut

    if (withSign && amount != null) {
      if (amount < 0) {
        return '- $formatted';
      } else if (amount > 0) {
        return '+ $formatted';
      }
    }
    return formatted;
  }

  @override
  void dispose() {
    _sectionAnimController.dispose();
    _listAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: ShaderMask(
          shaderCallback: (Rect bounds) {
            return LinearGradient(
              colors: [ColorsApp.primary, ColorsApp.primary.withOpacity(0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds);
          },
          child: Text(
            'Dashboard',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.logout,
              color: Colors.grey,
            ),
            onPressed: () async {
              await TokenStorage().deleteAllTokens();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (Route<dynamic> route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [ColorsApp.primary.withOpacity(0.08), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: FadeTransition(
          opacity: _sectionFadeAnim,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Balance Summary with animation
                AnimatedBuilder(
                  animation: _sectionAnimController,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, 30 * (1 - _sectionFadeAnim.value)),
                      child: Opacity(
                        opacity: _sectionFadeAnim.value,
                        child: child,
                      ),
                    );
                  },
                  child: const UserBalanceSummary(),
                ),
                const SizedBox(height: 30),
                // My Wallets Section
                AnimatedBuilder(
                  animation: _sectionAnimController,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(-30 * (1 - _sectionFadeAnim.value), 0),
                      child: Opacity(
                        opacity: _sectionFadeAnim.value,
                        child: child,
                      ),
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'My Wallets',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: ColorsApp.primary,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: MyWallets(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                // Monthly Overview Section
                AnimatedBuilder(
                  animation: _sectionAnimController,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(30 * (1 - _sectionFadeAnim.value), 0),
                      child: Opacity(
                        opacity: _sectionFadeAnim.value,
                        child: child,
                      ),
                    );
                  },
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: MonthlyOverviewSection(),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                // Recent Transactions Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Transactions',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: ColorsApp.primary,
                        letterSpacing: 1.1,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const TransactionListPage(),
                          ),
                        );
                      },
                      child: const Text(
                        'View All',
                        style: TextStyle(color: ColorsApp.primary, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                _isLoadingRecentTransactions
                    ? const Center(child: CircularProgressIndicator())
                    : _recentTransactionsErrorMessage != null
                        ? Center(child: Text(_recentTransactionsErrorMessage!))
                        : _recentTransactions.isEmpty
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(20.0),
                                  child: Text(
                                    'No recent transactions. Add one from the "+" button!',
                                    style: TextStyle(fontSize: 16, color: Colors.grey),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _recentTransactions.length,
                                separatorBuilder: (context, index) => const SizedBox(height: 10),
                                itemBuilder: (context, index) {
                                  final transaction = _recentTransactions[index];
                                  final bool isTransfer = transaction.type == 'transfer';
                                  final amountColor = _getAmountColor(transaction.type);
                                  final amountText = _formatCurrency(transaction.amount, withSign: true);
                                  final dateLabel = _getDateLabel(transaction.transactionDate);
                                  // Animation for each card
                                  final Animation<double> cardAnim = CurvedAnimation(
                                    parent: _listAnimController,
                                    curve: Interval(
                                      min(1.0, index * 0.2),
                                      min(1.0, 0.5 + index * 0.2),
                                      curve: Curves.easeOut,
                                    ),
                                  );
                                  _listAnimController.forward();
                                  return AnimatedBuilder(
                                    animation: cardAnim,
                                    builder: (context, child) {
                                      return Transform.translate(
                                        offset: Offset(0, 30 * (1 - cardAnim.value)),
                                        child: Opacity(
                                          opacity: cardAnim.value,
                                          child: child,
                                        ),
                                      );
                                    },
                                    child: Card(
                                      margin: EdgeInsets.zero,
                                      elevation: 3,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: ListTile(
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 16.0,
                                          vertical: 8.0,
                                        ),
                                        leading: CircleAvatar(
                                          backgroundColor: isTransfer
                                              ? ColorsApp.primary.withOpacity(0.1)
                                              : CategoryDisplayHelpers.getCategoryIconBgColor(
                                                  transaction.categoryName,
                                                  transaction.categoryType,
                                                  transaction.customCategoryColor,
                                                ),
                                          child: Icon(
                                            isTransfer
                                                ? Icons.swap_horiz
                                                : CategoryDisplayHelpers.getCategoryIcon(
                                                    transaction.categoryName,
                                                    transaction.categoryType,
                                                  ),
                                            color: isTransfer
                                                ? ColorsApp.primary
                                                : CategoryDisplayHelpers.getCategoryIconColor(
                                                    transaction.categoryName,
                                                    transaction.categoryType,
                                                    transaction.customCategoryColor,
                                                  ),
                                          ),
                                        ),
                                        title: Text(
                                          (transaction.categoryName != null && transaction.categoryName!.isNotEmpty)
                                              ? transaction.categoryName!
                                              : (isTransfer ? 'Transfer' : 'N/A'),
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        subtitle: Text(
                                          dateLabel,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        trailing: Text(
                                          amountText,
                                          style: TextStyle(
                                            color: amountColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        onTap: null,
                                      ),
                                    ),
                                  );
                                },
                              ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
