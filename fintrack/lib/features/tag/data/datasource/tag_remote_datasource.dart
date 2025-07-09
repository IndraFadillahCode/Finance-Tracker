import 'dart:convert'; 
import 'package:dartz/dartz.dart'; 
import 'package:fintrack/core/config/api_driver.dart'; 
import 'package:fintrack/features/tag/data/models/request/tag_request_model.dart';
import 'package:fintrack/features/tag/data/models/response/list_tag_response_model.dart';
import 'package:fintrack/features/tag/data/models/response/tag_detail_response_model.dart';
import 'package:http/http.dart'
    as http; 

class TagRemoteDatasource {
  final APIDriver driver = APIDriver();


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
 
      print("API RESPONSE STATUS: ${response.statusCode}");
      print("API RESPONSE BODY: ${response.body}");
      return Right(response);
    } catch (e) {
      print("EXCEPTION: $e"); 
      return Left('Network or unexpected error: ${e.toString()}');
    }
  }


  Future<Either<String, ListTagResponseModel>> getTags() async {
    final result = await _safeApiCall(() => driver.get('/finance/tags/'));

    return result.fold(
      (error) => Left(error), 
      (response) {
        if (response.statusCode == 200) {
          final Map<String, dynamic> decodedJson =
              jsonDecode(response.body) as Map<String, dynamic>;
          return Right(ListTagResponseModel.fromJson(decodedJson));
        } else {
          return Left(_parseErrorResponse(response)); 
        }
      },
    );
  }

  Future<Either<String, String>> createTag(TagRequestModel tagRequest) async {
    final result = await _safeApiCall(
      () => driver.post('/finance/tags/', tagRequest.toMap()),
    );

    return result.fold(
      (error) => Left(error), 
      (response) {
        if (response.statusCode == 201) {
          return Right('Tag created successfully!');
        } else {
          return Left(_parseErrorResponse(response)); 
        }
      },
    );
  }


  Future<Either<String, TagDetailResponseModel>> getTagDetail(int id) async {
    final result = await _safeApiCall(() => driver.get('/finance/tags/$id/'));

    return result.fold(
      (error) => Left(error), 
      (response) {
        if (response.statusCode == 200) {
          final Map<String, dynamic> decodedJson =
              jsonDecode(response.body) as Map<String, dynamic>;
          return Right(TagDetailResponseModel.fromJson(decodedJson));
        } else {
          return Left(_parseErrorResponse(response)); 
        }
      },
    );
  }

  
  Future<Either<String, String>> updateTag(
    int id,
    TagRequestModel tagRequest,
  ) async {
    final result = await _safeApiCall(
      () => driver.put('/finance/tags/$id/', tagRequest.toMap()),
    );

    return result.fold(
      (error) => Left(error), 
      (response) {
        if (response.statusCode == 200) {
          return Right('Tag updated successfully!');
        } else {
          return Left(_parseErrorResponse(response)); 
        }
      },
    );
  }


  Future<Either<String, String>> deleteTag(int id) async {
    final result = await _safeApiCall(
      () => driver.delete('/finance/tags/$id/'),
    );

    return result.fold(
      (error) => Left(error), 
      (response) {
   
        if (response.statusCode == 204 || response.statusCode == 200) {
          return Right('Tag deleted successfully!');
        } else {
          return Left(_parseErrorResponse(response)); 
        }
      },
    );
  }
}
