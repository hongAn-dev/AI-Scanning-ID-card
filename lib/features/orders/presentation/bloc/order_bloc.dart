import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/order.dart';
import '../../domain/entities/order_detail.dart';
import '../../domain/usecases/get_order_detail.dart';
import '../../domain/usecases/get_orders.dart';

part 'order_event.dart';
part 'order_state.dart';

class OrderBloc extends Bloc<OrderEvent, OrderState> {
  final GetOrders getOrders;
  final GetOrderDetail getOrderDetail;
  bool _isLoadingMore = false;

  OrderBloc({
    required this.getOrders,
    required this.getOrderDetail,
  }) : super(const OrderInitial()) {
    on<FetchOrdersEvent>(_onFetchOrders);
    on<RefreshOrdersEvent>(_onRefreshOrders);
    on<FetchOrderDetailEvent>(_onFetchOrderDetail);
  }

  Future<void> _onFetchOrders(
    FetchOrdersEvent event,
    Emitter<OrderState> emit,
  ) async {
     if (_isLoadingMore && event.pageIndex > 0) return;

     if (event.pageIndex > 0) {
      _isLoadingMore = true;
    }
    if (event.pageIndex == 0) {
      emit(OrderLoading(
        orders: state.orders,
        paging: state.paging,
        extra: state.extra,
      ));
    }

    final result = await getOrders(
      GetOrdersParams(
        filterType: event.filterType,
        fromDate: event.fromDate,
        toDate: event.toDate,
        locationId: event.locationId,
        orderStatus: event.orderStatus,
        searchByOrderInfo: event.searchByOrderInfo,
        pageSize: event.pageSize,
        pageIndex: event.pageIndex,
      ),
    );

    _isLoadingMore = false;

    result.fold(
      (failure) => emit(OrderError(
        message: failure.message,
        orders: state.orders,
        paging: state.paging,
        extra: state.extra,
      )),
      (data) {
        final newOrders = data['orders'] as List<Order>;
        final paging = data['paging'] as OrderPaging;
        // Với các trang > 0, giữ nguyên extra hiện tại (tổng doanh thu)
        // để tránh bị reset về 0 nếu API không trả tổng cho các trang sau.
        final OrderExtra? extra =
            event.pageIndex > 0 ? state.extra : data['extra'] as OrderExtra?;

        final List<Order> orders;
        if (event.pageIndex > 0) {
          orders = [...state.orders, ...newOrders];
        } else {
          orders = newOrders;
        }

        emit(OrderLoaded(
          orders: orders,
          paging: paging,
          extra: extra,
        ));
      },
    );
  }

  Future<void> _onRefreshOrders(
    RefreshOrdersEvent event,
    Emitter<OrderState> emit,
  ) async {
    // Refresh with default parameters
     _isLoadingMore = false;
    add(const FetchOrdersEvent(pageIndex: 0, pageSize: 20));
  }

  Future<void> _onFetchOrderDetail(
    FetchOrderDetailEvent event,
    Emitter<OrderState> emit,
  ) async {
    emit(const OrderDetailLoading());

    final result = await getOrderDetail(event.orderId);

    result.fold(
      (failure) => emit(OrderDetailError(message: failure.message)),
      (orderDetail) => emit(OrderDetailLoaded(orderDetail: orderDetail)),
    );
  }
}
