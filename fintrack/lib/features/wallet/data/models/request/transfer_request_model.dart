import 'dart:convert';

class TransferRequestModel {
  final int? fromWallet;
  final int? toWallet;
  final String? amount;
  final String? fee;
  final String? description;

  TransferRequestModel({
    this.fromWallet,
    this.toWallet,
    this.amount,
    this.fee,
    this.description,
  });

  factory TransferRequestModel.fromRawJson(String str) =>
      TransferRequestModel.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory TransferRequestModel.fromMap(Map<String, dynamic> json) =>
      TransferRequestModel(
        fromWallet: json["from_wallet"],
        toWallet: json["to_wallet"],
        amount: json["amount"],
        fee: json["fee"],
        description: json["description"],
      );

  Map<String, dynamic> toMap() => {
    "from_wallet": fromWallet,
    "to_wallet": toWallet,
    "amount": amount,
    "fee": fee,
    "description": description,
  };
}
