import 'package:flutter/material.dart'; 
import 'package:fintrack/core/config/color.dart';
import 'package:fintrack/features/dashboard/data/datasource/dashboard_remote_datasource.dart';
import 'package:fintrack/features/dashboard/data/models/response/profile_response_model.dart';
import 'package:fintrack/features/wallet/data/datasource/wallet_remote_datasource.dart';
import 'package:intl/intl.dart';

class UserBalanceSummary extends StatefulWidget {
  const UserBalanceSummary({super.key});

  @override
  State<UserBalanceSummary> createState() => _UserBalanceSummaryState();
}

class _UserBalanceSummaryState extends State<UserBalanceSummary> {
  final DashboardRemoteDatasource _dashboardDatasource =
      DashboardRemoteDatasource();
  final WalletRemoteDatasource _walletDatasource = WalletRemoteDatasource();

  ProfileResponseModel? _profile;
  double _totalBalance = 0.0;
  int _walletCount = 0;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    print(
      'UserBalanceSummary: didChangeDependencies called, refetching data.',
    );
    _fetchData();
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

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    await Future.wait([_fetchProfile(), _calculateTotalBalanceAndCount()]);

    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _fetchProfile() async {
    final result = await _dashboardDatasource.getProfile();
    result.fold(
      (error) {
        print('Error fetching profile in UserBalanceSummary: $error');
        
      },
      (data) {
        if (mounted) {
          setState(() {
            _profile = data;
          });
        }
      },
    );
  }

  Future<void> _calculateTotalBalanceAndCount() async {
    final walletResult = await _walletDatasource.getWallet();
    walletResult.fold(
      (error) {
        print(
          'Error calculating total balance and count in UserBalanceSummary: $error',
        );
        _showSnackBar(
          'Error loading wallets for total balance: $error',
          isError: true,
        );
      },
      (data) {
        print(
          'DEBUG (UserBalanceSummary): Raw wallet data received: ${data.toJson()}',
        );
        print(
          'DEBUG (UserBalanceSummary): Number of results: ${data.results?.length}',
        );
        if (mounted) {
          setState(() {
            _totalBalance = 0.0;
            _walletCount = 0;

            if (data.results != null) {
              _walletCount = data.results!.length;
              for (var wallet in data.results!) {
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
              'DEBUG (UserBalanceSummary): Final _totalBalance: $_totalBalance, _walletCount: $_walletCount',
            );
          });
        }
      },
    );
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 180,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(),
      );
    }
    if (_errorMessage != null) {
      return Container(
        height: 180,
        alignment: Alignment.center,
        child: Text('Error: $_errorMessage'),
      );
    }

    // Ambil nama yang tersedia
    String displayName = (_profile?.firstName != null && _profile!.firstName!.isNotEmpty)
        ? _profile!.firstName!
        : (_profile?.fullName != null && _profile!.fullName!.isNotEmpty)
            ? _profile!.fullName!
            : (_profile?.username != null && _profile!.username!.isNotEmpty)
                ? _profile!.username!
                : 'User';
    // Ambil inisial dari nama, fallback ke '?'
    String avatarInitial = (displayName != 'User' && displayName.isNotEmpty)
        ? displayName.substring(0, 1).toUpperCase()
        : '?';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ColorsApp.primary,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Hi, $displayName!',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              CircleAvatar(
                backgroundColor: Colors.white,
                radius: 20,
                child: Text(
                  avatarInitial,
                  style: TextStyle(
                    color: ColorsApp.primary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Total Balance',
            style: TextStyle(fontSize: 16, color: Colors.white70),
          ),
          const SizedBox(height: 5),
          Text(
            _formatCurrency(_totalBalance),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '$_walletCount Wallets ',
            style: TextStyle(fontSize: 14, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
