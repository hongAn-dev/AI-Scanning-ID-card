import '../../domain/entities/product_detail.dart';

class ProductDetailModel extends ProductDetail {
  const ProductDetailModel({
    required super.id,
    required super.productCode,
    required super.name,
    required super.groupName,
    required super.branchName,
    required super.description,
    required super.minInStock,
    required super.maxInStock,
    required super.unit,
    required super.unitPrice,
    required super.price,
    required super.inStock,
    required super.groupId,
    required super.isNew,
    required super.isFeature,
    required super.discount,
    required super.picture,
    required super.imageUrls,
    required super.extraLabels,
    required super.extraValues,
    required super.fConvert,
  });

  factory ProductDetailModel.fromJson(Map<String, dynamic> json) {
    return ProductDetailModel(
      id: json['Id'] ?? '',
      productCode: json['ProductCode'] ?? '',
      name: json['Name'] ?? '',
      groupName: json['GroupName'] ?? '',
      branchName: json['BranchName'] ?? '',
      description: json['Description'] ?? '',
      minInStock: (json['MinInStock'] ?? 0).toDouble(),
      maxInStock: (json['MaxInStock'] ?? 0).toDouble(),
      unit: json['Unit'] ?? '',
      unitPrice: (json['UnitPrice'] ?? 0).toDouble(),
      price: (json['Price'] ?? 0).toDouble(),
      inStock: (json['InStock'] ?? 0).toDouble(),
      groupId: json['GroupId'] ?? '',
      isNew: json['IsNew'] ?? false,
      isFeature: json['IsFeature'] ?? false,
      discount: (json['Discount'] ?? 0).toDouble(),
      picture: json['Picture'] ?? '',
      imageUrls: (json['ImageUrls'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      extraLabels: (json['ExtraLabels'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      extraValues: (json['ExtraValues'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      fConvert: (json['f_Convert'] ?? 0).toDouble(),
    );
  }
}

class ProductDetailResponseModel {
  final ProductDetailModel data;
  final MetaModel meta;

  ProductDetailResponseModel({
    required this.data,
    required this.meta,
  });

  factory ProductDetailResponseModel.fromJson(Map<String, dynamic> json) {
    return ProductDetailResponseModel(
      data: ProductDetailModel.fromJson(json['data']),
      meta: MetaModel.fromJson(json['meta']),
    );
  }
}

class MetaModel {
  final int statusCode;
  final String message;

  MetaModel({
    required this.statusCode,
    required this.message,
  });

  factory MetaModel.fromJson(Map<String, dynamic> json) {
    return MetaModel(
      statusCode: json['status_code'] ?? 0,
      message: json['message'] ?? '',
    );
  }
}
