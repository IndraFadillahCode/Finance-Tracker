import 'dart:convert';

class TransactionTagItemModel {
  final int? id;
  final int? tag;
  final String? tagName;

  TransactionTagItemModel({this.id, this.tag, this.tagName});

  factory TransactionTagItemModel.fromRawJson(String str) =>
      TransactionTagItemModel.fromJson(json.decode(str));
  String toRawJson() => json.encode(toJson());

  factory TransactionTagItemModel.fromJson(Map<String, dynamic> json) =>
      TransactionTagItemModel(
        id: json["id"],
        tag: json["tag"],
        tagName: json["tag_name"],
      );

  Map<String, dynamic> toJson() => {"id": id, "tag": tag, "tag_name": tagName};
}
