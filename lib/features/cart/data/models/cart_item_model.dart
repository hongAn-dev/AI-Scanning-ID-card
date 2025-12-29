import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

import '../../../products/data/models/product_model.dart';
import '../../../products/domain/entities/product.dart';
import '../../domain/entities/cart_item.dart';
import '../../domain/entities/discount_type.dart';

part 'cart_item_model.g.dart';

@JsonSerializable(explicitToJson: true)
class CartItemModel extends CartItem {
  const CartItemModel({
    required super.product,
    required super.quantity,
    super.discountValue,
    super.discountType,
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) => _$CartItemModelFromJson(json);

  Map<String, dynamic> toJson() => _$CartItemModelToJson(this);

  // Convert from database row
  factory CartItemModel.fromDatabase({
    required String id,
    required Map<String, dynamic> productData,
    required int quantity,
  }) {
    return CartItemModel(
      product: ProductModel.fromJson(productData),
      quantity: quantity,
      // Discount không được lưu trong DB, luôn reset về 0
      discountValue: 0,
      discountType: DiscountType.vnd,
    );
  }

  // Convert to database row (không lưu discount)
  Map<String, dynamic> toDatabase() {
    return {
      'product_id': product.id,
      'product_data': jsonEncode((product as ProductModel).toJson()),
      'quantity': quantity,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  @override
  CartItemModel copyWith({
    Product? product,
    int? quantity,
    double? discountValue,
    DiscountType? discountType,
  }) {
    return CartItemModel(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      discountValue: discountValue ?? this.discountValue,
      discountType: discountType ?? this.discountType,
    );
  }
}
