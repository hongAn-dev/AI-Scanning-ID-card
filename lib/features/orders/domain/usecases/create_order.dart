import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/create_order.dart';
import '../repositories/order_repository.dart';

class CreateOrder implements UseCase<Map<String, dynamic>, CreateOrderRequest> {
  final OrderRepository repository;

  CreateOrder(this.repository);

  @override
  Future<Either<Failure, Map<String, dynamic>>> call(CreateOrderRequest request) async {
    return await repository.createOrder(request);
  }
}
