import 'dart:convert';

import 'package:dartz/dartz.dart';

import '../../../../core/config/api_driver.dart';
import '../models/response/profile_response_model.dart';

class DashboardRemoteDatasource {
  APIDriver apiDriver = APIDriver();

  Future<Either<String, ProfileResponseModel>> getProfile() async {
    try {
      final response = await apiDriver.get('/auth/profile/');
      print("GET PROFILE RESPONSE: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final profile = ProfileResponseModel.fromJson(data);
        print(
          "Parsed Profile: ${profile.username}",
        ); // Log field untuk validasi
        return right(profile);
      } else {
        return left('Gagal mengambil data profile');
      }
    } catch (e) {
      return left('Gagal mengambil data profile');
    }
  }
}
