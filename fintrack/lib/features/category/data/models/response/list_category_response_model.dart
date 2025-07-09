import 'dart:convert';
import 'package:fintrack/features/category/data/models/category_item_model.dart';

class ListCategoryResponseModel {
  final int? count;
  final String? next;
  final String? previous;
  final List<CategoryItemModel>? results; 

  ListCategoryResponseModel({
    this.count,
    this.next,
    this.previous,
    this.results,
  });

  factory ListCategoryResponseModel.fromRawJson(String str) =>
      ListCategoryResponseModel.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory ListCategoryResponseModel.fromJson(Map<String, dynamic> json) =>
      ListCategoryResponseModel(
        count: json["count"],
        next: json["next"],
        previous: json["previous"],
        results:
            json["results"] == null
                ? []
                : List<CategoryItemModel>.from(
                  json["results"]!.map((x) => CategoryItemModel.fromJson(x)),
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
