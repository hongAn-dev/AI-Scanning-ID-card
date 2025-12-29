import 'package:equatable/equatable.dart';

class CustomerGroup extends Equatable {
  final int id;
  final String? uuid; // UUID from API (Id field)
  final String? groupCode; // GroupCode from API
  final String name; // GroupName from API
  final String? description; // Description from API

  const CustomerGroup({
    required this.id,
    this.uuid,
    this.groupCode,
    required this.name,
    this.description,
  });

  @override
  List<Object?> get props => [id, uuid, groupCode, name, description];
}
