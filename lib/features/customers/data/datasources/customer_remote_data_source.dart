import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../models/customer_model.dart';
import '../models/customer_remote_model.dart';

abstract class CustomerRemoteDataSource {
  /// Calls the api/Category/CustomerList endpoint
  ///
  /// Throws a [ServerException] for all error codes.
  Future<List<CustomerModel>> getCustomers({
    String searchText = '',
    String? email,
    String? groupId,
    int pageIndex = 0,
    int pageSize = 20,
  });

  /// Calls the api/Category/CustomerGroupList endpoint
  ///
  /// Throws a [ServerException] for all error codes.
  Future<List<CustomerGroupModel>> getCustomerGroups();

  /// Calls the api/Category/GetNewCustomerCode endpoint
  ///
  /// Throws a [ServerException] for all error codes.
  Future<String> getNewCustomerCode();

  /// Calls the api/Category/AddNewCustomer endpoint
  ///
  /// Throws a [ServerException] for all error codes.
  Future<CustomerModel> addNewCustomer({
    required String fullname,
    required String mobile,
    required String address,
    String? groupId,
    String? note,
  });
}

class CustomerRemoteDataSourceImpl implements CustomerRemoteDataSource {
  final DioClient dioClient;

  CustomerRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<List<CustomerModel>> getCustomers({
    String searchText = '',
    String? email,
    String? groupId,
    int pageIndex = 0,
    int pageSize = 20,
  }) async {
    final Map<String, dynamic> body = {
      'SearchText': searchText,
      'Email': email ?? '',
      'ObjectGroupId': groupId ?? '',
      'ObjectType': 0,
      'Status': false,
      'PageIndex': pageIndex,
      'PageSize': pageSize
    };

    try {
      final response = await dioClient.post(
        '${ApiConstants.baseUrl}${ApiConstants.customersEndpoint}',
        data: body,
      );

      if (response.statusCode == 200) {
        final customerResponse = CustomerResponseModel.fromJson(response.data);

        if (customerResponse.meta.statusCode == 0) {
          return customerResponse.data
              .map((remoteModel) => remoteModel.toCustomerModel())
              .toList();
        } else {
          throw ServerException(customerResponse.meta.message);
        }
      } else {
        throw ServerException('Failed to load customers');
      }
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Failed to load customers');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<CustomerGroupModel>> getCustomerGroups() async {
    try {
      final response = await dioClient.get(
        ApiConstants.customerGroupsEndpoint,
      );

      if (response.statusCode == 200) {
        final groupResponse =
            CustomerGroupResponseModel.fromJson(response.data);

        if (groupResponse.meta.statusCode == 0) {
          return groupResponse.data
              .map((remoteModel) => remoteModel.toCustomerGroupModel())
              .toList();
        } else {
          throw ServerException(groupResponse.meta.message);
        }
      } else {
        throw ServerException('Failed to load customer groups');
      }
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Failed to load customer groups');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<String> getNewCustomerCode() async {
    try {
      final response = await dioClient.get(
        ApiConstants.getNewCustomerCodeEndpoint,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['data'] != null && data['data']['NewCode'] != null) {
          return data['data']['NewCode'] as String;
        } else {
          throw ServerException('Failed to get new customer code');
        }
      } else {
        throw ServerException('Failed to get new customer code');
      }
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Failed to get new customer code');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<CustomerModel> addNewCustomer({
    required String fullname,
    required String mobile,
    required String address,
    String? groupId,
    String? note,
  }) async {
    try {
      // First, get the new customer code
      final code = await getNewCustomerCode();

      // Prepare request body
      final Map<String, dynamic> body = {
        'CustomerCode': code,
        'CustomerName': fullname,
        'BirthDay': DateTime.now().toIso8601String(),
        'GroupId': groupId ?? '',
        'Address': address,
        'Tel': mobile,
        'Email': '',
        'Description': note ?? '',
        'Avatar': '',
        'TaxCode': '',
        'Longitude': 0,
        'Latitude': 0,
        'Password': '1',
      };

      // Call add customer API
      final response = await dioClient.post(
        ApiConstants.addNewCustomerEndpoint,
        data: body,
      );

      if (response.statusCode == 200) {
        final data = response.data;

        if (data['meta'] != null && data['meta']['status_code'] == 0) {
          if (data['data'] != null) {
            final customerRemote = CustomerRemoteModel.fromJson(data['data']);
            return customerRemote.toCustomerModel();
          } else {
            throw ServerException('No customer data returned');
          }
        } else {
          throw ServerException(
            data['meta']?['message'] ?? 'Failed to add customer',
          );
        }
      } else {
        throw ServerException('Failed to add customer');
      }
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Failed to add customer');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
