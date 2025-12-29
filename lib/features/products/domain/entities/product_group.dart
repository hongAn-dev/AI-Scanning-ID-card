import 'package:equatable/equatable.dart';

class ProductGroup extends Equatable {
  final String id;
  final String name;
  final String? code;
  final String? description;
  final String? picture;

  const ProductGroup({
    required this.id,
    required this.name,
    this.code,
    this.description,
    this.picture,
  });

  @override
  List<Object?> get props => [id, name, code, description, picture];
}
