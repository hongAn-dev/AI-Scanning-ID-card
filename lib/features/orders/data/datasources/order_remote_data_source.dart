import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/create_order.dart';
import '../models/order_detail_model.dart';
import '../models/order_remote_model.dart';

abstract class OrderRemoteDataSource {
  /// Calls the order history endpoint
  ///
  /// Throws a [ServerException] for all error codes.
  Future<Map<String, dynamic>> getOrders({
    int filterType = -1,
    DateTime? fromDate,
    DateTime? toDate,
    String locationId = '',
    int orderStatus = -1,
    String searchByOrderInfo = '',
    int pageSize = 10,
    int pageIndex = 0,
  });

  /// Calls the order detail endpoint
  ///
  /// Throws a [ServerException] for all error codes.
  Future<OrderDetailModel> getOrderDetail(String orderId);

  /// Get new order code
  ///
  /// Throws a [ServerException] for all error codes.
  Future<String> getNewOrderCode();

  /// Create new order
  ///
  /// Throws a [ServerException] for all error codes.
  Future<Map<String, dynamic>> createOrder(CreateOrderRequest request);
}

class OrderRemoteDataSourceImpl implements OrderRemoteDataSource {
  final DioClient dioClient;

  OrderRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<Map<String, dynamic>> getOrders({
    int filterType = -1,
    DateTime? fromDate,
    DateTime? toDate,
    String locationId = '',
    int orderStatus = -1,
    String searchByOrderInfo = '',
    int pageSize = 20,
    int pageIndex = 0,
  }) async {
    final now = DateTime.now();
    final Map<String, dynamic> body = {
      'FilterType': filterType,
      'FromDate': (fromDate ?? now).toIso8601String(),
      'ToDate': (toDate ?? now).toIso8601String(),
      'LocationId': locationId,
      'OrderStatus': orderStatus,
      'SearchByOrderInfo': searchByOrderInfo,
      'SearchByCustomerInfo': '',
      'SearchByProductInfo': '',
      'PageSize': pageSize,
      'PageIndex': pageIndex,
    };

    try {
      final response = await dioClient.post(
        '${ApiConstants.baseUrl}${ApiConstants.orderHistoryEndpoint}',
        data: body,
      );

      if (response.statusCode == 200) {
        final orderResponse = OrderResponseModel.fromJson(response.data);

        if (orderResponse.meta.statusCode == 0) {
          final orders = orderResponse.data.map((remoteModel) => remoteModel.toOrderModel()).toList();

          return {
            'orders': orders,
            'paging': orderResponse.paging,
            'extra': orderResponse.extra,
          };
        } else {
          throw ServerException(orderResponse.meta.message);
        }
      } else {
        throw ServerException('Failed to load orders');
      }
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Failed to load orders');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<OrderDetailModel> getOrderDetail(String orderId) async {
    try {
      final response = await dioClient.get(
        '${ApiConstants.baseUrl}${ApiConstants.orderDetailEndpoint}/$orderId',
      );

      if (response.statusCode == 200) {
        final orderDetailResponse = OrderDetailResponseModel.fromJson(response.data);

        if (orderDetailResponse.meta.statusCode == 0) {
          return orderDetailResponse.data;
        } else {
          throw ServerException(orderDetailResponse.meta.message);
        }
      } else {
        throw ServerException('Failed to load order detail');
      }
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Failed to load order detail');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<String> getNewOrderCode() async {
    try {
      final response = await dioClient.get(
        '${ApiConstants.baseUrl}${ApiConstants.getNewOrderCodeEndpoint}',
      );

      if (response.statusCode == 200) {
        final data = response.data['data'];
        if (data != null && data['NewCode'] != null) {
          return data['NewCode'] as String;
        } else {
          throw ServerException('Failed to get new order code');
        }
      } else {
        throw ServerException('Failed to get new order code');
      }
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Failed to get new order code');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<Map<String, dynamic>> createOrder(CreateOrderRequest request) async {
    try {
      // First get new order code
      final orderCode = await getNewOrderCode();

      // Build order detail list
      final orderDetails = request.products.map((product) {
        return {
          'ProductId': product.productId,
          'ProductName': product.productName,
          'Price': product.price,
          'Qty': product.qty,
          'Unit': product.unit,
          'f_Convert': product.fConvert,
          'f_Discount': product.fDiscount,
          'm_Discount': product.mDiscount,
          'Description': product.description,
          'StoreId': product.storeId,
        };
      }).toList();

      // Format date
      final dateFormat = DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS");

      // Build request body
      final Map<String, dynamic> body = {
        'OrderCode': orderCode,
        'EmployeeId': request.employeeId,
        'f_Discount': request.fDiscount,
        'm_Discount': request.mDiscount,
        'OrderTotalDiscount': request.orderTotalDiscount,
        'OrderTotal': request.orderTotal,
        'm_TotalMoney': request.mTotalMoney,
        'ShippingAddress': request.shippingAddress,
        'BillingAddress': request.billingAddress,
        'Description': request.description,
        'Status': request.status,
        'f_Vat': request.fVat,
        'm_Vat': request.mVat,
        'OrderDate': dateFormat.format(request.orderDate),
        'CustomerId': request.customerId,
        'CreatedBy': request.createdBy,
        'ModifiedBy': request.modifiedBy,
        'CreatedDate': dateFormat.format(request.createdDate),
        'ModifiedDate': dateFormat.format(request.modifiedDate),
        'Location_Id': request.locationId,
        'OrderDetail': orderDetails,
      };

      // Call API
      final response = await dioClient.post(
        '${ApiConstants.baseUrl}${ApiConstants.createOrderEndpoint}',
        data: body,
      );

      if (response.statusCode == 200) {
        final meta = response.data['meta'];
        if (meta != null && meta['status_code'] == 0) {
          return {
            'success': true,
            'message': meta['message'] ?? 'Tạo đơn hàng thành công',
            'orderCode': orderCode,
            'data': response.data['data'],
          };
        } else {
          throw ServerException(meta?['message'] ?? 'Failed to create order');
        }
      } else {
        throw ServerException('Failed to create order');
      }
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Failed to create order');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
