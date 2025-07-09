import 'package:dartz/dartz.dart';
import 'dart:convert';
import 'package:fintrack/core/config/api_driver.dart';
import 'package:fintrack/features/wallet/data/models/request/transfer_request_model.dart';
import 'package:fintrack/features/wallet/data/models/request/wallet_request_model.dart';
import 'package:fintrack/features/wallet/data/models/response/list_wallet_response_model.dart';
import 'package:fintrack/features/wallet/data/models/response/wallet_response_model.dart';

class WalletRemoteDatasource {
  APIDriver driver = APIDriver();

  Future<Either<String, ListWalletResponceModel>> getWallet() async {
    try {
      final response = await driver.get('/finance/wallets/');

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedJson =
            jsonDecode(response.body) as Map<String, dynamic>;
        return Right(ListWalletResponceModel.fromJson(decodedJson));
      } else {
        return Left('Failed to load wallet data');
      }
    } catch (e) {
      return Left('Failed to load wallet data');
    }
  }

  Future<Either<String, String>> createWallet(WalletRequestModel wallet) async {
    try {
      final response = await driver.post('/finance/wallets/', wallet.toMap());


      print("CREATE WALLET RESPONSE STATUS: ${response.statusCode}");
      print("CREATE WALLET RESPONSE BODY: ${response.body}");


      if (response.statusCode == 201) {
        return Right('Wallet created successfully!');
      } else {
   
        String errorMessage =
            'Failed to create wallet. Status: ${response.statusCode}. ';
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
        return Left(errorMessage);

      }
    } catch (e) {

      print("EXCEPTION IN createWallet: $e");
      return Left('Failed to create wallet: ${e.toString()}');

    }
  }

  Future<Either<String, WalletResponseModel>> detailWallet(int id) async {
    try {
      final response = await driver.get('/finance/wallets/$id/');

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedJson =
            jsonDecode(response.body) as Map<String, dynamic>;

        return Right(WalletResponseModel.fromJson(decodedJson));
      } else {
        String errorMessage =
            'Failed to load wallet data. Status: ${response.statusCode}';
        try {
          final errorBody = jsonDecode(response.body);
          if (errorBody is Map && errorBody.containsKey('detail')) {
            errorMessage += ' Detail: ${errorBody['detail']}';
          } else {
            errorMessage += ' Body: ${response.body}';
          }
        } catch (_) {
          errorMessage += ' (Invalid error response)';
        }
        return Left(errorMessage);
      }
    } catch (e) {
      print("Error in detailWallet: $e");
      return Left('Failed to load wallet data: ${e.toString()}');
    }
  }

  Future<Either<String, String>> updateWallet(
    WalletRequestModel wallet,
    int id,
  ) async {
    try {
      final response = await driver.put('/finance/wallets/$id/', wallet.toMap());

      if (response.statusCode == 200) {
        return Right('Wallet update successfully!');
      } else {
        return Left('Failed to update wallet');
      }
    } catch (e) {
      return Left('Failed to update wallet');
    }
  }

  Future<Either<String, String>> deleteWallet(int id) async {
    try {
      final response = await driver.delete('/finance/wallets/$id/');

      if (response.statusCode == 204) {
        return Right(response.body);
      } else {
        return Left("Delete Wallet Failed");
      }
    } catch (e) {
      return Left("Failed to delete wallet");
    }
  }

  Future<Either<String, String>> createTransfer(
    TransferRequestModel transfer,
  ) async {
    try {
      final response = await driver.post(
        '/finance/transfers/',
        transfer.toMap(),
      );

      if (response.statusCode == 201) {
        return Right('Wallet created successfully!');
      } else {
        return Left('Failed to create wallet');
      }
    } catch (e) {
      return Left('Failed to create wallet');
    }
  }
}
