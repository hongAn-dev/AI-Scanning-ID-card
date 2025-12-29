import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/order_repository.dart';

class GetOrders implements UseCase<Map<String, dynamic>, GetOrdersParams> {
  final OrderRepository repository;

  GetOrders(this.repository);

  @override
  Future<Either<Failure, Map<String, dynamic>>> call(GetOrdersParams params) async {
    return await repository.getOrders(
      filterType: params.filterType,
      fromDate: params.fromDate,
      toDate: params.toDate,
      locationId: params.locationId,
      orderStatus: params.orderStatus,
      searchByOrderInfo: params.searchByOrderInfo,
      pageSize: params.pageSize,
      pageIndex: params.pageIndex,
    );
  }
}

class GetOrdersParams {
  final int filterType;
  final DateTime? fromDate;
  final DateTime? toDate;
  final String locationId;
  final int orderStatus;
  final String searchByOrderInfo;
  final int pageSize;
  final int pageIndex;

  GetOrdersParams({
    this.filterType = -1,
    this.fromDate,
    this.toDate,
    this.locationId = '',
    this.orderStatus = -1,
    this.searchByOrderInfo = '',
    this.pageSize = 20,
    this.pageIndex = 0,
  });
}
