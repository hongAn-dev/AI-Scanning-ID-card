import 'package:equatable/equatable.dart';

class OrderDetailEntity extends Equatable {
  final String id;
  final String orderCode;
  final String employeeId;
  final String customerId;
  final String? customerCode;
  final String employeeName;
  final String customerName;
  final String customerPhone;
  final String customerEmail;
  final String customerAddress;
  final String location;
  final String statusText;
  final DateTime orderDate;
  final int status;
  final String billingAddress;
  final String shippingAddress;
  final double orderTotal;
  final double fVat;
  final double mVat;
  final double orderTotalDiscount;
  final double fDiscount;
  final double mDiscount;
  final String description;
  final List<OrderProduct> orderProducts;
  final String createdBy;
  final String modifiedBy;
  final DateTime createdDate;
  final DateTime modifiedDate;

  const OrderDetailEntity({
    required this.id,
    required this.orderCode,
    required this.employeeId,
    required this.customerId,
    this.customerCode,
    required this.employeeName,
    required this.customerName,
    required this.customerPhone,
    required this.customerEmail,
    required this.customerAddress,
    required this.location,
    required this.statusText,
    required this.orderDate,
    required this.status,
    required this.billingAddress,
    required this.shippingAddress,
    required this.orderTotal,
    required this.fVat,
    required this.mVat,
    required this.orderTotalDiscount,
    required this.fDiscount,
    required this.mDiscount,
    required this.description,
    required this.orderProducts,
    required this.createdBy,
    required this.modifiedBy,
    required this.createdDate,
    required this.modifiedDate,
  });

  @override
  List<Object?> get props => [
        id,
        orderCode,
        employeeId,
        customerId,
        customerCode,
        employeeName,
        customerName,
        customerPhone,
        customerEmail,
        customerAddress,
        location,
        statusText,
        orderDate,
        status,
        billingAddress,
        shippingAddress,
        orderTotal,
        fVat,
        mVat,
        orderTotalDiscount,
        fDiscount,
        mDiscount,
        description,
        orderProducts,
        createdBy,
        modifiedBy,
        createdDate,
        modifiedDate,
      ];
}

class OrderProduct extends Equatable {
  final String id;
  final String? orderId;
  final String productId;
  final String productName;
  final String productCode;
  final String unit;
  final double price;
  final double qty;
  final double fDiscount;
  final double mDiscount;
  final String description;
  final double fConvert;
  final String? storeId;

  const OrderProduct({
    required this.id,
    this.orderId,
    required this.productId,
    required this.productName,
    required this.productCode,
    required this.unit,
    required this.price,
    required this.qty,
    required this.fDiscount,
    required this.mDiscount,
    required this.description,
    required this.fConvert,
    this.storeId,
  });

  double get totalPrice => price * qty;

  @override
  List<Object?> get props => [
        id,
        orderId,
        productId,
        productName,
        productCode,
        unit,
        price,
        qty,
        fDiscount,
        mDiscount,
        description,
        fConvert,
        storeId,
      ];
}
