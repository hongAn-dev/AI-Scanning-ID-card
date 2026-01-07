import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import 'dart:convert';

class CustomerRemoteDataSourceImpl {
  final DioClient dioClient;
  CustomerRemoteDataSourceImpl({required this.dioClient});

  Future<List<Map<String, dynamic>>> fetchCustomers({
    int pageIndex = 0,
    int pageSize = 20,
    String searchText = "",
    String locationId = "",
  }) async {
    try {
      print("🚀 Fetching customers from: ${ApiConstants.customersEndpoint}");
      final response = await dioClient.post(
        ApiConstants.customersEndpoint,
        data: {
          "SearchText": searchText,
          "Email": "",
          "ObjectGroupId": "",
          "ObjectType": -1, // Get All Types
          "Status": false,
          "PageIndex": pageIndex,
          "PageSize": pageSize,
          "LocationId": locationId
        },
      );

      print("✅ Response Code: ${response.statusCode}");
      print("Response Data: ${response.data}");

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'];
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        } else {
          print("⚠️ Data is not a List: $data");
        }
      } else {
        print("❌ Request failed or data null");
      }
      return [];
    } catch (e) {
      print("❌ Error fetching customers: $e");
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchCustomerGroups() async {
    try {
      print(
          "🚀 Fetching customer groups from: ${ApiConstants.customerGroupsEndpoint}");
      final response = await dioClient.get(
        ApiConstants.customerGroupsEndpoint,
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'];
        if (data is List) {
          print("✅ Loaded ${data.length} groups");
          return List<Map<String, dynamic>>.from(data);
        }
      }
      return [];
    } catch (e) {
      print("❌ Error fetching customer groups: $e");
      return [];
    }
  }

  Future<bool> addNewCustomer(Map<String, dynamic> customerBody) async {
    try {
      final response = await dioClient.post(
        ApiConstants.addNewCustomerByCCCDEndpoint,
        data: customerBody,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data != null &&
            data['data'] != null &&
            data['data']['Result'] != null) {
          final result = data['data']['Result'].toString();
          if (result.contains("Could not find stored procedure")) {
            throw Exception("Server Error: $result");
          }
        }
        return true;
      }
      return false;
    } catch (e) {
      print("Error adding customer: $e");
      rethrow;
    }
  }

  Future<bool> updateCustomer(Map<String, dynamic> customerBody) async {
    try {
      print("🚀 Updating customer...");
      print("   -> Endpoint: ${ApiConstants.updateCustomerEndpoint}");
      print("   -> Body: ${jsonEncode(customerBody)}");

      final response = await dioClient.post(
        ApiConstants.updateCustomerEndpoint,
        data: customerBody,
      );

      print("   -> Response Status: ${response.statusCode}");
      print("   -> Response Data: ${response.data}");

      if (response.statusCode == 200) {
        return true;
      }
      return false;
    } catch (e) {
      print("❌ Error updating customer: $e");
      rethrow;
    }
  }

  Future<bool> deleteCustomer(String id) async {
    try {
      final response = await dioClient.post(
        ApiConstants.deleteCustomerEndpoint,
        data: {"ObjectId": id},
      );
      if (response.statusCode == 200) {
        return true;
      }
      return false;
    } catch (e) {
      print("Error deleting customer: $e");
      rethrow;
    }
  }
}
