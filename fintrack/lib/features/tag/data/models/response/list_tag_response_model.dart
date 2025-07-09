import 'dart:convert';
import 'tag_item_model.dart'; 

class ListTagResponseModel {
  final int? count;
  final String? next;
  final String? previous;
  final List<TagItemModel>? results; 

  ListTagResponseModel({
    this.count,
    this.next,
    this.previous,
    this.results,
  });

  factory ListTagResponseModel.fromRawJson(String str) =>
      ListTagResponseModel.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory ListTagResponseModel.fromJson(Map<String, dynamic> json) =>
      ListTagResponseModel(
        count: json["count"],
        next: json["next"],
        previous: json["previous"],
        results: json["results"] == null
            ? []
            : List<TagItemModel>.from(
                json["results"]!.map((x) => TagItemModel.fromJson(x as Map<String, dynamic>))),
      );

  Map<String, dynamic> toJson() => {
        "count": count,
        "next": next,
        "previous": previous,
        "results": results == null
            ? []
            : List<dynamic>.from(results!.map((x) => x.toJson())),
      };
}