import 'package:masterpro_ai_scan_id/features/auth/data/auth_service.dart';

import 'package:masterpro_ai_scan_id/features/customers/domain/entities/customer.dart';
import 'package:masterpro_ai_scan_id/features/customers/domain/entities/customer_group.dart';
import 'package:masterpro_ai_scan_id/features/customers/domain/repositories/customer_repository.dart';

// Fake AuthService
class FakeAuthService implements AuthService {
  @override
  bool isDemoMode() {
    return false; // Default to false for tests
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    // Return null or throw depending on need. For widget test, usually explicit overrides are enough.
    throw UnimplementedError(
        "Method ${invocation.memberName} not implemented in FakeAuthService");
  }
}

// Fake CustomerRepository
class FakeCustomerRepository implements CustomerRepository {
  @override
  Future<List<CustomerGroup>> getCustomerGroups() async {
    return [
      CustomerGroup(id: "1", name: "Chi nhánh Hà Nội"),
      CustomerGroup(id: "2", name: "Chi nhánh HCM"),
    ];
  }

  @override
  Future<List<Customer>> getCustomers(
      {int pageIndex = 0, int pageSize = 20, String searchText = ""}) async {
    return [];
  }

  @override
  Future<void> addCustomer(Customer customer) async {
    return;
  }

  @override
  Future<void> updateCustomer(Customer customer) async {
    return;
  }

  @override
  Future<bool> checkCustomerExists(
      String identityNumber, String code, String name) async {
    return false;
  }

  @override
  Future<void> deleteCustomer(String id) async {
    return;
  }
}
