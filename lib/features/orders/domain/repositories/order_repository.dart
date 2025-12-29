import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/create_order.dart';
import '../entities/order_detail.dart';

abstract class OrderRepository {
  Future<Either<Failure, Map<String, dynamic>>> getOrders({
    int filterType = -1,
    DateTime? fromDate,
    DateTime? toDate,
    String locationId = '',
    int orderStatus = -1,
    String searchByOrderInfo = '',
    int pageSize = 20,
    int pageIndex = 0,
  });

  Future<Either<Failure, OrderDetailEntity>> getOrderDetail(String orderId);

  Future<Either<Failure, Map<String, dynamic>>> createOrder(CreateOrderRequest request);
}
