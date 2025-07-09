import 'package:flutter/material.dart';
import 'package:fintrack/core/config/color.dart';
import 'package:fintrack/features/transaction/data/datasource/transactions_remote_datasource.dart';
import 'package:fintrack/features/transaction/data/models/response/transaction_item_model.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> with SingleTickerProviderStateMixin {
  final TransactionRemoteDatasource _transactionRemoteDatasource =
      TransactionRemoteDatasource();

  List<TransactionItemModel> _transactions =
      [];
  Map<String, double> _categoryTotalAmounts =
      {};
  Map<String, String> _categoryTypes =
      {};

  Map<int, double> _weeklyExpenses = {};
  double _maxYExpenseTrend = 0.0;

  bool _isLoading = true;
  String? _errorMessage;
  double _totalIncome = 0.0;
  double _totalExpense = 0.0;
  double _balance = 0.0;


  DateTime _selectedPeriod =
      DateTime.now();

  final int _topCategoriesLimit = 3;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeInOut);
    _animController.forward();
    _selectedPeriod = DateTime(_selectedPeriod.year, _selectedPeriod.month, 1);
    _fetchAndAggregateReportData();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_isLoading) {
      _fetchAndAggregateReportData();
    }
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

  Future<void> _fetchAndAggregateReportData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _transactions = [];
      _categoryTotalAmounts = {};
      _categoryTypes = {};
      _totalIncome = 0.0;
      _totalExpense = 0.0;
      _balance = 0.0;
      _weeklyExpenses = {
              1: 0.0,
              2: 0.0,
              3: 0.0,
              4: 0.0,
              5: 0.0,
            };
      _maxYExpenseTrend = 0.0;
    });

    String startDate = DateFormat(
      'yyyy-MM-dd',
    ).format(DateTime(_selectedPeriod.year, _selectedPeriod.month, 1));
    String endDate = DateFormat(
      'yyyy-MM-dd',
    ).format(DateTime(_selectedPeriod.year, _selectedPeriod.month + 1, 0));

    final result = await _transactionRemoteDatasource.getTransactions(
      startDate: startDate,
      endDate: endDate,
    );

    if (!mounted) return;

    result.fold(
      (error) {
        print('Report Data Aggregation Error: $error');
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Failed to load report data: $error';
          });
          _showSnackBar('Failed to load report data: $error', isError: true);
        }
      },
      (data) {
        if (mounted) {
          setState(() {
            _transactions = data.results ?? []; // Simpan semua transaksi
            _totalIncome = 0.0;
            _totalExpense = 0.0;
            _categoryTotalAmounts = {};
            _categoryTypes = {};
            _weeklyExpenses = {
              1: 0.0,
              2: 0.0,
              3: 0.0,
              4: 0.0,
              5: 0.0,
            };
            _maxYExpenseTrend = 0.0;

            for (var transaction in _transactions) {
              if (transaction.type == 'transfer')
                continue;

              double? amount = double.tryParse(transaction.amount ?? '0');
              if (amount != null) {
                if (transaction.type == 'income') {
                  _totalIncome += amount;
                } else if (transaction.type == 'expense') {
                  _totalExpense += amount;

                  if (transaction.transactionDate != null) {
                    DateTime? transDate = DateTime.tryParse(
                      transaction.transactionDate!,
                    );
                    if (transDate != null) {

                      int week =
                          ((transDate.day - 1) ~/ 7) +
                          1;
                      _weeklyExpenses[week] =
                          (_weeklyExpenses[week] ?? 0.0) + amount;
                      if (_weeklyExpenses[week]! > _maxYExpenseTrend) {
                        _maxYExpenseTrend = _weeklyExpenses[week]!;
                      }
                    }
                  }
                }
              }


              if (transaction.categoryName != null &&
                  transaction.categoryName!.isNotEmpty) {
                String categoryKey = transaction.categoryName!;

                if (transaction.type == 'expense') {
                  double existingTotal =
                      _categoryTotalAmounts[categoryKey] ?? 0.0;
                  _categoryTotalAmounts[categoryKey] = existingTotal + amount!;
                }
                _categoryTypes[categoryKey] = transaction.type ?? 'N/A';
              }
            }
            _balance = _totalIncome - _totalExpense;


            _categoryTotalAmounts = Map.fromEntries(
              _categoryTotalAmounts.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value)),
            );

            _maxYExpenseTrend = (_maxYExpenseTrend * 1.2).ceilToDouble();
            if (_maxYExpenseTrend == 0)
              _maxYExpenseTrend = 100.0;

            _isLoading = false;
          });
          print(
            'Report data aggregated for ${_selectedPeriod.toIso8601String()}.',
          );
        }
      },
    );
  }

  void _onPeriodChanged(int monthOffset) {
    setState(() {
      _selectedPeriod = DateTime(
        _selectedPeriod.year,
        _selectedPeriod.month + monthOffset,
        1,
      );
    });
    _fetchAndAggregateReportData();
  }


  List<PieChartSectionData> _showingExpenseBreakdownSections() {
    List<MapEntry<String, double>> expenseCategories =
        _categoryTotalAmounts.entries
            .where(
              (entry) => _categoryTypes[entry.key] == 'expense',
            ) // Pastikan hanya expense
            .toList();

    // Pastikan total pengeluaran > 0 untuk menghindari pembagian dengan nol
    final double totalExpenseAmount = expenseCategories
        .map((e) => e.value)
        .fold(0.0, (prev, amount) => prev + amount);
    if (totalExpenseAmount == 0.0 || expenseCategories.isEmpty) {
      return [
        PieChartSectionData(
          value: 100,
          color: Colors.grey.shade300,
          title: 'No Expense',
          radius: 60,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
        ),
      ];
    }

    final List<Color> sectionColors = [
      Colors.red.shade700,
      Colors.orange.shade700,
      Colors.purple.shade700,
      Colors.blue.shade700,
      Colors.teal.shade700,
      Colors.green.shade700,
      Colors.brown.shade700,
      Colors.pink.shade700,
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
        if (remainingPercentage > 0) {
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
        }
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


  BarChartGroupData _makeBarChartGroupData(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: Colors.blue.shade700,
          width: 16,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
      showingTooltipIndicators: [],
    );
  }

  Widget getTitles(double value, TitleMeta meta) {
    const style = TextStyle(
      color: Colors.grey,
      fontWeight: FontWeight.bold,
      fontSize: 12,
    );
    String text;
    switch (value.toInt()) {
      case 1:
        text = 'Week 1';
        break;
      case 2:
        text = 'Week 2';
        break;
      case 3:
        text = 'Week 3';
        break;
      case 4:
        text = 'Week 4';
        break;
      case 5:
        text = 'Week 5';
        break;
      default:
        return const SizedBox();
    }
    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 4,
      child: Text(text, style: style),
    );
  }


  String _formatCurrency(double amount) {
    return NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount.abs());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        backgroundColor: ColorsApp.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text('Error: $_errorMessage'))
              : FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: Tween<Offset>(begin: const Offset(0, 0.07), end: Offset.zero).animate(_fadeAnim),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // --- Time Period Header ---
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today, size: 20, color: Colors.blueAccent),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Time Period',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () => _onPeriodChanged(-1),
                                      child: Icon(Icons.arrow_back_ios, size: 16, color: Colors.blueAccent),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      DateFormat('MMM yyyy').format(_selectedPeriod),
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                                    ),
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: () => _onPeriodChanged(1),
                                      child: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.blueAccent),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // --- Summary Card ---
                          Card(
                            elevation: 3,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.blue.shade50, Colors.white],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 14,
                                            height: 14,
                                            decoration: const BoxDecoration(
                                              color: Colors.green,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          const Text('Total Income', style: TextStyle(fontSize: 14, color: Colors.grey)),
                                        ],
                                      ),
                                      Text(_formatCurrency(_totalIncome), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 14,
                                            height: 14,
                                            decoration: const BoxDecoration(
                                              color: Colors.red,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          const Text('Total Expense', style: TextStyle(fontSize: 14, color: Colors.grey)),
                                        ],
                                      ),
                                      Text(_formatCurrency(_totalExpense), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
                                    ],
                                  ),
                                  const SizedBox(height: 18),
                                  Align(
                                    alignment: Alignment.center,
                                    child: Text('Balance: ${_formatCurrency(_balance)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),
                          // --- Expense Breakdown ---
                          Row(
                            children: [
                              const Icon(Icons.pie_chart, color: Colors.redAccent, size: 22),
                              const SizedBox(width: 8),
                              Text('Expense Breakdown', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.redAccent.shade200)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    height: 200,
                                    child: PieChart(
                                      PieChartData(
                                        sections: _showingExpenseBreakdownSections(),
                                        centerSpaceRadius: 40,
                                        sectionsSpace: 2,
                                        borderData: FlBorderData(show: false),
                                        pieTouchData: PieTouchData(
                                          touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                            setState(() {/* handle touch */});
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),
                          // --- Expense Trend ---
                          Row(
                            children: [
                              const Icon(Icons.show_chart, color: Colors.blueAccent, size: 22),
                              const SizedBox(width: 8),
                              Text('Expense Trend', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueAccent.shade200)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: Container(
                              height: 200,
                              padding: const EdgeInsets.all(16.0),
                              child: BarChart(
                                BarChartData(
                                  alignment: BarChartAlignment.spaceAround,
                                  maxY: _maxYExpenseTrend,
                                  barTouchData: BarTouchData(
                                    touchTooltipData: BarTouchTooltipData(
                                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                        String weekText = '';
                                        switch (group.x.toInt()) {
                                          case 1:
                                            weekText = 'Week 1';
                                            break;
                                          case 2:
                                            weekText = 'Week 2';
                                            break;
                                          case 3:
                                            weekText = 'Week 3';
                                            break;
                                          case 4:
                                            weekText = 'Week 4';
                                            break;
                                          case 5:
                                            weekText = 'Week 5';
                                            break;
                                        }
                                        return BarTooltipItem(
                                          '$weekText\n${_formatCurrency(rod.toY)}',
                                          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                        );
                                      },
                                    ),
                                  ),
                                  titlesData: FlTitlesData(
                                    show: true,
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: getTitles,
                                        reservedSize: 20,
                                      ),
                                    ),
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (value, meta) {
                                          return Text(_formatCurrency(value), style: const TextStyle(color: Colors.grey, fontSize: 10));
                                        },
                                        reservedSize: 40,
                                      ),
                                    ),
                                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  ),
                                  gridData: FlGridData(
                                    show: true,
                                    drawHorizontalLine: true,
                                    drawVerticalLine: false,
                                    getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade300, strokeWidth: 1),
                                  ),
                                  borderData: FlBorderData(
                                    show: false,
                                    border: Border.all(color: Colors.grey.shade200, width: 1),
                                  ),
                                  barGroups: [
                                    _makeBarChartGroupData(1, _weeklyExpenses[1] ?? 0.0),
                                    _makeBarChartGroupData(2, _weeklyExpenses[2] ?? 0.0),
                                    _makeBarChartGroupData(3, _weeklyExpenses[3] ?? 0.0),
                                    _makeBarChartGroupData(4, _weeklyExpenses[4] ?? 0.0),
                                    _makeBarChartGroupData(5, _weeklyExpenses[5] ?? 0.0),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }
}
