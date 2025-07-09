// lib/api_driver.dart
import 'dart:convert';
// import 'dart:io';

// import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;

import '../../features/auth/data/models/request/register_request_model.dart';
import 'token_storage.dart';
import 'variables.dart';

class APIDriver {
  final String _baseUrl = Variables.url;
  final TokenStorage _tokenStorage = TokenStorage();
  // final Dio _dio = Dio();

  // Login
  Future<bool> login(String username, String password) async {
    final url = '$_baseUrl/auth/login/';
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'username': username, 'password': password}),
    );

    // print(response.request!.url);
    // print("Login Response Status Code: ${response.statusCode}");
    // print("Login Response Body: ${response.body}");

    if (response.statusCode == 200) {
      final Map<String, dynamic> data =
          jsonDecode(response.body) as Map<String, dynamic>;

      // --- PERBAIKAN DI SINI ---
      // Ambil objek 'tokens' terlebih dahulu
      final Map<String, dynamic>? tokensData =
          data['tokens'] as Map<String, dynamic>?;

      if (tokensData == null) {
        throw Exception(
          "Login berhasil, tapi objek 'tokens' tidak ditemukan.",
        );
      }

      // Kemudian ambil 'access' dan 'refresh' dari objek 'tokens'
      final String? accessToken = tokensData['access'] as String?;
      final String? refreshToken = tokensData['refresh'] as String?;
      // --- AKHIR PERBAIKAN ---

      // Pastikan token tidak null sebelum disimpan
      if (accessToken == null) {
        throw Exception("Login berhasil, tapi access token null.");
      }

      final expiration = DateTime.now().add(
        const Duration(minutes: 5),
      ); // Gunakan const Duration

      await _tokenStorage.saveAccessToken(accessToken);
      await _tokenStorage.saveExpirationToken(expiration);

      if (refreshToken != null) {
        // Simpan refresh token hanya jika tersedia
        await _tokenStorage.saveRefreshToken(refreshToken);
      } else {
        // Opsional: Hapus refresh token lama jika tidak ada yang baru
        await _tokenStorage.deleteRefreshToken();
      }

      final savedAccessToken = await _tokenStorage.getAccessToken();
      final savedRefreshToken = await _tokenStorage.getRefreshToken();
      print("Saved Access Token: $savedAccessToken");
      print("Saved Refresh Token: $savedRefreshToken");

      return true; // Login berhasil
    } else {
      // Penanganan error yang lebih informatif (seperti yang kita bahas sebelumnya)
      String errorMessage = "Login gagal: ";
      try {
        final errorBody = jsonDecode(response.body);
        if (errorBody is Map && errorBody.containsKey('detail')) {
          errorMessage += errorBody['detail'];
        } else if (errorBody is Map) {
          // Iterate through all error messages from backend
          errorBody.forEach((key, value) {
            errorMessage += '\n$key: ${value.toString()}';
          });
        } else {
          errorMessage +=
              response
                  .body; // Fallback jika body bukan JSON atau tidak ada detail
        }
      } catch (e) {
        errorMessage +=
            "Terjadi kesalahan parsing respons error: ${e.toString()} | Body: ${response.body}";
      }
      throw Exception(errorMessage);
    }
  }

  // Register
  Future<void> register(RegisterRequestModel userData) async {
    final url = '$_baseUrl/auth/register/';
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: userData.toJson(),
    );

    print(response.request?.url);

    if (response.statusCode == 201) {
      // Registrasi berhasil
    } else {
      throw Exception('Registrasi gagal:' + response.body);
    }
  }

  // Refresh Token (Metode yang sudah ada)
  Future<void> refresh() async {
    final url = '$_baseUrl/auth/token/refresh/';
    final refreshToken = await _tokenStorage.getRefreshToken();

    if (refreshToken == null) {
      throw Exception('No refresh token found'); // <--- Ini yang memicu error
    }

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refresh': refreshToken}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final accessToken = data['access'];
      final expiration = DateTime.now().add(
        const Duration(minutes: 5),
      ); // Gunakan const

      await _tokenStorage.saveAccessToken(accessToken);
      await _tokenStorage.saveExpirationToken(expiration);
    } else {
      throw Exception('Failed to refresh token');
    }
  }

  // --- MODIFIKASI METODE GET, POST, PUT, DELETE DI SINI ---
  // Tambahkan parameter skipAuthCheck
  Future<http.Response> get(String url, {bool skipAuthCheck = false}) async {
    // Lewati cek autentikasi jika skipAuthCheck true
    if (!skipAuthCheck) {
      var accessToken = await _tokenStorage.getAccessToken();
      final expiration = await _tokenStorage.getExpirationToken();

      print("GET Request for URL: $_baseUrl$url"); // Debug URL
      print("Current Access Token (before check): $accessToken");
      print("Token Expiration: $expiration");
      print("Current Time: ${DateTime.now()}");

      if (accessToken == null ||
          expiration == null ||
          expiration.isBefore(DateTime.now())) {
        print(
          "Token is null, expired, or expiration is null. Attempting refresh...",
        );
        try {
          await refresh(); // Panggil refresh token
          accessToken =
              await _tokenStorage.getAccessToken(); // Ambil token baru
          if (accessToken == null) {
            throw Exception('Refresh successful but new access token is null.');
          }
        } catch (e) {
          throw Exception(
            'Autentikasi gagal atau token refresh bermasalah. Error: ${e.toString()}',
          );
        }
      }
      // Jika token sudah valid atau baru saja di-refresh, lanjutkan dengan request
      final response = await http.get(
        Uri.parse('$_baseUrl$url'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      print("Response Status: ${response.statusCode}");
      print("Response Body: ${response.body}");
      return response;
    } else {
      // Jika skipAuthCheck adalah true, lewati autentikasi sepenuhnya
      final response = await http.get(Uri.parse('$_baseUrl$url'));
      print("Response Status (Skipped Auth): ${response.statusCode}");
      print("Response Body (Skipped Auth): ${response.body}");
      return response;
    }
  }

  Future<http.Response> post(
    String url,
    Map<String, dynamic> payload, {
    bool skipAuthCheck = false,
  }) async {
    // Lewati cek autentikasi jika skipAuthCheck true
    if (!skipAuthCheck) {
      var accessToken = await _tokenStorage.getAccessToken();
      final expiration = await _tokenStorage.getExpirationToken();

      print("POST Request URL: $_baseUrl$url"); // Debug URL
      print("POST Request Payload: $payload"); // Debug payload
      print("Current Access Token for POST: $accessToken");
      print("Token Expiration for POST: $expiration");
      print("Current Time for POST: ${DateTime.now()}");

      if (accessToken == null ||
          expiration == null ||
          expiration.isBefore(DateTime.now())) {
        print(
          "Access Token is null/expired or expiration is null. Attempting refresh...",
        );
        try {
          await refresh();
          accessToken =
              await _tokenStorage.getAccessToken(); // Ambil token baru
          if (accessToken == null) {
            throw Exception(
              'Token refresh successful, but new access token is null.',
            );
          }
        } catch (e) {
          print("ERROR during token refresh for POST: $e");
          throw Exception(
            'Autentikasi gagal atau token refresh bermasalah. Error: ${e.toString()}',
          );
        }
      }
      // Lanjutkan dengan request POST menggunakan token yang valid
      final response = await http.post(
        Uri.parse('$_baseUrl$url'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(payload),
      );
      return response;
    } else {
      // Jika skipAuthCheck adalah true, lewati autentikasi sepenuhnya
      final response = await http.post(
        Uri.parse('$_baseUrl$url'),
        headers: {
          'Content-Type': 'application/json',
        }, // Hanya header content-type
        body: jsonEncode(payload),
      );
      print("Response Status (Skipped Auth): ${response.statusCode}");
      print("Response Body (Skipped Auth): ${response.body}");
      return response;
    }
  }

  Future<http.Response> put(
    String url,
    Map<String, dynamic> payload, {
    bool skipAuthCheck = false,
  }) async {
    // Ini mirip dengan POST, pastikan logika cek token dibungkus
    if (!skipAuthCheck) {
      var accessToken = await _tokenStorage.getAccessToken();
      final expiration = await _tokenStorage.getExpirationToken();

      if (accessToken == null ||
          expiration == null ||
          expiration.isBefore(DateTime.now())) {
        try {
          await refresh();
          accessToken = await _tokenStorage.getAccessToken();
          if (accessToken == null) {
            throw Exception(
              'Token refresh successful, but new access token is null.',
            );
          }
        } catch (e) {
          throw Exception(
            'Autentikasi gagal atau token refresh bermasalah. Error: ${e.toString()}',
          );
        }
      }
      final response = await http.put(
        Uri.parse('$_baseUrl$url'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(payload),
      );
      return response;
    } else {
      final response = await http.put(
        Uri.parse('$_baseUrl$url'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      return response;
    }
  }

  Future<http.Response> delete(String url, {bool skipAuthCheck = false}) async {
    // Ini mirip dengan GET, pastikan logika cek token dibungkus
    if (!skipAuthCheck) {
      var accessToken = await _tokenStorage.getAccessToken();
      final expiration = await _tokenStorage.getExpirationToken();

      if (accessToken == null ||
          expiration == null ||
          expiration.isBefore(DateTime.now())) {
        try {
          await refresh();
          accessToken = await _tokenStorage.getAccessToken();
          if (accessToken == null) {
            throw Exception(
              'Token refresh successful, but new access token is null.',
            );
          }
        } catch (e) {
          throw Exception(
            'Autentikasi gagal atau token refresh bermasalah. Error: ${e.toString()}',
          );
        }
      }
      final response = await http.delete(
        Uri.parse('$_baseUrl$url'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );
      return response;
    } else {
      final response = await http.delete(Uri.parse('$_baseUrl$url'));
      return response;
    }
  }
}
