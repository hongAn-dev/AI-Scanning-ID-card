import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/customer_group.dart';
import '../repositories/customer_repository.dart';

class GetCustomerGroups implements UseCase<List<CustomerGroup>, NoParams> {
  final CustomerRepository repository;

  GetCustomerGroups(this.repository);

  @override
  Future<Either<Failure, List<CustomerGroup>>> call(NoParams params) async {
    return await repository.getCustomerGroups();
  }
}
