import '../../domain/entities/customer.dart';
import '../../domain/entities/customer_group.dart';

class CustomerModel extends Customer {
  const CustomerModel({
    required super.id,
    super.uuid,
    required super.name,
    required super.phone,
    required super.address,
    super.note,
    super.group,
    required super.createdAt,
  });
}

class CustomerGroupModel extends CustomerGroup {
  const CustomerGroupModel({
    required super.id,
    super.uuid,
    super.groupCode,
    required super.name,
    super.description,
  });
}
