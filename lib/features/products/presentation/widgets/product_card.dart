import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../cart/presentation/bloc/cart_bloc.dart';
import '../../../cart/presentation/pages/cart_page.dart';
import '../../domain/entities/product.dart';
import '../pages/product_detail_page.dart';

class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  Widget _buildProductImage() {
    final hasImage = product.picture.isNotEmpty || product.imageUrls.isNotEmpty;

    if (!hasImage) {
      return Image.asset(
        'assets/placeholder.png',
        fit: BoxFit.contain,
      );
    }

    return CachedNetworkImage(
      imageUrl: product.picture.isNotEmpty
          ? product.picture
          : product.imageUrls.first,
      fit: BoxFit.contain,
      placeholder: (context, url) => const Center(
        child: CircularProgressIndicator(),
      ),
      errorWidget: (context, url, error) => Image.asset(
        'assets/placeholder.png',
        fit: BoxFit.contain,
      ),
    );
  }

  void _openProductDetail(BuildContext context) {
    // Get CartBloc reference before navigation
    final cartBloc = context.read<CartBloc>();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: cartBloc,
          child: ProductDetailPage(
            productId: product.id,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withOpacity(.4), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          Expanded(
            flex: 3,
            child: GestureDetector(
              onTap: () => _openProductDetail(context),
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                child: Container(
                  width: double.infinity,
                  color: Colors.white,
                  child: _buildProductImage(),
                ),
              ),
            ),
          ),

          // Product Info
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title - Clickable
                GestureDetector(
                  onTap: () => _openProductDetail(context),
                  child: Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 6),

                // Price and Stock
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${NumberFormat('#,###', 'vi_VN').format(product.price).replaceAll(',', '.')} đ${product.unit.isNotEmpty ? ' / ${product.unit}' : ''}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Action Buttons
                Row(
                  children: [
                    // Add to Cart Button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          try {
                            if (context.mounted) {
                              context
                                  .read<CartBloc>()
                                  .add(AddToCartEvent(product: product));

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Đã thêm ${product.name} vào giỏ hàng'),
                                  duration: const Duration(seconds: 1),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            // Handle the case where BLoC is closed
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Lỗi: ${e.toString()}'),
                                  duration: const Duration(seconds: 2),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                                color: Colors.grey.withOpacity(.4), width: 1),
                          ),
                          minimumSize: const Size(0, 32),
                        ),
                        child: const Icon(Icons.add_shopping_cart, size: 16),
                      ),
                    ),
                    const SizedBox(width: 6),

                    // Buy Now Button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          try {
                            if (context.mounted) {
                              // Get CartBloc reference before navigation
                              final cartBloc = context.read<CartBloc>();

                              // Add to cart first
                              cartBloc.add(AddToCartEvent(product: product));

                              // Wait a bit for the event to be processed
                              await Future.delayed(
                                  const Duration(milliseconds: 100));

                              // Navigate to cart page with smooth animation
                              if (context.mounted) {
                                Navigator.of(context).push(
                                  PageRouteBuilder(
                                    pageBuilder: (context, animation,
                                        secondaryAnimation) {
                                      return BlocProvider.value(
                                        value: cartBloc,
                                        child: const CartPage(),
                                      );
                                    },
                                    transitionsBuilder: (context, animation,
                                        secondaryAnimation, child) {
                                      const begin = Offset(1.0, 0.0);
                                      const end = Offset.zero;
                                      const curve = Curves.easeInOutCubic;

                                      var tween = Tween(begin: begin, end: end)
                                          .chain(CurveTween(curve: curve));
                                      var offsetAnimation =
                                          animation.drive(tween);

                                      return SlideTransition(
                                        position: offsetAnimation,
                                        child: child,
                                      );
                                    },
                                    transitionDuration:
                                        const Duration(milliseconds: 400),
                                  ),
                                );
                              }
                            }
                          } catch (e) {
                            // Handle the case where BLoC is closed
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Không thể thêm sản phẩm vào giỏ hàng ${e.toString()}'),
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          minimumSize: const Size(0, 32),
                        ),
                        child: const Text(
                          'Mua Ngay',
                          style: TextStyle(fontSize: 11),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
