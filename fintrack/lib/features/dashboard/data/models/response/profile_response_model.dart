import 'dart:convert';

class ProfileResponseModel {
  final String? id;
  final String? username;
  final String? email;
  final String? firstName;
  final String? lastName;

  ProfileResponseModel({
    this.id,
    this.username,
    this.email,
    this.firstName,
    this.lastName,
  });

  // factory ProfileResponseModel.fromJson(String str) =>
  //     ProfileResponseModel.fromMap(json.decode(str));

  factory ProfileResponseModel.fromJson(Map<String, dynamic> json) =>
      ProfileResponseModel(
        id: json["id"],
        username: json["username"],
        email: json["email"],
        firstName: json["first_name"],
        lastName: json["last_name"],
      );

  get fullName => null;

  Map<String, dynamic> toMap() => {
    "id": id,
    "username": username,
    "email": email,
    "first_name": firstName,
    "last_name": lastName,
  };

  String toJson() => json.encode(toMap());
}
