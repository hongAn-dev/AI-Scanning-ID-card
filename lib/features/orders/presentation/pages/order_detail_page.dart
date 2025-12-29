import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:masterpro_ghidon/utils/screen_utils.dart';

import '../../../../injection_container.dart' as di;
import '../../domain/entities/order_detail.dart';
import '../bloc/order_bloc.dart';

class OrderDetailPage extends StatelessWidget {
  final String orderId;
  final String orderCode;

  const OrderDetailPage({
    super.key,
    required this.orderId,
    required this.orderCode,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          di.sl<OrderBloc>()..add(FetchOrderDetailEvent(orderId)),
      child: OrderDetailView(orderCode: orderCode),
    );
  }
}

class OrderDetailView extends StatelessWidget {
  final String orderCode;

  const OrderDetailView({
    super.key,
    required this.orderCode,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chi tiết: $orderCode'),
        centerTitle: true,
        elevation: 0,
      ),
      body: BlocBuilder<OrderBloc, OrderState>(
        builder: (context, state) {
          if (state is OrderDetailLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state is OrderDetailError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Quay lại'),
                  ),
                ],
              ),
            );
          }

          if (state is OrderDetailLoaded) {
            final order = state.orderDetail!;
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order Status Card
                  _buildStatusCard(context, order),

                  const SizedBox(height: 8),

                  // Customer Info
                  _buildCustomerInfo(context, order),

                  const SizedBox(height: 8),

                  // Order Info
                  _buildOrderInfo(context, order),

                  const SizedBox(height: 8),

                  // Products List
                  _buildProductsList(context, order),

                  const SizedBox(height: 8),

                  // Summary
                  _buildSummary(context, order),

                  const SizedBox(height: 16),
                ],
              ),
            );
          }

          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context, OrderDetailEntity order) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.red,
            Colors.red.withOpacity(0.7),
          ],
        ),
      ),
      child: Column(
        children: [
          Icon(
            _getStatusIcon(order.status),
            size: 48,
            color: Colors.white,
          ),
          const SizedBox(height: 8),
          Text(
            order.statusText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat('dd/MM/yyyy HH:mm').format(order.orderDate),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(int status) {
    switch (status) {
      case 0:
        return Icons.pending_actions;
      case 1:
        return Icons.check_circle;
      case 2:
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  Widget _buildCustomerInfo(BuildContext context, OrderDetailEntity order) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Thông tin khách hàng',
                  style: TextStyle(
                    fontSize: ScreenUtils.isTablet(context) ||
                            ScreenUtils.isDesktop(context)
                        ? 20
                        : 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            _buildInfoRow(context, 'Tên khách hàng', order.customerName),
            if (order.customerPhone.isNotEmpty)
              _buildInfoRow(context, 'Số điện thoại', order.customerPhone),
            if (order.customerEmail.isNotEmpty)
              _buildInfoRow(context, 'Email', order.customerEmail),
            if (order.customerAddress.isNotEmpty)
              _buildInfoRow(context, 'Địa chỉ', order.customerAddress),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderInfo(BuildContext context, OrderDetailEntity order) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.receipt_long, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Thông tin đơn hàng',
                  style: TextStyle(
                    fontSize: ScreenUtils.isTablet(context) ||
                            ScreenUtils.isDesktop(context)
                        ? 20
                        : 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            _buildInfoRow(context, 'Mã đơn hàng', order.orderCode),
            _buildInfoRow(context, 'Nhân viên', order.employeeName),
            _buildInfoRow(context, 'Địa điểm', order.location),
            if (order.billingAddress.isNotEmpty)
              _buildInfoRow(
                  context, 'Địa chỉ thanh toán', order.billingAddress),
            if (order.shippingAddress.isNotEmpty)
              _buildInfoRow(
                  context, 'Địa chỉ giao hàng', order.shippingAddress),
            if (order.description.isNotEmpty)
              _buildInfoRow(context, 'Ghi chú', order.description),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsList(BuildContext context, OrderDetailEntity order) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.shopping_cart, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Sản phẩm',
                  style: TextStyle(
                    fontSize: ScreenUtils.isTablet(context) ||
                            ScreenUtils.isDesktop(context)
                        ? 20
                        : 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: order.orderProducts.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final product = order.orderProducts[index];
                return _buildProductItem(context, product);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductItem(BuildContext context, OrderProduct product) {
    final currencyFormat = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: '', // No image URL from API
              width: ScreenUtils.isTablet(context) ||
                      ScreenUtils.isDesktop(context)
                  ? 80
                  : 60,
              height: ScreenUtils.isTablet(context) ||
                      ScreenUtils.isDesktop(context)
                  ? 80
                  : 60,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                width: ScreenUtils.isTablet(context) ||
                        ScreenUtils.isDesktop(context)
                    ? 80
                    : 60,
                height: ScreenUtils.isTablet(context) ||
                        ScreenUtils.isDesktop(context)
                    ? 80
                    : 60,
                color: Colors.grey[200],
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                width: ScreenUtils.isTablet(context) ||
                        ScreenUtils.isDesktop(context)
                    ? 80
                    : 60,
                height: ScreenUtils.isTablet(context) ||
                        ScreenUtils.isDesktop(context)
                    ? 80
                    : 60,
                color: Colors.grey[200],
                child: Image.asset(
                  'assets/placeholder.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Product Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.productName,
                  style: TextStyle(
                    fontSize: ScreenUtils.isTablet(context) ||
                            ScreenUtils.isDesktop(context)
                        ? 20
                        : 15,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Mã: ${product.productCode}',
                  style: TextStyle(
                    fontSize: ScreenUtils.isTablet(context) ||
                            ScreenUtils.isDesktop(context)
                        ? 18
                        : 12,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      currencyFormat.format(product.price),
                      style: TextStyle(
                        fontSize: ScreenUtils.isTablet(context) ||
                                ScreenUtils.isDesktop(context)
                            ? 18
                            : 14,
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      ' x ${product.qty}',
                      style: TextStyle(
                        fontSize: ScreenUtils.isTablet(context) ||
                                ScreenUtils.isDesktop(context)
                            ? 18
                            : 14,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Thành tiền: ${currencyFormat.format(product.totalPrice)}',
                  style: TextStyle(
                    fontSize: ScreenUtils.isTablet(context) ||
                            ScreenUtils.isDesktop(context)
                        ? 18
                        : 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(BuildContext context, OrderDetailEntity order) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.calculate, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Tổng kết',
                  style: TextStyle(
                    fontSize: ScreenUtils.isTablet(context) ||
                            ScreenUtils.isDesktop(context)
                        ? 20
                        : 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            _buildSummaryRow(
                context, 'Tổng tiền hàng', order.orderTotal, false),
            if (order.fDiscount > 0 || order.mDiscount > 0)
              _buildSummaryRow(
                context,
                'Giảm giá',
                order.fDiscount + order.mDiscount,
                false,
                isDiscount: true,
              ),
            if (order.fVat > 0 || order.mVat > 0)
              _buildSummaryRow(context, 'VAT', order.fVat + order.mVat, false),
            const Divider(),
            _buildSummaryRow(
              context,
              'Tổng thanh toán',
              order.orderTotalDiscount,
              true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.black,
                fontSize: ScreenUtils.isTablet(context) ||
                        ScreenUtils.isDesktop(context)
                    ? 18
                    : 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: ScreenUtils.isTablet(context) ||
                        ScreenUtils.isDesktop(context)
                    ? 18
                    : 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
      BuildContext context, String label, double value, bool isBold,
      {bool isDiscount = false}) {
    final currencyFormat = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: ScreenUtils.isTablet(context) ||
                      ScreenUtils.isDesktop(context)
                  ? (isBold ? 20 : 16)
                  : (isBold ? 18 : 14),
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isDiscount ? Colors.red : null,
            ),
          ),
          Text(
            '${isDiscount ? '-' : ''}${currencyFormat.format(value)}',
            style: TextStyle(
              fontSize: ScreenUtils.isTablet(context) ||
                      ScreenUtils.isDesktop(context)
                  ? (isBold ? 20 : 16)
                  : (isBold ? 18 : 14),
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: isDiscount ? Colors.red : (isBold ? Colors.red : null),
            ),
          ),
        ],
      ),
    );
  }
}
