part of 'cart_bloc.dart';

abstract class CartEvent extends Equatable {
  const CartEvent();

  @override
  List<Object> get props => [];
}

class LoadCartEvent extends CartEvent {}

class AddToCartEvent extends CartEvent {
  final Product product;

  const AddToCartEvent({required this.product});

  @override
  List<Object> get props => [product];
}

class RemoveFromCartEvent extends CartEvent {
  final String productId;

  const RemoveFromCartEvent({required this.productId});

  @override
  List<Object> get props => [productId];
}

class IncreaseQuantityEvent extends CartEvent {
  final String productId;

  const IncreaseQuantityEvent({required this.productId});

  @override
  List<Object> get props => [productId];
}

class DecreaseQuantityEvent extends CartEvent {
  final String productId;

  const DecreaseQuantityEvent({required this.productId});

  @override
  List<Object> get props => [productId];
}

class UpdateDiscountEvent extends CartEvent {
  final String productId;
  final double discountValue;
  final DiscountType discountType;

  const UpdateDiscountEvent({
    required this.productId,
    required this.discountValue,
    required this.discountType,
  });

  @override
  List<Object> get props => [productId, discountValue, discountType];
}

class UpdateCartItemQuantityEvent extends CartEvent {
  final String productId;
  final int quantity;

  const UpdateCartItemQuantityEvent({
    required this.productId,
    required this.quantity,
  });

  @override
  List<Object> get props => [productId, quantity];
}

class ClearCartEvent extends CartEvent {}
