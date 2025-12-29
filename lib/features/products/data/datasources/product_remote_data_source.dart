import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../models/product_detail_model.dart';
import '../models/product_group_model.dart';
import '../models/product_model.dart';

abstract class ProductRemoteDataSource {
  Future<List<ProductModel>> getProducts({
    String? productName,
    String? productCode,
    String? productGroupId,
    int pageSize = 50,
    int pageIndex = 0,
  });
  Future<ProductModel> getProductById(int id);
  Future<ProductDetailModel> getProductDetail(String productId);
  Future<List<ProductModel>> getProductsByCategory(String category);
  Future<List<ProductGroupModel>> getProductGroups();
}

class ProductRemoteDataSourceImpl implements ProductRemoteDataSource {
  final DioClient dioClient;

  ProductRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<List<ProductModel>> getProducts({
    String? productName,
    String? productCode,
    String? productGroupId,
    int pageSize = 50,
    int pageIndex = 0,
  }) async {
    try {
      final response = await dioClient.post(
        '${ApiConstants.baseUrl}${ApiConstants.productsEndpoint}',
        data: {
          'ProductName': productName ?? '',
          'ProductCode': productCode ?? '',
          'Visible': true,
          'Instock': -1,
          'ProductGroup': productGroupId ?? '',
          'PageSize': pageSize,
          'PageIndex': pageIndex,
        },
      );

      if (response.statusCode == 200) {
        // Handle response data - may be wrapped in 'data' field
        final responseData = response.data;
        final List<dynamic> data =
            responseData is List ? responseData : (responseData['data'] ?? responseData['Data'] ?? []);

        return data.map((json) => ProductModel.fromJson(json)).toList();
      } else {
        throw ServerException('Failed to load products');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
        throw NetworkException('Connection timeout');
      } else if (e.type == DioExceptionType.connectionError) {
        throw NetworkException('No internet connection');
      } else {
        throw ServerException(e.message ?? 'Server error occurred');
      }
    } catch (e) {
      throw ServerException('Unexpected error occurred: $e');
    }
  }

  @override
  Future<List<ProductGroupModel>> getProductGroups() async {
    try {
      final response = await dioClient.get(
        '${ApiConstants.baseUrl}${ApiConstants.productGroupsEndpoint}',
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        final List<dynamic> data =
            responseData is List ? responseData : (responseData['data'] ?? responseData['Data'] ?? []);
        return data.map((e) => ProductGroupModel.fromJson(e)).toList();
      } else {
        throw ServerException('Failed to load product groups');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
        throw NetworkException('Connection timeout');
      } else if (e.type == DioExceptionType.connectionError) {
        throw NetworkException('No internet connection');
      } else {
        throw ServerException(e.message ?? 'Server error occurred');
      }
    } catch (e) {
      throw ServerException('Unexpected error occurred: $e');
    }
  }

  @override
  Future<ProductModel> getProductById(int id) async {
    try {
      final response = await dioClient.get(
        '${ApiConstants.baseUrl}${ApiConstants.productsEndpoint}/$id',
      );

      if (response.statusCode == 200) {
        // Handle response data - may be wrapped in 'data' field
        final responseData = response.data;
        final data =
            responseData is Map ? (responseData['data'] ?? responseData['Data'] ?? responseData) : responseData;

        return ProductModel.fromJson(data);
      } else {
        throw ServerException('Failed to load product');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
        throw NetworkException('Connection timeout');
      } else if (e.type == DioExceptionType.connectionError) {
        throw NetworkException('No internet connection');
      } else {
        throw ServerException(e.message ?? 'Server error occurred');
      }
    } catch (e) {
      throw ServerException('Unexpected error occurred: $e');
    }
  }

  @override
  Future<ProductDetailModel> getProductDetail(String productId) async {
    try {
      final response = await dioClient.get(
        '${ApiConstants.baseUrl}${ApiConstants.productDetailEndpoint}/$productId',
      );

      if (response.statusCode == 200) {
        final productDetailResponse = ProductDetailResponseModel.fromJson(response.data);

        if (productDetailResponse.meta.statusCode == 0) {
          return productDetailResponse.data;
        } else {
          throw ServerException(productDetailResponse.meta.message);
        }
      } else {
        throw ServerException('Failed to load product detail');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
        throw NetworkException('Connection timeout');
      } else if (e.type == DioExceptionType.connectionError) {
        throw NetworkException('No internet connection');
      } else {
        throw ServerException(e.message ?? 'Server error occurred');
      }
    } catch (e) {
      throw ServerException('Unexpected error occurred: $e');
    }
  }

  @override
  Future<List<ProductModel>> getProductsByCategory(String category) async {
    try {
      final response = await dioClient.get(
        '${ApiConstants.baseUrl}${ApiConstants.productsEndpoint}/category/$category',
      );

      if (response.statusCode == 200) {
        // Handle response data - may be wrapped in 'data' field
        final responseData = response.data;
        final List<dynamic> data =
            responseData is List ? responseData : (responseData['data'] ?? responseData['Data'] ?? []);

        return data.map((json) => ProductModel.fromJson(json)).toList();
      } else {
        throw ServerException('Failed to load products');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
        throw NetworkException('Connection timeout');
      } else if (e.type == DioExceptionType.connectionError) {
        throw NetworkException('No internet connection');
      } else {
        throw ServerException(e.message ?? 'Server error occurred');
      }
    } catch (e) {
      throw ServerException('Unexpected error occurred: $e');
    }
  }
}
