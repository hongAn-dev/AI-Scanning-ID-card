import 'package:equatable/equatable.dart';

class Product extends Equatable {
  final String id;
  final String name;
  final String productCode;
  final String unit;
  final double unitPrice;
  final double price;
  final double inStock;
  final double minInStock;
  final double maxInStock;
  final String branchName;
  final String groupName;
  final String? groupId;
  final String description;
  final String picture;
  final List<String> imageUrls;
  final double discount;
  final bool isNew;
  final bool isFeature;

  const Product({
    required this.id,
    required this.name,
    required this.productCode,
    required this.unit,
    required this.unitPrice,
    required this.price,
    required this.inStock,
    required this.minInStock,
    required this.maxInStock,
    required this.branchName,
    required this.groupName,
    this.groupId,
    required this.description,
    required this.picture,
    required this.imageUrls,
    required this.discount,
    required this.isNew,
    required this.isFeature,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        productCode,
        unit,
        unitPrice,
        price,
        inStock,
        minInStock,
        maxInStock,
        branchName,
        groupName,
        groupId,
        description,
        picture,
        imageUrls,
        discount,
        isNew,
        isFeature,
      ];
}
