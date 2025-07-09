import 'dart:convert';
import 'transaction_item_model.dart'; 

class ListTransactionResponseModel {
  final int? count;
  final String? next;
  final String? previous;
  final List<TransactionItemModel>? results; 

  ListTransactionResponseModel({
    this.count,
    this.next,
    this.previous,
    this.results,
  });

  factory ListTransactionResponseModel.fromRawJson(String str) =>
      ListTransactionResponseModel.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory ListTransactionResponseModel.fromJson(
    Map<String, dynamic> json,
  ) => ListTransactionResponseModel(
    count: json["count"],
    next: json["next"],
    previous: json["previous"],
    results:
        json["results"] == null
            ? []
            : List<TransactionItemModel>.from(
              json["results"]!.map(
                (x) => TransactionItemModel.fromJson(x as Map<String, dynamic>),
              ),
            ),
  );

  Map<String, dynamic> toJson() => {
    "count": count,
    "next": next,
    "previous": previous,
    "results":
        results == null
            ? []
            : List<dynamic>.from(results!.map((x) => x.toJson())),
  };
}
