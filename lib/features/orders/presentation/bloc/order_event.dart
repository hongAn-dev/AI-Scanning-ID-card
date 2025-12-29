part of 'order_bloc.dart';

abstract class OrderEvent extends Equatable {
  const OrderEvent();

  @override
  List<Object?> get props => [];
}

class FetchOrdersEvent extends OrderEvent {
  final int filterType;
  final DateTime? fromDate;
  final DateTime? toDate;
  final String locationId;
  final int orderStatus;
  final String searchByOrderInfo;
  final int pageSize;
  final int pageIndex;

  const FetchOrdersEvent({
    this.filterType = -1,
    this.fromDate,
    this.toDate,
    this.locationId = '',
    this.orderStatus = 2,
    this.searchByOrderInfo = '',
    this.pageSize = 20,
    this.pageIndex = 0,
  });

  @override
  List<Object?> get props => [
        filterType,
        fromDate,
        toDate,
        locationId,
        orderStatus,
        searchByOrderInfo,
        pageSize,
        pageIndex,
      ];
}

class RefreshOrdersEvent extends OrderEvent {
  const RefreshOrdersEvent();
}

class FetchOrderDetailEvent extends OrderEvent {
  final String orderId;

  const FetchOrderDetailEvent(this.orderId);

  @override
  List<Object?> get props => [orderId];
}
