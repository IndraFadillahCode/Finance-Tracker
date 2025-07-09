import 'dart:convert';

class WalletRequestModel {
  final String? name;
  final String? walletType;
  final String? currency;
  final String? initialBalance;
  final bool? isActive;

  WalletRequestModel({
    this.name,
    this.walletType,
    this.currency,
    this.initialBalance,
    this.isActive,
  });

  factory WalletRequestModel.fromRawJson(String str) =>
      WalletRequestModel.fromMap(json.decode(str));

  String toRawJson() => json.encode(toMap());

  factory WalletRequestModel.fromMap(Map<String, dynamic> json) =>
      WalletRequestModel(
        name: json["name"],
        walletType: json["wallet_type"],
        currency: json["currency"],
        initialBalance: json["initial_balance"],
        isActive: json["is_active"],
      );

  Map<String, dynamic> toMap() => {
    "name": name,
    "wallet_type": walletType,
    "currency": currency,
    "initial_balance": initialBalance,
    "is_active": isActive,
  };
}
