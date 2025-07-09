import 'dart:convert'; 
import 'package:dartz/dartz.dart'; 
import 'package:fintrack/core/config/api_driver.dart'; 
import 'package:fintrack/features/transaction/data/models/request/transaction_request_model.dart';
import 'package:fintrack/features/transaction/data/models/response/list_transaction_response_model.dart';
import 'package:fintrack/features/transaction/data/models/response/transaction_detail_response_model.dart';
import 'package:http/http.dart' as http; 

class TransactionRemoteDatasource {
  final APIDriver driver = APIDriver();


  Future<Either<String, T>> _handleApiResponse<T>(
    Future<http.Response> Function() apiCall,
    T Function(Map<String, dynamic> json) parser,
    String successMessage, {
    int successStatusCode = 200, 
    int createdStatusCode = 201, 
    int deletedStatusCode = 204, 
    bool isCreate = false,
    bool isDelete = false,
  }) async {
    try {
      final response = await apiCall();

 
      print("API RESPONSE STATUS: ${response.statusCode}");
      print("API RESPONSE BODY: ${response.body}");

      if ((!isCreate &&
              !isDelete &&
              response.statusCode == successStatusCode) ||
          (isCreate && response.statusCode == createdStatusCode) ||
          (isDelete &&
              (response.statusCode == deletedStatusCode ||
                  response.statusCode == successStatusCode))) {

        if (isDelete) {
          return Right(
            successMessage as T,
          ); 
        } else {
          final Map<String, dynamic> decodedJson =
              jsonDecode(response.body) as Map<String, dynamic>;
          return Right(parser(decodedJson));
        }
      } else {
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
          errorMessage += '(Invalid error response format)';
        }
        return Left(errorMessage);
      }
    } catch (e) {
 
      print("EXCEPTION: $e");
      return Left('Network or unexpected error: ${e.toString()}');
    }
  }

  Future<Either<String, ListTransactionResponseModel>> getTransactions({
    String? type,
    int? walletId,
    String? startDate,
    String? endDate,
    int? categoryId,
  }) async {
    final Map<String, String> queryParams = {};
    if (type != null) queryParams['type'] = type;
    if (walletId != null) queryParams['wallet'] = walletId.toString();
    if (startDate != null) queryParams['start_date'] = startDate;
    if (endDate != null) queryParams['end_date'] = endDate;
    if (categoryId != null) queryParams['category'] = categoryId.toString();

    final uri = Uri.parse(
      '/finance/transactions/',
    ).replace(queryParameters: queryParams);

    return _handleApiResponse<ListTransactionResponseModel>(
      () => driver.get(uri.toString()),
      ListTransactionResponseModel.fromJson,
      'Transactions loaded successfully!', 
    );
  }

  Future<Either<String, String>> createTransaction(
    TransactionRequestModel transactionRequest,
  ) async {
    return _handleApiResponse<String>(
      () => driver.post('/finance/transactions/', transactionRequest.toMap()),
      (json) =>
          'Transaction created successfully!',
      'Transaction created successfully!',
      isCreate: true,
    );
  }

  Future<Either<String, TransactionDetailResponseModel>> getTransactionDetail(
    int id,
  ) async {
    return _handleApiResponse<TransactionDetailResponseModel>(
      () => driver.get('/finance/transactions/$id/'),
      TransactionDetailResponseModel.fromJson,
      'Transaction detail loaded successfully!', // Pesan sukses (tidak digunakan untuk GET model)
    );
  }

  Future<Either<String, String>> updateTransaction(
    int id,
    TransactionRequestModel transactionRequest,
  ) async {
    return _handleApiResponse<String>(
      () =>
          driver.put('/finance/transactions/$id/', transactionRequest.toMap()),
      (json) =>
          'Transaction updated successfully!', 
      'Transaction updated successfully!',
    );
  }

  Future<Either<String, String>> deleteTransaction(int id) async {
    return _handleApiResponse<String>(
      () => driver.delete('/finance/transactions/$id/'),
      (json) =>
          'Transaction deleted successfully!', 
      'Transaction deleted successfully!',
      isDelete: true,
    );
  }

  
}
