import '../models/customer_model.dart';

abstract class CustomerLocalDataSource {
  List<CustomerModel> getCustomers({int? groupId});
  List<CustomerGroupModel> getCustomerGroups();
  CustomerModel addCustomer(CustomerModel customer);
  void updateCustomer(CustomerModel customer);
  void deleteCustomer(int id);
}

class CustomerLocalDataSourceImpl implements CustomerLocalDataSource {
  // In-memory storage - không lưu vào database
  static final List<CustomerModel> _customers = [];
  static final List<CustomerGroupModel> _groups = [];
  static int _nextId = 1;

  @override
  List<CustomerModel> getCustomers({int? groupId}) {
    if (groupId != null) {
      return _customers
          .where((customer) => customer.group?.id == groupId)
          .toList();
    }
    return List.from(_customers);
  }

  @override
  List<CustomerGroupModel> getCustomerGroups() {
    return List.from(_groups);
  }

  @override
  CustomerModel addCustomer(CustomerModel customer) {
    final newCustomer = CustomerModel(
      id: _nextId++,
      name: customer.name,
      phone: customer.phone,
      address: customer.address,
      note: customer.note,
      group: customer.group,
      createdAt: DateTime.now(),
    );

    _customers.add(newCustomer);
    return newCustomer;
  }

  @override
  void updateCustomer(CustomerModel customer) {
    final index = _customers.indexWhere((c) => c.id == customer.id);
    if (index >= 0) {
      _customers[index] = customer;
    }
  }

  @override
  void deleteCustomer(int id) {
    _customers.removeWhere((customer) => customer.id == id);
  }
}
