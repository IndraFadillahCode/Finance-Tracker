import 'package:flutter/material.dart';
import 'package:fintrack/features/wallet/data/datasource/wallet_remote_datasource.dart';
import 'package:fintrack/features/wallet/data/models/response/list_wallet_response_model.dart';
import 'package:intl/intl.dart';

class MyWallets extends StatefulWidget {
  const MyWallets({super.key});

  @override
  State<MyWallets> createState() => _MyWalletsState();
}

class _MyWalletsState extends State<MyWallets> {
  final WalletRemoteDatasource _walletDatasource = WalletRemoteDatasource();
  List<Result> _wallets = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchWallets();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _fetchWallets();
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

  Future<void> _fetchWallets() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _walletDatasource.getWallet();
    result.fold(
      (error) {
        print('Error fetching wallets in MyWalletsSection: $error');
        if (mounted) {
          setState(() {
            _errorMessage = 'Failed to load wallets: $error';
            _isLoading = false;
          });
          _showSnackBar('Error loading wallets: $error', isError: true);
        }
      },
      (data) {
        if (mounted) {
          setState(() {
            _wallets = data.results ?? [];
            _isLoading = false;
          });
        }
      },
    );
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
    if (_isLoading) {
      return SizedBox(
        height: 120,
        child: Center(child: const CircularProgressIndicator()),
      );
    }
    if (_errorMessage != null) {
      return SizedBox(
        height: 120,
        child: Center(child: Text('Error: $_errorMessage')),
      );
    }
    if (_wallets.isEmpty) {
      return SizedBox(
        height: 120,
        child: Center(child: Text('No wallets found.')),
      );
    }

    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _wallets.length,
        itemBuilder: (context, index) {
          final wallet = _wallets[index];
          final Color cardColor =
              index % 2 == 0 ? Colors.purple.shade100 : Colors.green.shade100;
          final Color textColor =
              index % 2 == 0 ? Colors.purple.shade800 : Colors.green.shade800;

          return Container(
            width: 150,
            margin: const EdgeInsets.only(right: 15),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  wallet.name ?? 'N/A',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                Text(
                  _formatCurrency(wallet.currentBalance),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
