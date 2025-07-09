import 'package:flutter/material.dart';
import 'package:fintrack/features/wallet/data/datasource/wallet_remote_datasource.dart';
import 'package:fintrack/features/wallet/data/models/request/transfer_request_model.dart';
import 'package:fintrack/features/wallet/data/models/response/list_wallet_response_model.dart';
import '../../../../core/config/color.dart';

class AddTransfer extends StatefulWidget {
  final ListWalletResponceModel? listWalet;
  final VoidCallback? addTransfer;

  const AddTransfer({super.key, this.addTransfer, this.listWalet});

  @override
  State<AddTransfer> createState() => AddTransferState();
}

class AddTransferState extends State<AddTransfer> with SingleTickerProviderStateMixin {
  final TextEditingController amountController = TextEditingController();
  final TextEditingController feeController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  int? formWalet;
  int? toWalet;

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
                DropdownButtonFormField<int>(
                  value: formWalet,
                  items: widget.listWalet?.results?.map((e) {
                    return DropdownMenuItem<int>(
                      value: e.id,
                      child: Row(
                        children: [
                          Icon(Icons.account_balance_wallet, color: ColorsApp.primary),
                          const SizedBox(width: 8),
                          Text(e.name ?? ''),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      formWalet = value;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'From Wallet',
                    prefixIcon: Icon(Icons.arrow_upward, color: ColorsApp.primary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<int>(
                  value: toWalet,
                  items: widget.listWalet?.results?.map((e) {
                    return DropdownMenuItem<int>(
                      value: e.id,
                      child: Row(
                        children: [
                          Icon(Icons.account_balance_wallet, color: ColorsApp.primary),
                          const SizedBox(width: 8),
                          Text(e.name ?? ''),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      toWalet = value;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'To Wallet',
                    prefixIcon: Icon(Icons.arrow_downward, color: ColorsApp.primary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Amount',
                    prefixIcon: Icon(Icons.attach_money, color: ColorsApp.primary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: feeController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Fee',
                    prefixIcon: Icon(Icons.money_off, color: ColorsApp.primary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    prefixIcon: Icon(Icons.description, color: ColorsApp.primary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
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
                            final transfer = TransferRequestModel(
                              fromWallet: formWalet,
                              toWallet: toWalet,
                              amount: amountController.text,
                              fee: feeController.text,
                              description: descriptionController.text,
                            );
                            final result = await WalletRemoteDatasource().createTransfer(
                              transfer,
                            );
                            result.fold(
                              (error) {
                                ScaffoldMessenger.of(
                                  context,
                                ).showSnackBar(SnackBar(content: Text(error)));
                              },
                              (success) {
                                ScaffoldMessenger.of(
                                  context,
                                ).showSnackBar(SnackBar(content: Text(success)));
                                widget.addTransfer?.call();
                                Navigator.pop(context);
                              },
                            );
                          },
                          child: Text(
                            'Simpan',
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
