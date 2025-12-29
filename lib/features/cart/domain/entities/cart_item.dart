import 'package:equatable/equatable.dart';

import '../../../products/domain/entities/product.dart';
import 'discount_type.dart';

class CartItem extends Equatable {
  final Product product;
  final int quantity;
  final double discountValue;
  final DiscountType discountType;

  const CartItem({
    required this.product,
    required this.quantity,
    this.discountValue = 0,
    this.discountType = DiscountType.vnd,
  });

  CartItem copyWith({
    Product? product,
    int? quantity,
    double? discountValue,
    DiscountType? discountType,
  }) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      discountValue: discountValue ?? this.discountValue,
      discountType: discountType ?? this.discountType,
    );
  }

  // Calculate discount amount per item
  double get discountAmount {
    if (discountType == DiscountType.percent) {
      // Percent discount
      final percentage = discountValue.clamp(0, 100);
      return product.price * (percentage / 100);
    } else {
      // VND discount
      return discountValue.clamp(0, product.price);
    }
  }

  // Price after discount per item
  double get priceAfterDiscount => product.price - discountAmount;

  // Total price for all items (quantity * price after discount)
  double get totalPrice => priceAfterDiscount * quantity;

  // Total discount amount for all items
  double get totalDiscount => discountAmount * quantity;

  @override
  List<Object> get props => [product, quantity, discountValue, discountType];
}
