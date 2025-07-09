import 'dart:convert';

class TagRequestModel {
  final String name;

  TagRequestModel({required this.name});

  factory TagRequestModel.fromRawJson(String str) =>
      TagRequestModel.fromJson(json.decode(str));
  String toRawJson() => json.encode(toMap());

  factory TagRequestModel.fromJson(Map<String, dynamic> json) =>
      TagRequestModel(name: json["name"]);

  Map<String, dynamic> toMap() => {"name": name};
}
