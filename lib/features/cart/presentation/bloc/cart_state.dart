part of 'cart_bloc.dart';

class CartState extends Equatable {
  final List<CartItem> items;
  final double totalAmount;

  const CartState({
    required this.items,
    required this.totalAmount,
  });

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  @override
  List<Object> get props => [items, totalAmount];
}
