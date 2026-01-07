import '../entities/customer.dart';
import '../repositories/customer_repository.dart';

class GetCustomers {
  final CustomerRepository repository;
  GetCustomers(this.repository);

  Future<List<Customer>> call() async {
    return repository.getCustomers();
  }
}
