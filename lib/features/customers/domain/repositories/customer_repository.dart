import '../entities/customer.dart';
import '../entities/customer_group.dart';

abstract class CustomerRepository {
  Future<List<Customer>> getCustomers(
      {int pageIndex = 0, int pageSize = 20, String searchText = ""});
  Future<List<CustomerGroup>> getCustomerGroups();
  Future<void> addCustomer(Customer customer);
  Future<void> updateCustomer(Customer customer);
  Future<bool> checkCustomerExists(
      String identityNumber, String code, String name);
  Future<void> deleteCustomer(String id);
}
