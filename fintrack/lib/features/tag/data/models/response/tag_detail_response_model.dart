import 'dart:convert';

class TagDetailResponseModel { 
  final int? id;
  final String? name;
  final String? createdAt; 

  TagDetailResponseModel({
    this.id,
    this.name,
    this.createdAt,
  });

  factory TagDetailResponseModel.fromRawJson(String str) => TagDetailResponseModel.fromJson(json.decode(str));
  String toRawJson() => json.encode(toJson());

  factory TagDetailResponseModel.fromJson(Map<String, dynamic> json) => TagDetailResponseModel(
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