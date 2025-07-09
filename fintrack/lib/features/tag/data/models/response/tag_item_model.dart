import 'dart:convert';

class TagItemModel {
  final int? id;
  final String? name;
  final String? createdAt; 

  TagItemModel({
    this.id,
    this.name,
    this.createdAt,
  });

  factory TagItemModel.fromRawJson(String str) => TagItemModel.fromJson(json.decode(str));
  String toRawJson() => json.encode(toJson());

  factory TagItemModel.fromJson(Map<String, dynamic> json) => TagItemModel(
        id: json["id"],
        name: json["name"],
        createdAt: json["created_at"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "created_at": createdAt,
      };
}