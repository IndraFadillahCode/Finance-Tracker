import 'dart:convert';

class CategoryItemModel {
  final int? id;
  final String? name;
  final String? type; 
  final String? icon; 
  final String? color; 

  CategoryItemModel({this.id, this.name, this.type, this.icon, this.color});

  factory CategoryItemModel.fromRawJson(String str) =>
      CategoryItemModel.fromJson(json.decode(str));
  String toRawJson() => json.encode(toJson());

  factory CategoryItemModel.fromJson(Map<String, dynamic> json) =>
      CategoryItemModel(
        id: json["id"],
        name: json["name"],
        type: json["type"],
        icon: json["icon"],
        color: json["color"],
      );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "type": type,
    "icon": icon,
    "color": color,
  };
}
