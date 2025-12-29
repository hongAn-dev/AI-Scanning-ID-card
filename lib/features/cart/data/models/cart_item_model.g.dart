// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cart_item_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CartItemModel _$CartItemModelFromJson(Map<String, dynamic> json) =>
    CartItemModel(
      product: ProductModel.fromJson(json['product'] as Map<String, dynamic>),
      quantity: (json['quantity'] as num).toInt(),
      discountValue: (json['discountValue'] as num?)?.toDouble() ?? 0,
      discountType: json['discountType'] != null
          ? DiscountType.values.byName(json['discountType'] as String)
          : DiscountType.vnd,
    );

Map<String, dynamic> _$CartItemModelToJson(CartItemModel instance) =>
    <String, dynamic>{
      'product': (instance.product as ProductModel).toJson(),
      'quantity': instance.quantity,
      'discountValue': instance.discountValue,
      'discountType': instance.discountType.name,
    };
