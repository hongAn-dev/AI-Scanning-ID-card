import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/customer.dart';
import '../entities/customer_group.dart';

abstract class CustomerRepository {
  Future<Either<Failure, List<Customer>>> getCustomers({
    String searchText = '',
    String? email,
    String? groupId,
    int pageIndex = 0,
    int pageSize = 20,
  });

  Future<Either<Failure, List<CustomerGroup>>> getCustomerGroups();

  Future<Either<Failure, Customer>> addCustomer(Customer customer);

  Future<Either<Failure, void>> updateCustomer(Customer customer);

  Future<Either<Failure, void>> deleteCustomer(String id);
}
