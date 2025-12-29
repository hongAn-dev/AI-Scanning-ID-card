part of 'order_bloc.dart';

abstract class OrderState extends Equatable {
  final List<Order> orders;
  final OrderPaging? paging;
  final OrderExtra? extra;
  final OrderDetailEntity? orderDetail;

  const OrderState({
    this.orders = const [],
    this.paging,
    this.extra,
    this.orderDetail,
  });

  @override
  List<Object?> get props => [orders, paging, extra, orderDetail];
}

class OrderInitial extends OrderState {
  const OrderInitial() : super();
}

class OrderLoading extends OrderState {
  const OrderLoading({
    super.orders,
    super.paging,
    super.extra,
  });
}

class OrderLoaded extends OrderState {
  const OrderLoaded({
    required super.orders,
    required super.paging,
    required super.extra,
  });
}

class OrderError extends OrderState {
  final String message;

  const OrderError({
    required this.message,
    super.orders,
    super.paging,
    super.extra,
  });

  @override
  List<Object?> get props => [message, orders, paging, extra];
}

// Order Detail States
class OrderDetailLoading extends OrderState {
  const OrderDetailLoading();
}

class OrderDetailLoaded extends OrderState {
  const OrderDetailLoaded({
    required OrderDetailEntity orderDetail,
  }) : super(orderDetail: orderDetail);
}

class OrderDetailError extends OrderState {
  final String message;

  const OrderDetailError({
    required this.message,
  });

  @override
  List<Object?> get props => [message];
}
