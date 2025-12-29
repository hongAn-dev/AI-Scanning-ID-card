import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:masterpro_ghidon/features/customers/presentation/bloc/customer_bloc.dart';
import 'package:masterpro_ghidon/utils/screen_utils.dart';

import '../../../../injection_container.dart' as di;
import '../../../auth/data/auth_service.dart';
import '../../../customers/data/datasources/customer_local_data_source.dart';
import '../../../customers/domain/entities/customer.dart';
import '../../../customers/presentation/pages/customer_list_page.dart';
import '../../../orders/domain/entities/create_order.dart';
import '../../../orders/domain/usecases/create_order.dart';
import '../../domain/entities/discount_type.dart';
import '../bloc/cart_bloc.dart';
import 'order_result_page.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _noteController = TextEditingController();
  final _discountController = TextEditingController();

  DiscountType _orderDiscountType = DiscountType.vnd;
  final double _shippingFee = 0; // Default shipping fee
  double _orderDiscountValue = 0;
  String? _customerId;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _noteController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  void _updateOrderDiscount() {
    setState(() {
      _orderDiscountValue = double.tryParse(_discountController.text) ?? 0;
    });
  }

  double _calculateOrderDiscount(double subtotal) {
    if (_orderDiscountType == DiscountType.percent) {
      final percentage = _orderDiscountValue.clamp(0, 100);
      return subtotal * (percentage / 100);
    } else {
      return _orderDiscountValue.clamp(0, subtotal);
    }
  }

  void _selectCustomer() async {
    _formKey.currentState?.reset();
    final customerDataSource = di.sl<CustomerLocalDataSource>();
    final customer = await Navigator.push<Customer>(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => di.sl<CustomerBloc>(),
          child: CustomerListPage(
            dataSource: customerDataSource,
            onCustomerSelected: (customer) {},
          ),
        ),
      ),
    );

    if (customer != null) {
      setState(() {
        // Use UUID from API (Id field) - e.g., "7c8880ec-900b-424e-851a-4a995402b1f2"
        _customerId = customer.uuid ?? customer.id.toString();
        _nameController.text = customer.name;
        _phoneController.text = customer.phone;
        _addressController.text = customer.address;
        _noteController.text = '';
      });
    }
  }

  void _processOrder(BuildContext context, double finalTotal) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  color: Colors.blueAccent,
                ),
                SizedBox(height: 16),
                Text(
                  'Đang xử lý đơn hàng...',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // Get auth service to get employee ID
      final authService = di.sl<AuthService>();
      final userAccount = authService.getUserAccount();

      if (userAccount == null || userAccount.employeeId.isEmpty) {
        // Close loading dialog
        if (context.mounted) {
          Navigator.pop(context);
        }
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không tìm thấy thông tin nhân viên'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      if (_customerId == null || _customerId!.isEmpty) {
        // Close loading dialog
        if (context.mounted) {
          Navigator.pop(context);
        }
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vui lòng chọn khách hàng'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final cartState = context.read<CartBloc>().state;
      final cartItems = cartState.items;
      final now = DateTime.now();

      // Calculate total discount from order level
      final orderDiscount = _calculateOrderDiscount(cartState.totalAmount);

      // Build products list
      final products = cartItems.map((item) {
        return CreateOrderProduct(
          productId: item.product.id,
          productName: item.product.name,
          price: item.product.price,
          qty: item.quantity.toDouble(),
          unit: item.product.unit,
          fConvert: 1, // Default convert factor
          fDiscount: 0,
          mDiscount: item.totalDiscount,
        );
      }).toList();

      // Create order request
      final orderRequest = CreateOrderRequest(
        employeeId: userAccount.employeeId,
        customerId: _customerId!,
        fDiscount: 0,
        mDiscount: orderDiscount,
        orderTotalDiscount: finalTotal,
        orderTotal: finalTotal,
        mTotalMoney: finalTotal,
        shippingAddress: _addressController.text,
        billingAddress: _addressController.text,
        description: _noteController.text,
        orderDate: now,
        createdBy: userAccount.employeeId,
        modifiedBy: userAccount.employeeId,
        createdDate: now,
        modifiedDate: now,
        products: products,
      );

      // Call create order API
      final createOrder = di.sl<CreateOrder>();
      final result = await createOrder(orderRequest);

      // Close loading dialog
      if (context.mounted) {
        Navigator.pop(context);
      }

      result.fold(
        (failure) {
          if (context.mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => OrderResultPage(
                  isSuccess: false,
                  errorMessage: failure.message,
                ),
              ),
            );
          }
        },
        (data) {
          final isSuccess = data['success'] == true;
          final orderCode = data['orderCode'] ?? '';
          final message = data['message'] ?? '';

          if (isSuccess) {
            if (context.mounted) {
              context.read<CartBloc>().add(ClearCartEvent());
            }

            if (context.mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => OrderResultPage(
                    isSuccess: true,
                    orderDetails: {
                      'customerName': _nameController.text,
                      'phone': _phoneController.text,
                      'address': _addressController.text,
                      'totalAmount': finalTotal,
                      'orderCode': orderCode,
                      'message': message,
                    },
                  ),
                ),
              );
            }
          } else {
            if (context.mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => OrderResultPage(
                    isSuccess: false,
                    errorMessage: message.isNotEmpty
                        ? message
                        : 'Không thể tạo đơn hàng. Vui lòng thử lại.',
                  ),
                ),
              );
            }
          }
        },
      );
    } catch (e) {
      // Close loading dialog
      if (context.mounted) {
        Navigator.pop(context);
      }

      // Navigate to failure page on error
      if (context.mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => OrderResultPage(
              isSuccess: false,
              errorMessage: 'Lỗi: ${e.toString()}',
            ),
          ),
        );
      }
    }
  }

  void _placeOrder(BuildContext context, double finalTotal) {
    if (_formKey.currentState!.validate()) {
      // Show confirmation dialog
      showDialog(
        context: context,
        builder: (ctx) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width:
                ScreenUtils.isTablet(context) || ScreenUtils.isDesktop(context)
                    ? 600
                    : double.infinity,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon and title
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.shopping_cart_checkout,
                    color: Colors.red,
                    size: ScreenUtils.isTablet(context) ||
                            ScreenUtils.isDesktop(context)
                        ? 48
                        : 23,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Xác nhận đặt hàng',
                  style: TextStyle(
                    fontSize: ScreenUtils.isTablet(context) ||
                            ScreenUtils.isDesktop(context)
                        ? 22
                        : 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Vui lòng kiểm tra thông tin trước khi đặt hàng',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Customer information card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow(
                          Icons.person, 'Họ tên', _nameController.text),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                          Icons.phone, 'Điện thoại', _phoneController.text),
                      const SizedBox(height: 12),
                      _buildInfoRow(Icons.location_on, 'Địa chỉ',
                          _addressController.text),
                      if (_noteController.text.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _buildInfoRow(
                            Icons.note, 'Ghi chú', _noteController.text),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Total amount
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.red[50]!, Colors.red[100]!],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Tổng thanh toán',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${NumberFormat('#,###', 'vi_VN').format(finalTotal).replaceAll(',', '.')} đ',
                        style: TextStyle(
                          fontSize: ScreenUtils.isTablet(context) ||
                                  ScreenUtils.isDesktop(context)
                              ? 20
                              : 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: const BorderSide(color: Colors.grey),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Hủy',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx); // Close dialog
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: const Text(
                          'Xác nhận',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thanh toán'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        actions: [
          TextButton.icon(
            onPressed: _selectCustomer,
            icon: const Icon(
              Icons.person_search,
              size: 28,
              color: Colors.black,
            ),
            label: const Text(''),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),
          ),
        ],
      ),
      body: BlocBuilder<CartBloc, CartState>(
        builder: (context, state) {
          final subtotal = state.totalAmount;
          final orderDiscount = _calculateOrderDiscount(subtotal);
          final total = subtotal + _shippingFee - orderDiscount;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Customer Information Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSectionTitle('Thông tin khách hàng'),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Full Name
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Họ và tên',
                        hintText: 'Nhập họ và tên',
                        labelStyle: const TextStyle(color: Colors.black),
                        prefixIcon: const Icon(Icons.person),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.black),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập họ và tên';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Address
                    TextFormField(
                      controller: _addressController,
                      decoration: InputDecoration(
                        labelText: 'Địa chỉ',
                        hintText: 'Nhập địa chỉ giao hàng',
                        labelStyle: const TextStyle(color: Colors.black),
                        prefixIcon: const Icon(Icons.location_on),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.black),
                        ),
                      ),
                      // maxLines: 2,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập địa chỉ';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Phone
                    TextFormField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        labelText: 'Điện thoại',
                        hintText: 'Nhập số điện thoại',
                        labelStyle: const TextStyle(color: Colors.black),
                        prefixIcon: const Icon(Icons.phone),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.black),
                        ),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập số điện thoại';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Note
                    TextFormField(
                      controller: _noteController,
                      decoration: InputDecoration(
                        labelText: 'Ghi chú đặt hàng',
                        hintText: 'Nhập ghi chú (không bắt buộc)',
                        labelStyle: const TextStyle(color: Colors.black),
                        prefixIcon: const Icon(Icons.note),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.black),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Order Summary Section
                    _buildSectionTitle('Chi tiết đơn hàng'),
                    const SizedBox(height: 8),

                    // Summary Card
                    Card(
                      color: Colors.white,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            // Subtotal
                            _buildSummaryRow(
                              'Tổng tiền hàng',
                              '${NumberFormat('#,###', 'vi_VN').format(subtotal).replaceAll(',', '.')} đ',
                            ),
                            // const SizedBox(height: 12),

                            // Shipping Fee
                            // _buildSummaryRow(
                            //   'Phí vận chuyển',
                            //   '${NumberFormat('#,###', 'vi_VN').format(_shippingFee).replaceAll(',', '.')} đ',
                            //   valueColor: Colors.orange,
                            // ),
                            // const SizedBox(height: 16),

                            // Order Discount Section
                            const Divider(),
                            // const SizedBox(height: 12),
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Giảm giá đơn hàng',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Discount Input Row
                            Row(
                              children: [
                                // VND Box
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _orderDiscountType = DiscountType.vnd;
                                      _updateOrderDiscount();
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          _orderDiscountType == DiscountType.vnd
                                              ? Colors.red
                                              : Colors.grey[200],
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: _orderDiscountType ==
                                                DiscountType.vnd
                                            ? Colors.red
                                            : Colors.grey[400]!,
                                      ),
                                    ),
                                    child: Text(
                                      'VND',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: _orderDiscountType ==
                                                DiscountType.vnd
                                            ? Colors.white
                                            : Colors.grey[700],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // % Box
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _orderDiscountType = DiscountType.percent;
                                      // Cap value at 100 when switching to percentage
                                      final currentValue = double.tryParse(
                                              _discountController.text) ??
                                          0;
                                      if (currentValue > 100) {
                                        _discountController.text = '100';
                                      }
                                      _updateOrderDiscount();
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _orderDiscountType ==
                                              DiscountType.percent
                                          ? Colors.red
                                          : Colors.grey[200],
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: _orderDiscountType ==
                                                DiscountType.percent
                                            ? Colors.red
                                            : Colors.grey[400]!,
                                      ),
                                    ),
                                    child: Text(
                                      '%',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: _orderDiscountType ==
                                                DiscountType.percent
                                            ? Colors.white
                                            : Colors.grey[700],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Discount Input
                                Expanded(
                                  child: TextField(
                                    controller: _discountController,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                        RegExp(r'^\d+\.?\d{0,2}'),
                                      ),
                                      _PercentageRangeFormatter(
                                        isPercentage: _orderDiscountType ==
                                            DiscountType.percent,
                                      ),
                                    ],
                                    decoration: InputDecoration(
                                      hintText: _orderDiscountType ==
                                              DiscountType.percent
                                          ? '0-100'
                                          : '0',
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 8,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                            color: Colors.black.withOpacity(.5),
                                            width: 1),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                            color: Colors.black.withOpacity(.5),
                                            width: 1),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                            color: Colors.black.withOpacity(.5),
                                            width: 1),
                                      ),
                                      isDense: true,
                                    ),
                                    onChanged: (value) {
                                      _updateOrderDiscount();
                                    },
                                  ),
                                ),
                              ],
                            ),

                            // Discount amount display
                            if (orderDiscount > 0)
                              Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    '-${NumberFormat('#,###', 'vi_VN').format(orderDiscount).replaceAll(',', '.')} đ',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.red[600],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),

                            const SizedBox(height: 16),
                            const Divider(),
                            const SizedBox(height: 12),

                            // Total
                            _buildSummaryRow(
                              'Thành tiền',
                              '${NumberFormat('#,###', 'vi_VN').format(total).replaceAll(',', '.')} đ',
                              isTotal: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Place Order Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _processOrder(context, total),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Đặt hàng',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isTotal = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: Colors.black,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 20 : 16,
            fontWeight: FontWeight.bold,
            color: valueColor ?? (isTotal ? Colors.red : Colors.black),
          ),
        ),
      ],
    );
  }
}

// Custom formatter to restrict percentage input to 0-100
class _PercentageRangeFormatter extends TextInputFormatter {
  final bool isPercentage;

  _PercentageRangeFormatter({required this.isPercentage});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (!isPercentage) {
      return newValue;
    }

    if (newValue.text.isEmpty) {
      return newValue;
    }

    final value = double.tryParse(newValue.text);
    if (value == null) {
      return oldValue;
    }

    if (value > 100) {
      return oldValue;
    }

    return newValue;
  }
}
