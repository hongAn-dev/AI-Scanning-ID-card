import 'order_model.dart';
import '../../domain/entities/order.dart';

class OrderRemoteModel {
  final String id;
  final String orderCode;
  final String orderDate;
  final String customerName;
  final String employeeName;
  final String orderStatus;
  final double discount;
  final double totalMoney;

  OrderRemoteModel({
    required this.id,
    required this.orderCode,
    required this.orderDate,
    required this.customerName,
    required this.employeeName,
    required this.orderStatus,
    required this.discount,
    required this.totalMoney,
  });

  factory OrderRemoteModel.fromJson(Map<String, dynamic> json) {
    return OrderRemoteModel(
      id: json['Id'] ?? '',
      orderCode: json['OrderCode'] ?? '',
      orderDate: json['OrderDate'] ?? '',
      customerName: json['CustomerName'] ?? '',
      employeeName: json['EmployeeName'] ?? '',
      orderStatus: json['OrderStatus'] ?? '',
      discount: (json['Discount'] ?? 0).toDouble(),
      totalMoney: (json['TotalMoney'] ?? 0).toDouble(),
    );
  }

  OrderModel toOrderModel() {
    return OrderModel(
      id: id,
      orderCode: orderCode,
      orderDate: DateTime.tryParse(orderDate) ?? DateTime.now(),
      customerName: customerName,
      employeeName: employeeName,
      orderStatus: OrderStatus.fromString(orderStatus),
      discount: discount,
      totalMoney: totalMoney,
    );
  }
}

class OrderResponseModel {
  final List<OrderRemoteModel> data;
  final OrderPagingModel paging;
  final MetaModel meta;
  final OrderExtraModel? extra;

  OrderResponseModel({
    required this.data,
    required this.paging,
    required this.meta,
    this.extra,
  });

  factory OrderResponseModel.fromJson(Map<String, dynamic> json) {
    return OrderResponseModel(
      data: (json['data'] as List?)?.map((item) => OrderRemoteModel.fromJson(item)).toList() ?? [],
      paging: OrderPagingModel.fromJson(json['paging'] ?? {}),
      meta: MetaModel.fromJson(json['meta'] ?? {}),
      extra: json['Extra'] != null ? OrderExtraModel.fromJson(json['Extra']) : null,
    );
  }
}

class MetaModel {
  final int statusCode;
  final String message;

  MetaModel({
    required this.statusCode,
    required this.message,
  });

  factory MetaModel.fromJson(Map<String, dynamic> json) {
    return MetaModel(
      statusCode: json['status_code'] ?? 0,
      message: json['message'] ?? '',
    );
  }
}
