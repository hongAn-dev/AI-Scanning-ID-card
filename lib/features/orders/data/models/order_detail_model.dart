import '../../domain/entities/order_detail.dart';

class OrderDetailModel extends OrderDetailEntity {
  const OrderDetailModel({
    required super.id,
    required super.orderCode,
    required super.employeeId,
    required super.customerId,
    super.customerCode,
    required super.employeeName,
    required super.customerName,
    required super.customerPhone,
    required super.customerEmail,
    required super.customerAddress,
    required super.location,
    required super.statusText,
    required super.orderDate,
    required super.status,
    required super.billingAddress,
    required super.shippingAddress,
    required super.orderTotal,
    required super.fVat,
    required super.mVat,
    required super.orderTotalDiscount,
    required super.fDiscount,
    required super.mDiscount,
    required super.description,
    required super.orderProducts,
    required super.createdBy,
    required super.modifiedBy,
    required super.createdDate,
    required super.modifiedDate,
  });

  factory OrderDetailModel.fromJson(Map<String, dynamic> json) {
    return OrderDetailModel(
      id: json['Id'] ?? '',
      orderCode: json['OrderCode'] ?? '',
      employeeId: json['EmployeeId'] ?? '',
      customerId: json['CustomerId'] ?? '',
      customerCode: json['CustomerCode'],
      employeeName: json['EmployeeName'] ?? '',
      customerName: json['CustomerName'] ?? '',
      customerPhone: json['CustomerPhone'] ?? '',
      customerEmail: json['CustomerEmail'] ?? '',
      customerAddress: json['CustomerAddress'] ?? '',
      location: json['Location'] ?? '',
      statusText: json['StatusText'] ?? '',
      orderDate: json['OrderDate'] != null ? DateTime.parse(json['OrderDate']) : DateTime.now(),
      status: json['Status'] ?? 0,
      billingAddress: json['BillingAddress'] ?? '',
      shippingAddress: json['ShippingAddress'] ?? '',
      orderTotal: (json['OrderTotal'] ?? 0).toDouble(),
      fVat: (json['f_Vat'] ?? 0).toDouble(),
      mVat: (json['m_Vat'] ?? 0).toDouble(),
      orderTotalDiscount: (json['OrderTotalDiscount'] ?? 0).toDouble(),
      fDiscount: (json['f_Discount'] ?? 0).toDouble(),
      mDiscount: (json['m_Discount'] ?? 0).toDouble(),
      description: json['Discription'] ?? '',
      orderProducts: (json['OrderDetail'] as List?)?.map((item) => OrderProductModel.fromJson(item)).toList() ?? [],
      createdBy: json['CreatedBy'] ?? '',
      modifiedBy: json['ModifiedBy'] ?? '',
      createdDate: json['CreatedDate'] != null ? DateTime.parse(json['CreatedDate']) : DateTime.now(),
      modifiedDate: json['ModifiedDate'] != null ? DateTime.parse(json['ModifiedDate']) : DateTime.now(),
    );
  }
}

class OrderProductModel extends OrderProduct {
  const OrderProductModel({
    required super.id,
    super.orderId,
    required super.productId,
    required super.productName,
    required super.productCode,
    required super.unit,
    required super.price,
    required super.qty,
    required super.fDiscount,
    required super.mDiscount,
    required super.description,
    required super.fConvert,
    super.storeId,
  });

  factory OrderProductModel.fromJson(Map<String, dynamic> json) {
    return OrderProductModel(
      id: json['Id'] ?? '',
      orderId: json['OrderId'],
      productId: json['ProductId'] ?? '',
      productName: json['ProductName'] ?? '',
      productCode: json['ProductCode'] ?? '',
      unit: json['Unit'] ?? '',
      price: (json['Price'] ?? 0).toDouble(),
      qty: (json['Qty'] ?? 0).toDouble(),
      fDiscount: (json['f_Discount'] ?? 0).toDouble(),
      mDiscount: (json['m_Discount'] ?? 0).toDouble(),
      description: json['Description'] ?? '',
      fConvert: (json['f_Convert'] ?? 1).toDouble(),
      storeId: json['StoreId'],
    );
  }
}

class OrderDetailResponseModel {
  final OrderDetailModel data;
  final MetaModel meta;

  OrderDetailResponseModel({
    required this.data,
    required this.meta,
  });

  factory OrderDetailResponseModel.fromJson(Map<String, dynamic> json) {
    return OrderDetailResponseModel(
      data: OrderDetailModel.fromJson(json['data']),
      meta: MetaModel.fromJson(json['meta']),
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
