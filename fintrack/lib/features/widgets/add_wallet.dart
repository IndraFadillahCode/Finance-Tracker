import 'package:flutter/material.dart';
import 'package:fintrack/features/wallet/data/datasource/wallet_remote_datasource.dart';
import 'package:fintrack/features/wallet/data/models/request/wallet_request_model.dart';
import 'package:fintrack/features/wallet/data/models/response/wallet_response_model.dart';
import '../../../../core/config/color.dart';

class AddWallet extends StatefulWidget {
  final VoidCallback? addWalet;
  final VoidCallback? onUpdate;
  final WalletResponseModel? walet;

  const AddWallet({
    super.key,
    this.addWalet,
    this.onUpdate,
    this.walet,
  });

  @override
  State<AddWallet> createState() => AddWalletState();
}

class AddWalletState extends State<AddWallet> with SingleTickerProviderStateMixin {
  final TextEditingController walletNameController = TextEditingController();
  final TextEditingController walletTypeController = TextEditingController();
  final TextEditingController currencyController = TextEditingController();
  final TextEditingController walletBalanceController = TextEditingController();

  bool? isActive = false;

  final Map<String, String> walletTypes = {
    'cash': 'Cash',
    'bank': 'Bank Account',
    'ewallet': 'E-Wallet',
    'credit': 'Credit Card',
    'other': 'Lainya',
  };

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
    if (widget.walet != null) {
      walletNameController.text = widget.walet!.name ?? '';
      walletTypeController.text = widget.walet!.walletType ?? '';
      currencyController.text = widget.walet!.currency ?? '';
      walletBalanceController.text = widget.walet!.initialBalance ?? '';
      isActive = widget.walet!.isActive;
    } else {
      isActive = true;
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(_fadeAnim),
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: walletNameController,
                  decoration: InputDecoration(
                    labelText: 'Wallet Name',
                    prefixIcon: Icon(Icons.account_balance_wallet, color: ColorsApp.primary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: walletTypeController.text.isEmpty ? null : walletTypeController.text,
                  onChanged: (String? newValue) {
                    setState(() {
                      walletTypeController.text = newValue!;
                    });
                  },
                  items: walletTypes.entries.map((entry) => DropdownMenuItem<String>(
                    value: entry.key,
                    child: Row(
                      children: [
                        Icon(
                          entry.key == 'cash' ? Icons.money :
                          entry.key == 'bank' ? Icons.account_balance :
                          entry.key == 'ewallet' ? Icons.phone_iphone :
                          entry.key == 'credit' ? Icons.credit_card : Icons.wallet_giftcard,
                          color: ColorsApp.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(entry.value),
                      ],
                    ),
                  )).toList(),
                  decoration: InputDecoration(
                    labelText: 'Wallet Type',
                    prefixIcon: Icon(Icons.category, color: ColorsApp.primary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: currencyController,
                  decoration: InputDecoration(
                    labelText: 'Currency',
                    prefixIcon: Icon(Icons.attach_money, color: ColorsApp.primary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: walletBalanceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Wallet Balance',
                    prefixIcon: Icon(Icons.savings, color: ColorsApp.primary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Active',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: ColorsApp.primary,
                      ),
                    ),
                    Switch(
                      value: isActive!,
                      onChanged: (value) {
                        setState(() {
                          isActive = value;
                        });
                      },
                      activeColor: ColorsApp.primary,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
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
                            Navigator.pop(context);
                          },
                          child: Text(
                            'Batal',
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
                          onPressed: () async {
                            final walet = WalletRequestModel(
                              name: walletNameController.text,
                              walletType: walletTypeController.text,
                              currency: currencyController.text,
                              initialBalance: walletBalanceController.text,
                              isActive: isActive,
                            );
                            if (widget.walet != null) {
                              final result = await WalletRemoteDatasource().updateWallet(
                                walet,
                                widget.walet?.id ?? 0,
                              );
                              result.fold(
                                (error) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(error),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                },
                                (successMessage) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(successMessage),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                  widget.onUpdate!();
                                  Navigator.pop(context);
                                },
                              );
                            } else {
                              final result = await WalletRemoteDatasource().createWallet(
                                walet,
                              );
                              result.fold(
                                (error) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(error),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                },
                                (successMessage) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(successMessage),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                  widget.addWalet?.call();
                                  Navigator.pop(context);
                                },
                              );
                            }
                          },
                          child: Text(
                            widget.walet != null ? 'Update' : 'Simpan',
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
    );
  }
}
