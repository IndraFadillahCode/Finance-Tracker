import 'package:flutter/material.dart';
import 'package:fintrack/features/wallet/data/datasource/wallet_remote_datasource.dart';
import 'package:fintrack/features/wallet/data/models/response/list_wallet_response_model.dart';
import 'package:intl/intl.dart';
import 'package:fintrack/core/config/color.dart';
import 'package:fintrack/features/widgets/add_tansfer.dart';
import 'package:fintrack/features/widgets/add_wallet.dart';
import 'package:fintrack/features/widgets/detail_wallet.dart';
import 'dart:math';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> with TickerProviderStateMixin {
  ListWalletResponceModel? listWalet;
  double _totalBalance = 0.0;

  late AnimationController _sectionAnimController;
  late Animation<double> _sectionFadeAnim;
  late AnimationController _listAnimController;

  void _getWalet() async {
    final result = await WalletRemoteDatasource().getWallet();
    result.fold(
      (error) {
        print('Error: $error');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading wallets: $error'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      (data) {
        print(data.toJson());
        if (mounted) {
          setState(() {
            listWalet = data;
            _totalBalance = 0.0;
            if (listWalet?.results != null) {
              for (var wallet in listWalet!.results!) {
                if (wallet.currentBalance != null) {
           
                  double? balance = double.tryParse(wallet.currentBalance!);
                  if (balance != null) {
                    _totalBalance += balance;
                  } else {
                    print(
                      'Warning: Failed to parse balance: ${wallet.currentBalance}',
                    );
                  }
                }
              }
            }
            print(
              'setState updated. Number of wallets: ${listWalet?.results?.length}',
            );
            print(
              'Total Balance Calculated: $_totalBalance',
            ); 
          });
        }
      },
    );
  }

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
    _getWalet();
    _sectionAnimController.forward();
  }

  @override
  void dispose() {
    _sectionAnimController.dispose();
    _listAnimController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    _getWalet();
  }

  String _formatCurrency(String? amountString) {
    double? amount = double.tryParse(amountString ?? '0');
    return NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount ?? 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsApp.bgColor,
      body: SafeArea(
        child: Stack(
          children: [
            RefreshIndicator(
              onRefresh: () async {
                _getWalet();
              },
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Animated Total Balance Section
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
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [ColorsApp.primary, ColorsApp.primary.withOpacity(0.7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: ColorsApp.primary.withOpacity(0.15),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Balance',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                NumberFormat.currency(
                                  locale: 'id',
                                  symbol: 'Rp ',
                                  decimalDigits: 0,
                                ).format(_totalBalance),
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Container(
                                width: 48,
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                child: Center(
                                  child: Text(
                                    'IDR',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
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
                  const SizedBox(height: 24),
                  // Animated Wallet List
                  listWalet?.results == null || listWalet!.results!.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Text(
                              'No wallets found. Add one below!',
                              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                            ),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: listWalet?.results?.length ?? 0,
                          separatorBuilder: (context, index) => const SizedBox(height: 14),
                          itemBuilder: (context, index) {
                            final wallet = listWalet?.results?.elementAt(index);
                            if (wallet == null) {
                              return const SizedBox.shrink();
                            }
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
                              child: GestureDetector(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                        insetPadding: EdgeInsets.zero,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        backgroundColor: Colors.white,
                                        title: Text('Detail Wallet'),
                                        content: SizedBox(
                                          width: MediaQuery.of(context).size.width * 0.8,
                                          child: DetailWallet(
                                            id: wallet.id ?? 0,
                                            onUpdated: () {
                                              _getWalet();
                                            },
                                            onDeleted: () {
                                              _getWalet();
                                            },
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Colors.white, ColorsApp.primary.withOpacity(0.07)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: ColorsApp.primary.withOpacity(0.08),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          color: ColorsApp.primary,
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        child: Center(
                                          child: Text(
                                            wallet.name?.substring(0, 1).toUpperCase() ?? '-',
                                            style: TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            wallet.name ?? '-',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: ColorsApp.primary,
                                            ),
                                          ),
                                          Text(
                                            wallet.walletType ?? '-',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Spacer(),
                                      Text(
                                        _formatCurrency(wallet.currentBalance),
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            // Animated Add Wallet/Transfer Buttons
            Positioned(
              bottom: 20,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  Flexible(
                    child: AnimatedBuilder(
                      animation: _sectionAnimController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: 0.95 + 0.05 * _sectionFadeAnim.value,
                          child: Opacity(
                            opacity: _sectionFadeAnim.value,
                            child: child,
                          ),
                        );
                      },
                      child: InkWell(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                insetPadding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                backgroundColor: Colors.white,
                                title: Text('Add Wallet'),
                                content: SizedBox(
                                  width: MediaQuery.of(context).size.width * 0.8,
                                  child: AddWallet(
                                    addWalet: () {
                                      _getWalet();
                                    },
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        child: Container(
                          height: 60,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [ColorsApp.primary, ColorsApp.primary.withOpacity(0.7)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: ColorsApp.primary.withOpacity(0.15),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              '+ Add Wallet',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: AnimatedBuilder(
                      animation: _sectionAnimController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: 0.95 + 0.05 * _sectionFadeAnim.value,
                          child: Opacity(
                            opacity: _sectionFadeAnim.value,
                            child: child,
                          ),
                        );
                      },
                      child: InkWell(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                insetPadding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                backgroundColor: Colors.white,
                                title: Text('Add Transfer'),
                                content: SizedBox(
                                  width: MediaQuery.of(context).size.width * 0.8,
                                  child: AddTransfer(
                                    addTransfer: () {
                                      _getWalet();
                                    },
                                    listWalet: listWalet,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        child: Container(
                          height: 60,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: ColorsApp.primary, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: ColorsApp.primary.withOpacity(0.08),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.compare_arrows_rounded,
                                color: ColorsApp.primary,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Transfer',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: ColorsApp.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
