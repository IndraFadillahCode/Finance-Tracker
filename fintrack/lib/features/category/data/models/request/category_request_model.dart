import 'dart:convert';

class CategoryRequestModel {
  final String name;
  final String type; 
  final String? icon; 
  final String? color; 

  CategoryRequestModel({
    required this.name,
    required this.type,
    this.icon,
    this.color,
  });

  
  Map<String, dynamic> toMap() => {
    "name": name,
    "type": type,
    "icon": icon,
    "color": color,
  };

 
  String toJsonString() => json.encode(toMap());
}