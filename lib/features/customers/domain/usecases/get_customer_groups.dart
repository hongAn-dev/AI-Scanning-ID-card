import '../entities/customer_group.dart';
import '../repositories/customer_repository.dart';

class GetCustomerGroups {
  final CustomerRepository repository;
  GetCustomerGroups(this.repository);

  Future<List<CustomerGroup>> call() async {
    return repository.getCustomerGroups();
  }
}
