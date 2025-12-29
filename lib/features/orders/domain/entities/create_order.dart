import 'package:equatable/equatable.dart';

class CreateOrderRequest extends Equatable {
  final String employeeId;
  final String customerId;
  final double fDiscount;
  final double mDiscount;
  final double orderTotalDiscount;
  final double orderTotal;
  final double mTotalMoney;
  final String shippingAddress;
  final String billingAddress;
  final String description;
  final int status;
  final double fVat;
  final double mVat;
  final DateTime orderDate;
  final String createdBy;
  final String modifiedBy;
  final DateTime createdDate;
  final DateTime modifiedDate;
  final String locationId;
  final List<CreateOrderProduct> products;

  const CreateOrderRequest({
    required this.employeeId,
    required this.customerId,
    this.fDiscount = 0,
    required this.mDiscount,
    required this.orderTotalDiscount,
    required this.orderTotal,
    required this.mTotalMoney,
    required this.shippingAddress,
    required this.billingAddress,
    required this.description,
    this.status = 0,
    this.fVat = 0,
    this.mVat = 0,
    required this.orderDate,
    required this.createdBy,
    required this.modifiedBy,
    required this.createdDate,
    required this.modifiedDate,
    this.locationId = '',
    required this.products,
  });

  @override
  List<Object?> get props => [
        employeeId,
        customerId,
        fDiscount,
        mDiscount,
        orderTotalDiscount,
        orderTotal,
        mTotalMoney,
        shippingAddress,
        billingAddress,
        description,
        status,
        fVat,
        mVat,
        orderDate,
        createdBy,
        modifiedBy,
        createdDate,
        modifiedDate,
        locationId,
        products,
      ];
}

class CreateOrderProduct extends Equatable {
  final String productId;
  final String productName;
  final double price;
  final double qty;
  final String unit;
  final double fConvert;
  final double fDiscount;
  final double mDiscount;
  final String description;
  final String storeId;

  const CreateOrderProduct({
    required this.productId,
    required this.productName,
    required this.price,
    required this.qty,
    required this.unit,
    required this.fConvert,
    this.fDiscount = 0,
    required this.mDiscount,
    this.description = '',
    this.storeId = '',
  });

  @override
  List<Object?> get props => [
        productId,
        productName,
        price,
        qty,
        unit,
        fConvert,
        fDiscount,
        mDiscount,
        description,
        storeId,
      ];
}
