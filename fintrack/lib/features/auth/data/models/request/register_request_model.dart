import 'dart:convert';

class RegisterRequestModel {
  final String? username;
  final String? password;
  final String? password2;
  final String? email;
  final String? firstName;
  final String? lastName;
  final String? phone; 
  final String?
  tokenRegistrasi; 

  RegisterRequestModel({
    this.username,
    this.password,
    this.password2,
    this.email,
    this.firstName,
    this.lastName,
    this.phone, 
    this.tokenRegistrasi, 
  });

  factory RegisterRequestModel.fromJson(String str) =>
      RegisterRequestModel.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory RegisterRequestModel.fromMap(Map<String, dynamic> json) =>
      RegisterRequestModel(
        username: json["username"],
        password: json["password"],
        password2: json["password2"],
        email: json["email"],
        firstName: json["first_name"],
        lastName: json["last_name"],
        phone: json["phone"], 
        tokenRegistrasi: json["token_registrasi"], 
      );

  Map<String, dynamic> toMap() => {
    "username": username,
    "password": password,
    "password2": password2,
    "email": email,
    "first_name": firstName,
    "last_name": lastName,
    "phone": phone, 
    "token_registrasi": tokenRegistrasi, 
  };
}
