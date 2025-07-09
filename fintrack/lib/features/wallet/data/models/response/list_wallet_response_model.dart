import 'dart:convert';

class ListWalletResponceModel {
  final int? count;
  final int? totalPage;
  final dynamic next;
  final dynamic previous;
  final List<Result>? results;

  ListWalletResponceModel({
    this.count,
    this.totalPage,
    this.next,
    this.previous,
    this.results,
  });

  factory ListWalletResponceModel.fromRawJson(String str) =>
      ListWalletResponceModel.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory ListWalletResponceModel.fromJson(Map<String, dynamic> json) =>
      ListWalletResponceModel(
        count: json["count"],

        totalPage: json["total_pages"],
        next: json["next"],
        previous: json["previous"],

        results:
            json["results"] == null
                ? []
                : List<Result>.from(
                  json["results"]!.map((x) => Result.fromJson(x)),
                ),
      );

  Map<String, dynamic> toJson() => {
    "count": count,
    "total_page": totalPage,
    "next": next,
    "previous": previous,

    "results":
        results == null
            ? []
            : List<dynamic>.from(results!.map((x) => x.toJson())),
  };
}

class Result {
  final int? id;
  final String? name;
  final String? walletType;
  final String? currency;
  final String? currentBalance;
  final bool? isActive;

  Result({
    this.id,
    this.name,
    this.walletType,
    this.currency,
    this.currentBalance,
    this.isActive,
  });

  factory Result.fromRawJson(String str) => Result.fromJson(json.decode(str));
  String toRawJson() => json.encode(toJson());

  factory Result.fromJson(Map<String, dynamic> json) => Result(
    id: json["id"],
    name: json["name"],
    walletType: json["wallet_type"],
    currency: json["currency"],
    currentBalance: json["current_balance"],
    isActive: json["is_active"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "wallet_type": walletType,
    "currency": currency,
    "current_balance": currentBalance,
    "is_active": isActive,
  };
}
