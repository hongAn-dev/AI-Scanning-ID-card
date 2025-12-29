import 'package:equatable/equatable.dart';

enum OrderStatus {
  ordering('Đang đặt hàng'),
  completed('Hoàn thành'),
  cancelled('Đã Huỷ');

  final String displayName;
  const OrderStatus(this.displayName);

  static OrderStatus fromString(String status) {
    switch (status) {
      case 'Đang đặt hàng':
        return OrderStatus.ordering;
      case 'Hoàn thành':
        return OrderStatus.completed;
      case 'Đã Huỷ':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.ordering;
    }
  }
}

class Order extends Equatable {
  final String id;
  final String orderCode;
  final DateTime orderDate;
  final String customerName;
  final String employeeName;
  final OrderStatus orderStatus;
  final double discount;
  final double totalMoney;

  const Order({
    required this.id,
    required this.orderCode,
    required this.orderDate,
    required this.customerName,
    required this.employeeName,
    required this.orderStatus,
    required this.discount,
    required this.totalMoney,
  });

  @override
  List<Object?> get props => [
        id,
        orderCode,
        orderDate,
        customerName,
        employeeName,
        orderStatus,
        discount,
        totalMoney,
      ];
}

class OrderPaging extends Equatable {
  final int totalPage;
  final int pageIndex;
  final int pageSize;
  final int totalCount;

  const OrderPaging({
    required this.totalPage,
    required this.pageIndex,
    required this.pageSize,
    required this.totalCount,
  });

  @override
  List<Object?> get props => [totalPage, pageIndex, pageSize, totalCount];
}

class OrderExtra extends Equatable {
  final double totalMoney;

  const OrderExtra({
    required this.totalMoney,
  });

  @override
  List<Object?> get props => [totalMoney];
}
