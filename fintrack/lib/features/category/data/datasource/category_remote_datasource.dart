import 'package:dartz/dartz.dart';
import 'dart:convert';
import 'package:fintrack/core/config/api_driver.dart';
import 'package:fintrack/features/category/data/models/category_item_model.dart';
import 'package:fintrack/features/category/data/models/request/category_request_model.dart';
import 'package:fintrack/features/category/data/models/response/list_category_response_model.dart';

class CategoryRemoteDatasource {
  final APIDriver driver = APIDriver();

  Future<Either<String, ListCategoryResponseModel>> getCategories() async {
    try {
      final response = await driver.get('/finance/categories/');

      print("GET CATEGORIES RESPONSE STATUS: ${response.statusCode}");
      print(
        "GET CATEGORIES RESPONSE BODY: ${response.body}",
      ); 

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData =
            jsonDecode(response.body) as Map<String, dynamic>;
        return Right(ListCategoryResponseModel.fromJson(responseData));
      } else {
        String errorMessage =
            'Failed to load categories. Status: ${response.statusCode}';
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
      print("EXCEPTION IN getCategories: $e");
      return Left('Failed to load categories: ${e.toString()}');
    }
  }

  Future<Either<String, String>> createCategory(
    CategoryRequestModel categoryRequest,
  ) async {
    try {
      final response = await driver.post(
        '/finance/categories/',
        categoryRequest.toMap(),
      );

      print("CREATE CATEGORY RESPONSE STATUS: ${response.statusCode}");
      print("CREATE CATEGORY RESPONSE BODY: ${response.body}");

      if (response.statusCode == 201) {
        return Right('Category created successfully!');
      } else {
        String errorMessage =
            'Failed to create category. Status: ${response.statusCode}. ';
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
          errorMessage += ' (Invalid error response)';
        }
        return Left(errorMessage);
      }
    } catch (e) {
      print("EXCEPTION IN createCategory: $e");
      return Left('Failed to create category: ${e.toString()}');
    }
  }

  Future<Either<String, CategoryItemModel>> detailCategory(int id) async {
    try {
      final response = await driver.get('/finance/categories/$id/');

      print("GET CATEGORY DETAIL RESPONSE STATUS: ${response.statusCode}");
      print("GET CATEGORY DETAIL RESPONSE BODY: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedJson =
            jsonDecode(response.body) as Map<String, dynamic>;
        return Right(CategoryItemModel.fromJson(decodedJson));
      } else {
        String errorMessage =
            'Failed to load category details. Status: ${response.statusCode}. ';
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
          errorMessage += '(Invalid error response)';
        }
        return Left(errorMessage);
      }
    } catch (e) {
      print("EXCEPTION IN detailCategory: $e");
      return Left('Failed to load category details: ${e.toString()}');
    }
  }

  Future<Either<String, String>> updateCategory(
    CategoryRequestModel categoryRequest,
    int id,
  ) async {
    try {
      final response = await driver.put(
        '/finance/categories/$id/',
        categoryRequest.toMap(),
      );

      print("UPDATE CATEGORY RESPONSE STATUS: ${response.statusCode}");
      print("UPDATE CATEGORY RESPONSE BODY: ${response.body}");

      if (response.statusCode == 200) {
        return Right('Category updated successfully!');
      } else {
        String errorMessage =
            'Failed to update category. Status: ${response.statusCode}. ';
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
          errorMessage += '(Invalid error response)';
        }
        return Left(errorMessage);
      }
    } catch (e) {
      print("EXCEPTION IN updateCategory: $e");
      return Left('Failed to update category: ${e.toString()}');
    }
  }

  Future<Either<String, String>> deleteCategory(int id) async {
    try {
      final response = await driver.delete('/finance/categories/$id/');

      print("DELETE CATEGORY RESPONSE STATUS: ${response.statusCode}");
      print("DELETE CATEGORY RESPONSE BODY: ${response.body}");

      if (response.statusCode == 204) {
        return Right('Category deleted successfully!');
      } else if (response.statusCode == 200) {
        return Right('Category deleted successfully!');
      } else {
        String errorMessage =
            'Failed to delete category. Status: ${response.statusCode}. ';
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
          errorMessage += '(Invalid error response)';
        }
        return Left(errorMessage);
      }
    } catch (e) {
      print("EXCEPTION IN deleteCategory: $e");
      return Left('Failed to delete category: ${e.toString()}');
    }
  }

  Future<Either<String, List<CategoryItemModel>>> getIncomeCategories() async {
    try {
      final response = await driver.get('/finance/categories/income/');
      print("GET INCOME CATEGORIES RESPONSE STATUS: ${response.statusCode}");
      print(
        "GET INCOME CATEGORIES RESPONSE BODY: ${response.body}",
      ); 

      if (response.statusCode == 200) {
        final List<dynamic> responseList =
            jsonDecode(response.body) as List<dynamic>;
        final List<CategoryItemModel> categories =
            responseList
                .map(
                  (x) => CategoryItemModel.fromJson(x as Map<String, dynamic>),
                )
                .toList();
        return Right(categories);
      } else {
        String errorMessage =
            'Failed to load income categories. Status: ${response.statusCode}. ';
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
          errorMessage += '(Invalid error response)';
        }
        return Left(errorMessage);
      }
    } catch (e) {
      print("EXCEPTION IN getIncomeCategories: $e");
      return Left('Failed to load income categories: ${e.toString()}');
    }
  }

  Future<Either<String, List<CategoryItemModel>>> getExpenseCategories() async {
    try {
      final response = await driver.get('/finance/categories/expense/');
      print("GET EXPENSE CATEGORIES RESPONSE STATUS: ${response.statusCode}");
      print(
        "GET EXPENSE CATEGORIES RESPONSE BODY: ${response.body}",
      ); // <--- Lihat di sini!

      if (response.statusCode == 200) {
        final List<dynamic> responseList =
            jsonDecode(response.body) as List<dynamic>;
        final List<CategoryItemModel> categories =
            responseList
                .map(
                  (x) => CategoryItemModel.fromJson(x as Map<String, dynamic>),
                )
                .toList();
        return Right(categories);
      } else {
        String errorMessage =
            'Failed to load expense categories. Status: ${response.statusCode}. ';
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
          errorMessage += '(Invalid error response)';
        }
        return Left(errorMessage);
      }
    } catch (e) {
      print("EXCEPTION IN getExpenseCategories: $e");
      return Left('Failed to load expense categories: ${e.toString()}');
    }
  }
}
