import '../../domain/entities/product.dart';

class ProductModel extends Product {
  const ProductModel({
    required super.id,
    required super.name,
    required super.productCode,
    required super.unit,
    required super.unitPrice,
    required super.price,
    required super.inStock,
    required super.minInStock,
    required super.maxInStock,
    required super.branchName,
    required super.groupName,
    super.groupId,
    required super.description,
    required super.picture,
    required super.imageUrls,
    required super.discount,
    required super.isNew,
    required super.isFeature,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['Id'] ?? '',
      name: json['Name'] ?? '',
      productCode: json['ProductCode'] ?? '',
      unit: json['Unit'] ?? '',
      unitPrice: (json['UnitPrice'] ?? 0).toDouble(),
      price: (json['Price'] ?? 0).toDouble(),
      inStock: (json['InStock'] ?? 0).toDouble(),
      minInStock: (json['MinInStock'] ?? 0).toDouble(),
      maxInStock: (json['MaxInStock'] ?? 0).toDouble(),
      branchName: json['BranchName'] ?? '',
      groupName: json['GroupName'] ?? '',
      groupId: json['GroupId'],
      description: json['Description'] ?? '',
      picture: json['Picture'] ?? '',
      imageUrls:
          json['ImageUrls'] != null ? List<String>.from(json['ImageUrls']) : [],
      discount: (json['Discount'] ?? 0).toDouble(),
      isNew: json['IsNew'] ?? false,
      isFeature: json['IsFeature'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Id': id,
      'Name': name,
      'ProductCode': productCode,
      'Unit': unit,
      'UnitPrice': unitPrice,
      'Price': price,
      'InStock': inStock,
      'MinInStock': minInStock,
      'MaxInStock': maxInStock,
      'BranchName': branchName,
      'GroupName': groupName,
      'GroupId': groupId,
      'Description': description,
      'Picture': picture,
      'ImageUrls': imageUrls,
      'Discount': discount,
      'IsNew': isNew,
      'IsFeature': isFeature,
    };
  }

  Product toEntity() {
    return Product(
      id: id,
      name: name,
      productCode: productCode,
      unit: unit,
      unitPrice: unitPrice,
      price: price,
      inStock: inStock,
      minInStock: minInStock,
      maxInStock: maxInStock,
      branchName: branchName,
      groupName: groupName,
      groupId: groupId,
      description: description,
      picture: picture,
      imageUrls: imageUrls,
      discount: discount,
      isNew: isNew,
      isFeature: isFeature,
    );
  }
}

class ProductResponse {
  final List<ProductModel> products;
  final PagingInfo paging;
  final Meta meta;

  const ProductResponse({
    required this.products,
    required this.paging,
    required this.meta,
  });

  factory ProductResponse.fromJson(Map<String, dynamic> json) {
    return ProductResponse(
      products: (json['data'] as List<dynamic>?)
              ?.map((item) => ProductModel.fromJson(item))
              .toList() ??
          [],
      paging: PagingInfo.fromJson(json['paging'] ?? {}),
      meta: Meta.fromJson(json['meta'] ?? {}),
    );
  }
}

class PagingInfo {
  final int totalPage;
  final int pageIndex;
  final int pageSize;
  final int totalCount;

  const PagingInfo({
    required this.totalPage,
    required this.pageIndex,
    required this.pageSize,
    required this.totalCount,
  });

  factory PagingInfo.fromJson(Map<String, dynamic> json) {
    return PagingInfo(
      totalPage: json['TotalPage'] ?? 0,
      pageIndex: json['PageIndex'] ?? 0,
      pageSize: json['PageSize'] ?? 0,
      totalCount: json['TotalCount'] ?? 0,
    );
  }
}

class Meta {
  final int statusCode;
  final String message;

  const Meta({
    required this.statusCode,
    required this.message,
  });

  factory Meta.fromJson(Map<String, dynamic> json) {
    return Meta(
      statusCode: json['status_code'] ?? 0,
      message: json['message'] ?? '',
    );
  }
}
