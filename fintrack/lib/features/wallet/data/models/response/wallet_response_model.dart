import 'dart:convert';

class WalletResponseModel {
    final int? id;
    final String? name;
    final String? walletType;
    final String? currency;
    final String? initialBalance;
    final String? currentBalance;
    final bool? isActive;
    final DateTime? createdAt;
    final DateTime? updatedAt;

    WalletResponseModel({
        this.id,
        this.name,
        this.walletType,
        this.currency,
        this.initialBalance,
        this.currentBalance,
        this.isActive,
        this.createdAt,
        this.updatedAt,
    });

    factory WalletResponseModel.fromRawJson(String str) => WalletResponseModel.fromJson(json.decode(str));

    String toRawJson() => json.encode(toJson());

    factory WalletResponseModel.fromJson(Map<String, dynamic> json) => WalletResponseModel(
        id: json["id"],
        name: json["name"],
        walletType: json["wallet_type"],
        currency: json["currency"],
        initialBalance: json["initial_balance"],
        currentBalance: json["current_balance"],
        isActive: json["is_active"],
        createdAt: json["created_at"] == null ? null : DateTime.parse(json["created_at"]),
        updatedAt: json["updated_at"] == null ? null : DateTime.parse(json["updated_at"]),
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "wallet_type": walletType,
        "currency": currency,
        "initial_balance": initialBalance,
        "current_balance": currentBalance,
        "is_active": isActive,
        "created_at": createdAt?.toIso8601String(),
        "updated_at": updatedAt?.toIso8601String(),
    };
}
