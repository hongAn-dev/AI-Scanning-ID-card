import 'package:equatable/equatable.dart';

class ProductDetail extends Equatable {
  final String id;
  final String productCode;
  final String name;
  final String groupName;
  final String branchName;
  final String description;
  final double minInStock;
  final double maxInStock;
  final String unit;
  final double unitPrice;
  final double price;
  final double inStock;
  final String groupId;
  final bool isNew;
  final bool isFeature;
  final double discount;
  final String picture;
  final List<String> imageUrls;
  final List<String> extraLabels;
  final List<String> extraValues;
  final double fConvert;

  const ProductDetail({
    required this.id,
    required this.productCode,
    required this.name,
    required this.groupName,
    required this.branchName,
    required this.description,
    required this.minInStock,
    required this.maxInStock,
    required this.unit,
    required this.unitPrice,
    required this.price,
    required this.inStock,
    required this.groupId,
    required this.isNew,
    required this.isFeature,
    required this.discount,
    required this.picture,
    required this.imageUrls,
    required this.extraLabels,
    required this.extraValues,
    required this.fConvert,
  });

  @override
  List<Object?> get props => [
        id,
        productCode,
        name,
        groupName,
        branchName,
        description,
        minInStock,
        maxInStock,
        unit,
        unitPrice,
        price,
        inStock,
        groupId,
        isNew,
        isFeature,
        discount,
        picture,
        imageUrls,
        extraLabels,
        extraValues,
        fConvert,
      ];
}
