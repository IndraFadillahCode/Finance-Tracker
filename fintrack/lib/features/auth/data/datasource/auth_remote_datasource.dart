import 'dart:convert';
import 'package:dartz/dartz.dart';
import '../../../../core/config/api_driver.dart';
import '../models/request/register_request_model.dart';

import 'package:http/http.dart'
    as http; 

class AuthRemoteDatasource {
  final APIDriver driver = APIDriver();

  // Helper untuk parsing error response
  String _parseErrorResponse(http.Response response) {
    String errorMessage =
        'Failed to process request. Status: ${response.statusCode}. ';
    try {
      final errorBody = jsonDecode(response.body);
      if (errorBody is Map && errorBody.containsKey('detail')) {
        errorMessage += 'Detail: ${errorBody['detail']}';
      } else if (errorBody is Map) {
        errorBody.forEach((key, value) {
          errorMessage += '\n$key: ${value.toString()}';
        });
      } else {
        errorMessage += 'Body: ${response.body}';
      }
    } catch (_) {
      errorMessage += '(Invalid or non-JSON error response)';
    }
    return errorMessage;
  }

  Future<Either<String, http.Response>> _safeApiCall(
    Future<http.Response> Function() apiCall,
  ) async {
    try {
      final response = await apiCall();
      print("AUTH API RESPONSE STATUS: ${response.statusCode}");
      print("AUTH API RESPONSE BODY: ${response.body}");
      return Right(response);
    } catch (e) {
      print("AUTH EXCEPTION: $e");
      return Left('Network or unexpected error: ${e.toString()}');
    }
  }

  Future<Either<String, Map<String, dynamic>>> register(
    RegisterRequestModel registerRequest,
  ) async {
    final String registerPath = '/auth/register/';

    final result = await _safeApiCall(
      () => driver.post(
        registerPath,
        registerRequest.toMap(),
        skipAuthCheck: true,
      ),
    );

    return result.fold((error) => Left(error), (response) {
      if (response.statusCode == 201) {
        final Map<String, dynamic> responseData =
            jsonDecode(response.body) as Map<String, dynamic>;
        final Map<String, dynamic>? tokens =
            responseData['tokens'] as Map<String, dynamic>?;

        if (tokens != null &&
            tokens.containsKey('access') &&
            tokens.containsKey('refresh')) {
          return Right(tokens); // Ini Map<String, dynamic>
        } else {
          // Ini akan jadi String Left
          return Left(
            'Registration successful, but tokens not found in response.',
          );
        }
      } else {
        return Left(_parseErrorResponse(response));
      }
    });
  }
}
