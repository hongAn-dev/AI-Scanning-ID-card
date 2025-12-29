import 'package:equatable/equatable.dart';

import 'customer_group.dart';

class Customer extends Equatable {
  final int id;
  final String? uuid; // UUID from API (Id field) - e.g., "7c8880ec-900b-424e-851a-4a995402b1f2"
  final String name;
  final String phone;
  final String address;
  final String? note;
  final CustomerGroup? group;
  final DateTime createdAt;

  const Customer({
    required this.id,
    this.uuid,
    required this.name,
    required this.phone,
    required this.address,
    this.note,
    this.group,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, uuid, name, phone, address, note, group, createdAt];
}
