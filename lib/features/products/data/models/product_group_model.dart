import '../../domain/entities/product_group.dart';

class ProductGroupModel extends ProductGroup {
  const ProductGroupModel({
    required super.id,
    required super.name,
    super.code,
    super.description,
    super.picture,
  });

  factory ProductGroupModel.fromJson(Map<String, dynamic> json) {
    return ProductGroupModel(
      id: (json['Id'] ?? json['id'] ?? '').toString(),
      name:
          (json['GroupName'] ?? json['Name'] ?? json['name'] ?? '').toString(),
      code: (json['GroupCode'] ?? json['code'])?.toString(),
      description: (json['Description'] ?? json['desc'])?.toString(),
      picture: (json['Picture'] ?? json['picture'])?.toString(),
    );
  }
}
