import 'package:flutter/material.dart';
import 'package:fintrack/features/transaction/data/datasource/transactions_remote_datasource.dart';
import 'package:fintrack/features/transaction/data/models/response/transaction_item_model.dart';
import 'package:fintrack/utils/category_helpers.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';

class MonthlyOverviewSection extends StatefulWidget {
  const MonthlyOverviewSection({super.key});

  @override
  State<MonthlyOverviewSection> createState() => _MonthlyOverviewSectionState();
}

class _MonthlyOverviewSectionState extends State<MonthlyOverviewSection> {
  final TransactionRemoteDatasource _transactionRemoteDatasource =
      TransactionRemoteDatasource();

  Map<String, double> _categoryTotalAmounts = {};
  Map<String, String> _categoryTypes = {};

  bool _isLoading = true;
  String? _errorMessage;
  double _totalSpend = 0.0;
  double _totalIncome = 0.0;

  final int _topCategoriesLimit = 3;
  DateTime _displayMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fetchAndAggregateTransactions();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchAndAggregateTransactions();
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

  Future<void> _fetchAndAggregateTransactions() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _totalSpend = 0.0;
      _totalIncome = 0.0;
      _categoryTotalAmounts = {};
      _categoryTypes = {};
    });

    String startDate = DateFormat(
      'yyyy-MM-dd',
    ).format(DateTime(_displayMonth.year, _displayMonth.month, 1));

    String endDate = DateFormat(
      'yyyy-MM-dd',
    ).format(DateTime(_displayMonth.year, _displayMonth.month + 1, 0));

    final result = await _transactionRemoteDatasource.getTransactions(
      startDate: startDate,
      endDate: endDate,
    );

    if (!mounted) return;

    result.fold(
      (error) {
        print('Category Aggregation Error: $error');
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Failed to load summaries: $error';
          });
          _showSnackBar('Failed to load summaries: $error', isError: true);
        }
      },
      (data) {
        if (mounted) {
          setState(() {
            List<TransactionItemModel> allTransactions = data.results ?? [];

            _totalSpend = 0.0;
            _totalIncome = 0.0;
            _categoryTotalAmounts = {};
            _categoryTypes = {};

            for (var transaction in allTransactions) {
              if (transaction.type == 'transfer') continue;

              double? amount = double.tryParse(transaction.amount ?? '0');
              if (amount != null) {
                if (transaction.type == 'expense') {
                  _totalSpend += amount;
                } else if (transaction.type == 'income') {
                  _totalIncome += amount;
                }
              }

              if (transaction.categoryName != null &&
                  transaction.categoryName!.isNotEmpty) {
                String categoryKey = transaction.categoryName!;
                double existingTotal =
                    _categoryTotalAmounts[categoryKey] ?? 0.0;
                _categoryTotalAmounts[categoryKey] =
                    existingTotal + (amount ?? 0);

                _categoryTypes[categoryKey] = transaction.type ?? 'N/A';

                print(
                  'DEBUG: Aggregating Category: $categoryKey, Type: ${transaction.type}, Amount: $amount',
                );
              }
            }
            print(
              'DEBUG: Final _totalSpend: $_totalSpend, _totalIncome: $_totalIncome',
            );
            print('DEBUG: Final _categoryTotalAmounts: $_categoryTotalAmounts');
            print('DEBUG: Final _categoryTypes: $_categoryTypes');
            _isLoading = false;
          });
          print('Transactions aggregated for Monthly Overview.');
        }
      },
    );
  }

  void _onMonthChanged(int monthOffset) {
    setState(() {
      _displayMonth = DateTime(
        _displayMonth.year,
        _displayMonth.month + monthOffset,
        1,
      );
    });
    _fetchAndAggregateTransactions();
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount.abs());
  }

  List<PieChartSectionData> _showingSpendSections() {
    List<MapEntry<String, double>> expenseCategories =
        _categoryTotalAmounts.entries
            .where((entry) => _categoryTypes[entry.key] == 'expense')
            .toList();

    expenseCategories.sort((a, b) => b.value.compareTo(a.value));

    print('DEBUG: _totalSpend for pie chart: $_totalSpend');
    print('DEBUG: expenseCategories isEmpty: ${expenseCategories.isEmpty}');

    if (_totalSpend == 0.0 || expenseCategories.isEmpty) {
      return [
        PieChartSectionData(
          value: 100,
          color: Colors.grey.shade300,
          title: 'No Spend',
          radius: 60,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
        ),
      ];
    }

    final double totalExpenseAmount = expenseCategories
        .map((e) => e.value)
        .fold(0.0, (prev, amount) => prev + amount);

    final List<Color> sectionColors = [
      Colors.red.shade700, // Merah
      Colors.orange.shade700, // Oranye
      Colors.purple.shade700, // Ungu
      Colors.blue.shade700, // Biru
      Colors.teal.shade700, // Teal
      Colors.green.shade700, // Hijau
      Colors.brown.shade700, // Coklat
      Colors.pink.shade700, // Pink
    ];

    List<PieChartSectionData> sections = [];
    int colorIndex = 0;

    for (int i = 0; i < expenseCategories.length; i++) {
      final entry = expenseCategories[i];
      final percentage = (entry.value / totalExpenseAmount) * 100;

      if (i >= _topCategoriesLimit) {
        final double remainingTotal = expenseCategories
            .skip(i)
            .map((e) => e.value)
            .fold(0.0, (prev, amt) => prev + amt);
        final remainingPercentage = (remainingTotal / totalExpenseAmount) * 100;
        sections.add(
          PieChartSectionData(
            value: remainingTotal,
            color: Colors.grey.shade400,
            title:
                remainingPercentage > 5
                    ? 'Others\n${remainingPercentage.toStringAsFixed(1)}%'
                    : '',
            radius: 60,
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        );
        break;
      }

      sections.add(
        PieChartSectionData(
          value: entry.value,
          color: sectionColors[colorIndex % sectionColors.length],
          title:
              percentage > 5
                  ? '${entry.key}\n${percentage.toStringAsFixed(1)}%'
                  : '',
          radius: 60,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
      colorIndex++;
    }
    return sections;
  }

  @override
  Widget build(BuildContext context) {
    List<MapEntry<String, double>> sortedTopCategories =
        _categoryTotalAmounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    // Calculate balance percentage (net balance / income), clamp between 0 and 1
    double balancePercent = _totalIncome > 0
        ? ((_totalIncome - _totalSpend) / _totalIncome).clamp(0.0, 1.0)
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Monthly Overview',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => _onMonthChanged(-1),
                    child: Icon(
                      Icons.arrow_back_ios,
                      size: 16,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('MMM yyyy').format(_displayMonth),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _onMonthChanged(1),
                    child: Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? Center(child: Text('Error: $_errorMessage'))
            : Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    // --- Circular Balance Indicator ---
                    _BalanceCircularIndicator(percentage: balancePercent),
                    const SizedBox(width: 24),
                    // --- Income/Expense Dots and Labels ---
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: const BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text('Income', style: TextStyle(fontSize: 15)),
                              const SizedBox(width: 20),
                              Container(
                                width: 12,
                                height: 12,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text('Expense', style: TextStyle(fontSize: 15)),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Spend',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    _formatCurrency(_totalSpend),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text(
                                    'Income',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    _formatCurrency(_totalIncome),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Net Balance: ${_formatCurrency(_totalIncome - _totalSpend)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        const SizedBox(height: 30),
        // --- TOP CATEGORIES SECTION ---
        Text(
          'Top Categories',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 10),
        _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? Center(child: Text('Error: $_errorMessage'))
            : sortedTopCategories.isEmpty
            ? const Center(
              child: Text(
                'No transaction data to show top categories.',
                style: TextStyle(color: Colors.grey),
              ),
            )
            : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sortedTopCategories.take(_topCategoriesLimit).length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final entry = sortedTopCategories[index];
                final categoryName = entry.key;
                final totalAmount = entry.value;
                final categoryType = _categoryTypes[categoryName];

                final isExpense = categoryType == 'expense';
                final amountColor = isExpense ? Colors.red : Colors.green;

                return Card(
                  margin: EdgeInsets.zero,
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          CategoryDisplayHelpers.getCategoryIconBgColor(
                            categoryName,
                            categoryType,
                            null,
                          ),
                      child: Icon(
                        CategoryDisplayHelpers.getCategoryIcon(
                          categoryName,
                          categoryType,
                        ),
                        color: CategoryDisplayHelpers.getCategoryIconColor(
                          categoryName,
                          categoryType,
                          null,
                        ),
                      ),
                    ),
                    title: Text(
                      categoryName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      categoryType ?? 'N/A', // Tampilkan tipe kategori
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    trailing: Text(
                      _formatCurrency(totalAmount),
                      style: TextStyle(
                        color: amountColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                );
              },
            ),
      ],
    );
  }
}

class _BalanceCircularIndicator extends StatelessWidget {
  final double percentage; // 0.0 - 1.0
  const _BalanceCircularIndicator({required this.percentage, super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 70,
      height: 70,
      child: CustomPaint(
        painter: _BalanceCirclePainter(percentage: percentage),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Balance',
                style: TextStyle(fontSize: 11, color: Colors.black54),
              ),
              Text(
                '${(percentage * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BalanceCirclePainter extends CustomPainter {
  final double percentage;
  _BalanceCirclePainter({required this.percentage});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint bgPaint = Paint()
      ..color = Colors.red.shade100
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    final Paint fgPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 4;
    canvas.drawCircle(center, radius, bgPaint);
    final sweepAngle = 2 * pi * percentage;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
