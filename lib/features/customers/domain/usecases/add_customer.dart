import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/customer.dart';
import '../repositories/customer_repository.dart';

class AddCustomer {
  final CustomerRepository repository;

  AddCustomer(this.repository);

  Future<Either<Failure, Customer>> call(Customer customer) async {
    return await repository.addCustomer(customer);
  }
}
