import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/order_detail.dart';
import '../repositories/order_repository.dart';

class GetOrderDetail implements UseCase<OrderDetailEntity, String> {
  final OrderRepository repository;

  GetOrderDetail(this.repository);

  @override
  Future<Either<Failure, OrderDetailEntity>> call(String orderId) async {
    return await repository.getOrderDetail(orderId);
  }
}
