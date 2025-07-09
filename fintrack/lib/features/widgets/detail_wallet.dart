import 'package:flutter/material.dart';
import 'package:fintrack/features/wallet/data/datasource/wallet_remote_datasource.dart';
import 'package:fintrack/features/wallet/data/models/response/wallet_response_model.dart';
import 'package:fintrack/features/widgets/add_wallet.dart';

class DetailWallet extends StatefulWidget {
  final int? id;
  final VoidCallback? onDeleted;
  final VoidCallback? onUpdated;

  const DetailWallet({super.key, this.id, this.onDeleted, this.onUpdated});

  @override
  State<DetailWallet> createState() => _DetailWalletState();
}

class _DetailWalletState extends State<DetailWallet> {
  WalletResponseModel? walet;
  void _getWalet() async {
    final result = await WalletRemoteDatasource().detailWallet(widget.id ?? 0);
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
        print(data);
        setState(() {
          walet = data;
        });
      },
    );
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _getWalet();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Name :',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.black,
                fontSize: 16,
              ),
            ),
            Text(
              walet?.name ?? '-',
              style: TextStyle(
                color: Colors.black54,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Type :',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.black,
                fontSize: 16,
              ),
            ),
            Text(
              walet?.walletType ?? '-',
              style: TextStyle(
                color: Colors.black54,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Currency :',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.black,
                fontSize: 16,
              ),
            ),
            Text(
              walet?.currency ?? '-',
              style: TextStyle(
                color: Colors.black54,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              'Initial Balance :',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.black,
                fontSize: 16,
              ),
            ),
            Text(
              walet?.initialBalance ?? '-',
              style: TextStyle(
                color: Colors.black54,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),

            Text(
              'Current Balance :',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.black,
                fontSize: 16,
              ),
            ),
            Text(
              walet?.currentBalance ?? '-',
              style: TextStyle(
                color: Colors.black54,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              walet?.isActive == true ? 'yes' : 'no',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.black,
                fontSize: 16,
              ),
            ),
            Text(
              'Yes',
              style: TextStyle(
                color: Colors.black54,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Tutup',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          insetPadding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          backgroundColor: Colors.white,
                          title: Text('Edit Wallet'),
                          content: SizedBox(
                            width: MediaQuery.of(context).size.width * 0.8,
                            child: AddWallet(
                              walet: walet,
                              onUpdate: () {
                                if (widget.onUpdated != null) {
                                  widget.onUpdated!();
                                }
                              },
                            ),
                          ),
                        );
                      },
                    );
                  },
                  child: Text(
                    'Edit',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                TextButton(
                  onPressed: () async {
                    final result = await WalletRemoteDatasource().deleteWallet(
                      widget.id ?? 0,
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
                        widget.onDeleted!();
                        Navigator.pop(context);
                      },
                    );
                  },
                  child: Text(
                    'Hapus',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
