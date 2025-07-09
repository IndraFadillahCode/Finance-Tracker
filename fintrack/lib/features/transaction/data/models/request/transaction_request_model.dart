import 'dart:convert';

class TransactionRequestModel {
  final int? wallet; 
  final int? category; 
  final String? amount;
  final String? type;
  final String? description;
  final String? transactionDate; 
  final List<int>? tagIds;

  TransactionRequestModel({
    this.wallet,
    this.category,
    this.amount,
    this.type,
    this.description,
    this.transactionDate,
    this.tagIds,
  });

  factory TransactionRequestModel.fromRawJson(String str) => TransactionRequestModel.fromJson(json.decode(str));
  String toRawJson() => json.encode(toMap());

  factory TransactionRequestModel.fromJson(Map<String, dynamic> json) => TransactionRequestModel(
        wallet: json["wallet"],
        category: json["category"],
        amount: json["amount"],
        type: json["type"],
        description: json["description"],
        transactionDate: json["transaction_date"],
        tagIds: json["tag_ids"] == null ? null : List<int>.from(json["tag_ids"].map((x) => x)),
      );

  Map<String, dynamic> toMap() => {
        "wallet": wallet,
        "category": category,
        "amount": amount,
        "type": type,
        "description": description,
        "transaction_date": transactionDate,
        "tag_ids": tagIds,
      };
}