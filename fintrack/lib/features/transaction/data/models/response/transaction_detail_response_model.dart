
import 'dart:convert';
import 'transaction_tag_item_model.dart'; 

class TransactionDetailResponseModel {
  final int? id;
  final int? wallet;
  final String? walletName;
  final int? category;
  final String? categoryName;
  final String? categoryType; 
  final String? customCategoryColor; 
  final String? amount;
  final String? type;
  final String? description;
  final String? transactionDate;
  final String? createdAt;
  final String? updatedAt;
  final List<TransactionTagItemModel>? tags;
  final List<int>? tagIds;

  TransactionDetailResponseModel({
    this.id,
    this.wallet,
    this.walletName,
    this.category,
    this.categoryName,
    this.categoryType, 
    this.customCategoryColor,
    this.amount,
    this.type,
    this.description,
    this.transactionDate,
    this.createdAt,
    this.updatedAt,
    this.tags,
    this.tagIds,
  });

  factory TransactionDetailResponseModel.fromRawJson(String str) =>
      TransactionDetailResponseModel.fromJson(json.decode(str));
  String toRawJson() => json.encode(toJson());

  factory TransactionDetailResponseModel.fromJson(Map<String, dynamic> json) =>
      TransactionDetailResponseModel(
        id: json["id"],
        wallet: json["wallet"],
        walletName: json["wallet_name"],
        category: json["category"],
        categoryName: json["category_name"],
        categoryType: json["category_type"], 
        customCategoryColor: json["custom_category_color"], 
        amount: json["amount"],
        type: json["type"],
        description: json["description"],
        transactionDate: json["transaction_date"],
        createdAt: json["created_at"],
        updatedAt: json["updated_at"],
        tags:
            json["tags"] == null
                ? []
                : List<TransactionTagItemModel>.from(
                  json["tags"]!.map((x) => TransactionTagItemModel.fromJson(x)),
                ),
        tagIds:
            json["tag_ids"] == null
                ? []
                : List<int>.from(json["tag_ids"]!.map((x) => x)),
      );

  Map<String, dynamic> toJson() => {
    "id": id,
    "wallet": wallet,
    "wallet_name": walletName,
    "category": category,
    "category_name": categoryName,
    "category_type": categoryType,
    "custom_category_color": customCategoryColor, 
    "amount": amount,
    "type": type,
    "description": description,
    "transaction_date": transactionDate,
    "created_at": createdAt,
    "updated_at": updatedAt,
    "tags":
        tags == null ? [] : List<dynamic>.from(tags!.map((x) => x.toJson())),
    "tag_ids": tagIds == null ? [] : List<dynamic>.from(tagIds!.map((x) => x)),
  };
}
