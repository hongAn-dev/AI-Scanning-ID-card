import '../../domain/entities/order.dart';

class OrderModel extends Order {
  const OrderModel({
    required super.id,
    required super.orderCode,
    required super.orderDate,
    required super.customerName,
    required super.employeeName,
    required super.orderStatus,
    required super.discount,
    required super.totalMoney,
  });
}

class OrderPagingModel extends OrderPaging {
  const OrderPagingModel({
    required super.totalPage,
    required super.pageIndex,
    required super.pageSize,
    required super.totalCount,
  });

  factory OrderPagingModel.fromJson(Map<String, dynamic> json) {
    return OrderPagingModel(
      totalPage: json['TotalPage'] ?? 0,
      pageIndex: json['PageIndex'] ?? 0,
      pageSize: json['PageSize'] ?? 0,
      totalCount: json['TotalCount'] ?? 0,
    );
  }
}

class OrderExtraModel extends OrderExtra {
  const OrderExtraModel({
    required super.totalMoney,
  });

  factory OrderExtraModel.fromJson(Map<String, dynamic> json) {
    return OrderExtraModel(
      totalMoney: (json['TotalMoney'] ?? 0).toDouble(),
    );
  }
}
