import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../products/domain/entities/product.dart';
import '../../data/datasources/cart_local_data_source.dart';
import '../../data/models/cart_item_model.dart';
import '../../domain/entities/cart_item.dart';
import '../../domain/entities/discount_type.dart';

part 'cart_event.dart';
part 'cart_state.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  final CartLocalDataSource localDataSource;

  CartBloc({required this.localDataSource}) : super(const CartState(items: [], totalAmount: 0)) {
    on<LoadCartEvent>(_onLoadCart);
    on<AddToCartEvent>(_onAddToCart);
    on<RemoveFromCartEvent>(_onRemoveFromCart);
    on<IncreaseQuantityEvent>(_onIncreaseQuantity);
    on<DecreaseQuantityEvent>(_onDecreaseQuantity);
    on<UpdateDiscountEvent>(_onUpdateDiscount);
    on<UpdateCartItemQuantityEvent>(_onUpdateCartItemQuantity);
    on<ClearCartEvent>(_onClearCart);

    // Load cart on initialization
    add(LoadCartEvent());
  }

  Future<void> _onLoadCart(
    LoadCartEvent event,
    Emitter<CartState> emit,
  ) async {
    try {
      final items = await localDataSource.getCartItems();
      final totalAmount = _calculateTotal(items);
      emit(CartState(items: items, totalAmount: totalAmount));
    } catch (e) {
      // If error, start with empty cart
      emit(const CartState(items: [], totalAmount: 0));
    }
  }

  Future<void> _onAddToCart(
    AddToCartEvent event,
    Emitter<CartState> emit,
  ) async {
    try {
      final items = List<CartItem>.from(state.items);
      final existingIndex = items.indexWhere((item) => item.product.id == event.product.id);

      final cartItemModel = CartItemModel(product: event.product, quantity: 1);

      if (existingIndex >= 0) {
        // Product already in cart, increase quantity
        final updatedItem = CartItemModel(
          product: event.product,
          quantity: items[existingIndex].quantity + 1,
        );
        items[existingIndex] = updatedItem;
        await localDataSource.updateCartItem(updatedItem);
      } else {
        // Add new product to cart
        items.add(cartItemModel);
        await localDataSource.addCartItem(cartItemModel);
      }

      final totalAmount = _calculateTotal(items);
      emit(CartState(items: items, totalAmount: totalAmount));
    } catch (e) {
      // Keep current state if error
      emit(state);
    }
  }

  Future<void> _onRemoveFromCart(
    RemoveFromCartEvent event,
    Emitter<CartState> emit,
  ) async {
    try {
      final items = List<CartItem>.from(state.items);
      items.removeWhere((item) => item.product.id == event.productId);

      await localDataSource.removeCartItem(event.productId);

      final totalAmount = _calculateTotal(items);
      emit(CartState(items: items, totalAmount: totalAmount));
    } catch (e) {
      emit(state);
    }
  }

  Future<void> _onIncreaseQuantity(
    IncreaseQuantityEvent event,
    Emitter<CartState> emit,
  ) async {
    try {
      final items = List<CartItem>.from(state.items);
      final index = items.indexWhere((item) => item.product.id == event.productId);

      if (index >= 0) {
        final updatedItem = CartItemModel(
          product: items[index].product,
          quantity: items[index].quantity + 1,
        );
        items[index] = updatedItem;
        await localDataSource.updateCartItem(updatedItem);
      }

      final totalAmount = _calculateTotal(items);
      emit(CartState(items: items, totalAmount: totalAmount));
    } catch (e) {
      emit(state);
    }
  }

  Future<void> _onDecreaseQuantity(
    DecreaseQuantityEvent event,
    Emitter<CartState> emit,
  ) async {
    try {
      final items = List<CartItem>.from(state.items);
      final index = items.indexWhere((item) => item.product.id == event.productId);

      if (index >= 0) {
        if (items[index].quantity > 1) {
          final updatedItem = CartItemModel(
            product: items[index].product,
            quantity: items[index].quantity - 1,
            discountValue: items[index].discountValue,
            discountType: items[index].discountType,
          );
          items[index] = updatedItem;
          await localDataSource.updateCartItem(updatedItem);
        } else {
          items.removeAt(index);
          await localDataSource.removeCartItem(event.productId);
        }
      }

      final totalAmount = _calculateTotal(items);
      emit(CartState(items: items, totalAmount: totalAmount));
    } catch (e) {
      emit(state);
    }
  }

  Future<void> _onUpdateDiscount(
    UpdateDiscountEvent event,
    Emitter<CartState> emit,
  ) async {
    try {
      final items = List<CartItem>.from(state.items);
      final index = items.indexWhere((item) => item.product.id == event.productId);

      if (index >= 0) {
        final updatedItem = CartItemModel(
          product: items[index].product,
          quantity: items[index].quantity,
          discountValue: event.discountValue,
          discountType: event.discountType,
        );
        items[index] = updatedItem;
        await localDataSource.updateCartItem(updatedItem);

        final totalAmount = _calculateTotal(items);
        emit(CartState(items: items, totalAmount: totalAmount));
      }
    } catch (e) {
      emit(state);
    }
  }

  Future<void> _onUpdateCartItemQuantity(
    UpdateCartItemQuantityEvent event,
    Emitter<CartState> emit,
  ) async {
    try {
      final items = List<CartItem>.from(state.items);
      final index = items.indexWhere((item) => item.product.id == event.productId);

      if (index >= 0) {
        if (event.quantity <= 0) {
          // If quantity is 0 or less, remove the item
          items.removeAt(index);
          await localDataSource.removeCartItem(event.productId);
        } else {
          // Update the quantity
          final updatedItem = CartItemModel(
            product: items[index].product,
            quantity: event.quantity,
            discountValue: items[index].discountValue,
            discountType: items[index].discountType,
          );
          items[index] = updatedItem;
          await localDataSource.updateCartItem(updatedItem);
        }

        final totalAmount = _calculateTotal(items);
        emit(CartState(items: items, totalAmount: totalAmount));
      }
    } catch (e) {
      emit(state);
    }
  }

  Future<void> _onClearCart(
    ClearCartEvent event,
    Emitter<CartState> emit,
  ) async {
    try {
      await localDataSource.clearCart();
      emit(const CartState(items: [], totalAmount: 0));
    } catch (e) {
      emit(state);
    }
  }

  double _calculateTotal(List<CartItem> items) {
    return items.fold(0, (sum, item) => sum + item.totalPrice);
  }
}
