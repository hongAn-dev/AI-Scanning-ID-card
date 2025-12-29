import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/create_order.dart';
import '../../domain/entities/order_detail.dart';
import '../../domain/repositories/order_repository.dart';
import '../datasources/order_remote_data_source.dart';

class OrderRepositoryImpl implements OrderRepository {
  final OrderRemoteDataSource remoteDataSource;

  OrderRepositoryImpl({
    required this.remoteDataSource,
  });

  @override
  Future<Either<Failure, Map<String, dynamic>>> getOrders({
    int filterType = -1,
    DateTime? fromDate,
    DateTime? toDate,
    String locationId = '',
    int orderStatus = -1,
    String searchByOrderInfo = '',
    int pageSize = 20,
    int pageIndex = 0,
  }) async {
    try {
      final result = await remoteDataSource.getOrders(
        filterType: filterType,
        fromDate: fromDate,
        toDate: toDate,
        locationId: locationId,
        orderStatus: orderStatus,
        searchByOrderInfo: searchByOrderInfo,
        pageSize: pageSize,
        pageIndex: pageIndex,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, OrderDetailEntity>> getOrderDetail(String orderId) async {
    try {
      final result = await remoteDataSource.getOrderDetail(orderId);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> createOrder(CreateOrderRequest request) async {
    try {
      final result = await remoteDataSource.createOrder(request);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
}
