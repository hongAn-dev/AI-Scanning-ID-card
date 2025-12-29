import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:intl/intl.dart';
import 'package:masterpro_ghidon/utils/screen_utils.dart';

import '../../../../injection_container.dart' as di;
import '../../../cart/presentation/bloc/cart_bloc.dart';
import '../../../cart/presentation/pages/cart_page.dart';
import '../../data/models/product_model.dart';
import '../../domain/entities/product_detail.dart';
import '../../domain/usecases/get_product_detail.dart';

class ProductDetailPage extends StatefulWidget {
  final String productId;

  const ProductDetailPage({
    super.key,
    required this.productId,
  });

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  ProductDetail? _productDetail;
  bool _isLoading = true;
  String? _errorMessage;
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _loadProductDetail();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadProductDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final getProductDetail = di.sl<GetProductDetail>();
    final result = await getProductDetail(widget.productId);

    result.fold(
      (failure) {
        setState(() {
          _isLoading = false;
          _errorMessage = failure.message;
        });
      },
      (productDetail) {
        setState(() {
          _isLoading = false;
          _productDetail = productDetail;
        });
      },
    );
  }

  void _addToCart() {
    if (_productDetail == null) return;

    // Create ProductModel (not Product entity) to ensure it can be cast properly
    final product = ProductModel(
      id: _productDetail!.id,
      productCode: _productDetail!.productCode,
      name: _productDetail!.name,
      unit: _productDetail!.unit,
      unitPrice: _productDetail!.unitPrice,
      price: _productDetail!.price,
      inStock: _productDetail!.inStock,
      minInStock: _productDetail!.minInStock,
      maxInStock: _productDetail!.maxInStock,
      branchName: _productDetail!.branchName,
      groupName: _productDetail!.groupName,
      groupId: _productDetail!.groupId,
      description: _productDetail!.description,
      picture: _productDetail!.picture,
      imageUrls: _productDetail!.imageUrls,
      discount: _productDetail!.discount,
      isNew: _productDetail!.isNew,
      isFeature: _productDetail!.isFeature,
    );

    context.read<CartBloc>().add(
          AddToCartEvent(product: product),
        );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Đã thêm vào giỏ hàng'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _buyNow() async {
    if (_productDetail == null) return;

    try {
      // Create ProductModel (not Product entity) to ensure it can be cast properly
      final product = ProductModel(
        id: _productDetail!.id,
        productCode: _productDetail!.productCode,
        name: _productDetail!.name,
        unit: _productDetail!.unit,
        unitPrice: _productDetail!.unitPrice,
        price: _productDetail!.price,
        inStock: _productDetail!.inStock,
        minInStock: _productDetail!.minInStock,
        maxInStock: _productDetail!.maxInStock,
        branchName: _productDetail!.branchName,
        groupName: _productDetail!.groupName,
        groupId: _productDetail!.groupId,
        description: _productDetail!.description,
        picture: _productDetail!.picture,
        imageUrls: _productDetail!.imageUrls,
        discount: _productDetail!.discount,
        isNew: _productDetail!.isNew,
        isFeature: _productDetail!.isFeature,
      );

      if (mounted) {
        // Get CartBloc reference before navigation
        final cartBloc = context.read<CartBloc>();

        // Add to cart first
        cartBloc.add(AddToCartEvent(product: product));

        // Wait a bit for the event to be processed
        await Future.delayed(const Duration(milliseconds: 100));

        // Navigate to cart page
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: cartBloc,
                child: const CartPage(),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết sản phẩm'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadProductDetail,
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                )
              : _buildProductDetail(),
      bottomNavigationBar: _productDetail != null
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _addToCart,
                      icon: const Icon(Icons.add_shopping_cart),
                      label: Text('Thêm vào giỏ',
                          style: TextStyle(
                              fontSize: ScreenUtils.isTablet(context) ||
                                      ScreenUtils.isDesktop(context)
                                  ? 20
                                  : 16)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Colors.red),
                        foregroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _buyNow,
                      icon: const Icon(Icons.shopping_bag),
                      label: Text('Mua ngay',
                          style: TextStyle(
                              fontSize: ScreenUtils.isTablet(context) ||
                                      ScreenUtils.isDesktop(context)
                                  ? 20
                                  : 16)),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }

  Widget _buildProductDetail() {
    if (_productDetail == null) return const SizedBox.shrink();

    final images = _productDetail!.imageUrls.isNotEmpty
        ? _productDetail!.imageUrls
        : [_productDetail!.picture];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Carousel
          Stack(
            children: [
              Container(
                height: 350,
                color: Colors.white,
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentImageIndex = index;
                    });
                  },
                  itemCount: images.length,
                  itemBuilder: (context, index) {
                    return CachedNetworkImage(
                      imageUrl: images[index],
                      fit: BoxFit.contain,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      errorWidget: (context, url, error) => const Center(
                        child: Icon(Icons.image_not_supported, size: 64),
                      ),
                    );
                  },
                ),
              ),
              // Badges
              Positioned(
                top: 16,
                left: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_productDetail!.isNew)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'MỚI',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    if (_productDetail!.discount > 0) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '-${_productDetail!.discount.toInt()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Image indicators
              if (images.length > 1)
                Positioned(
                  bottom: 16,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      images.length,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _currentImageIndex == index
                              ? Colors.red
                              : Colors.grey[300],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // Product Info
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Name
                Text(
                  _productDetail!.name,
                  style: TextStyle(
                    fontSize: ScreenUtils.isTablet(context) ||
                            ScreenUtils.isDesktop(context)
                        ? 28
                        : 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                // Category and Brand
                Row(
                  children: [
                    _buildTag(Icons.category, _productDetail!.groupName),
                    const SizedBox(width: 12),
                    if (_productDetail!.branchName.isNotEmpty)
                      _buildTag(Icons.business, _productDetail!.branchName),
                  ],
                ),
                const SizedBox(height: 16),

                // Price
                Row(
                  children: [
                    Text(
                      '${NumberFormat('#,###', 'vi_VN').format(_productDetail!.price).replaceAll(',', '.')} đ',
                      style: TextStyle(
                        fontSize: ScreenUtils.isTablet(context) ||
                                ScreenUtils.isDesktop(context)
                            ? 28
                            : 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '/${_productDetail!.unit}',
                      style: TextStyle(
                        fontSize: ScreenUtils.isTablet(context) ||
                                ScreenUtils.isDesktop(context)
                            ? 20
                            : 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Stock Status
                Row(
                  children: [
                    Icon(
                      _productDetail!.inStock > 0
                          ? Icons.check_circle
                          : Icons.cancel,
                      size: 20,
                      color: _productDetail!.inStock > 0
                          ? Colors.green
                          : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _productDetail!.inStock > 0
                          ? 'Còn hàng (${_productDetail!.inStock.toInt()} ${_productDetail!.unit})'
                          : 'Hết hàng',
                      style: TextStyle(
                        fontSize: ScreenUtils.isTablet(context) ||
                                ScreenUtils.isDesktop(context)
                            ? 20
                            : 16,
                        color: _productDetail!.inStock > 0
                            ? Colors.green
                            : Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Description
          if (_productDetail!.description.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mô tả sản phẩm',
                    style: TextStyle(
                      fontSize: ScreenUtils.isTablet(context) ||
                              ScreenUtils.isDesktop(context)
                          ? 28
                          : 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Html(
                    data: _productDetail!.description,
                    style: {
                      "body": Style(
                        margin: Margins.zero,
                        padding: HtmlPaddings.zero,
                      ),
                      "p": Style(
                        fontSize: FontSize(ScreenUtils.isTablet(context) ||
                                ScreenUtils.isDesktop(context)
                            ? 20
                            : 16),
                        lineHeight: const LineHeight(1.6),
                      ),
                      "h2": Style(
                        fontSize: FontSize(ScreenUtils.isTablet(context) ||
                                ScreenUtils.isDesktop(context)
                            ? 28
                            : 22),
                        fontWeight: FontWeight.bold,
                      ),
                      "table": Style(
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      "td": Style(
                        padding: HtmlPaddings.all(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                    },
                  ),
                ],
              ),
            ),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildTag(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey[700]),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: ScreenUtils.isTablet(context) ||
                      ScreenUtils.isDesktop(context)
                  ? 16
                  : 12,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}
