import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/cart_item.dart';
import '../../domain/entities/discount_type.dart';
import '../bloc/cart_bloc.dart';

class CartItemCard extends StatefulWidget {
  final CartItem item;

  const CartItemCard({super.key, required this.item});

  @override
  State<CartItemCard> createState() => _CartItemCardState();
}

class _CartItemCardState extends State<CartItemCard> {
  final TextEditingController _discountController = TextEditingController();
  late DiscountType _selectedDiscountType;

  @override
  void initState() {
    super.initState();
    _selectedDiscountType = widget.item.discountType;
    if (widget.item.discountValue > 0) {
      _discountController.text = widget.item.discountValue.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _discountController.dispose();
    super.dispose();
  }

  void _updateDiscount() {
    final value = double.tryParse(_discountController.text) ?? 0;
    context.read<CartBloc>().add(
          UpdateDiscountEvent(
            productId: widget.item.product.id,
            discountValue: value,
            discountType: _selectedDiscountType,
          ),
        );
  }

  Widget _buildProductImage() {
    final hasImage = widget.item.product.picture.isNotEmpty ||
        widget.item.product.imageUrls.isNotEmpty;

    if (!hasImage) {
      return Image.asset(
        'assets/placeholder.png',
        fit: BoxFit.contain,
      );
    }

    return CachedNetworkImage(
      imageUrl: widget.item.product.picture.isNotEmpty
          ? widget.item.product.picture
          : widget.item.product.imageUrls.first,
      fit: BoxFit.contain,
      placeholder: (context, url) => const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      errorWidget: (context, url, error) => Image.asset(
        'assets/placeholder.png',
        fit: BoxFit.contain,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasDiscount = widget.item.discountValue > 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withOpacity(.4), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 80,
                height: 80,
                color: Colors.white,
                child: _buildProductImage(),
              ),
            ),
            const SizedBox(width: 12),

            // Product Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    widget.item.product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),

                  Text(
                    'Tồn: ${widget.item.product.inStock.toStringAsFixed(0)}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Price section
                  if (hasDiscount)
                    Text(
                      '${NumberFormat('#,###', 'vi_VN').format(widget.item.product.price).replaceAll(',', '.')} đ',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  if (hasDiscount) const SizedBox(width: 8),
                  Text(
                    'Giá bán: ${NumberFormat('#,###', 'vi_VN').format(widget.item.priceAfterDiscount).replaceAll(',', '.')} đ / ${widget.item.product.unit}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: hasDiscount ? Colors.red : Colors.red,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Discount Input Row
                  Row(
                    children: [
                      // VND Box
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedDiscountType = DiscountType.vnd;
                            _updateDiscount();
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _selectedDiscountType == DiscountType.vnd
                                ? Colors.red
                                : Colors.grey[200],
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: _selectedDiscountType == DiscountType.vnd
                                  ? Colors.red
                                  : Colors.grey[400]!,
                            ),
                          ),
                          child: Text(
                            'VND',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _selectedDiscountType == DiscountType.vnd
                                  ? Colors.white
                                  : Colors.grey[700],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),

                      // % Box
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedDiscountType = DiscountType.percent;
                            _updateDiscount();
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _selectedDiscountType == DiscountType.percent
                                ? Colors.red
                                : Colors.grey[200],
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color:
                                  _selectedDiscountType == DiscountType.percent
                                      ? Colors.red
                                      : Colors.grey[400]!,
                            ),
                          ),
                          child: Text(
                            '%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color:
                                  _selectedDiscountType == DiscountType.percent
                                      ? Colors.white
                                      : Colors.grey[700],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Discount Input
                      Expanded(
                        child: SizedBox(
                          height: 32,
                          child: TextField(
                            controller: _discountController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d+\.?\d{0,2}'),
                              ),
                            ],
                            decoration: InputDecoration(
                              hintText:
                                  _selectedDiscountType == DiscountType.percent
                                      ? '0-100'
                                      : '0',
                              hintStyle: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide:
                                    BorderSide(color: Colors.grey[600]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide:
                                    BorderSide(color: Colors.grey[600]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: const BorderSide(
                                  color: Colors.red,
                                ),
                              ),
                              isDense: true,
                            ),
                            style: const TextStyle(fontSize: 13),
                            onChanged: (value) {
                              // Auto update when typing
                              _updateDiscount();
                            },
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Quantity Controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () {
                              context.read<CartBloc>().add(
                                    DecreaseQuantityEvent(
                                        productId: widget.item.product.id),
                                  );
                            },
                            iconSize: 24,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            color: Colors.red,
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width:
                                60, // Adjust width as needed for the input field
                            child: TextFormField(
                              key: ValueKey(widget.item.product
                                  .id), // Forces rebuild if quantity changes
                              initialValue: widget.item.quantity.toString(),
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 4,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                  borderSide:
                                      BorderSide(color: Colors.grey[600]!),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                  borderSide:
                                      BorderSide(color: Colors.grey[600]!),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                  borderSide: const BorderSide(
                                    color: Colors.red,
                                  ),
                                ),
                                isDense: true,
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              onChanged: (value) {
                                // If empty, set quantity to 0
                                // if (value.trim().isEmpty) {
                                //   context.read<CartBloc>().add(
                                //         UpdateCartItemQuantityEvent(
                                //           productId: widget.item.product.id,
                                //           quantity: 0,
                                //         ),
                                //       );
                                //   return;
                                // }

                                // Parse the value as integer
                                int? newQuantity = int.tryParse(value);

                                if (newQuantity != null && newQuantity >= 0) {
                                  context.read<CartBloc>().add(
                                        UpdateCartItemQuantityEvent(
                                          productId: widget.item.product.id,
                                          quantity: newQuantity,
                                        ),
                                      );
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () {
                              context.read<CartBloc>().add(
                                    IncreaseQuantityEvent(
                                        productId: widget.item.product.id),
                                  );
                            },
                            iconSize: 24,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            color: Colors.red,
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.red),
                            onPressed: () {
                              context.read<CartBloc>().add(
                                    RemoveFromCartEvent(
                                        productId: widget.item.product.id),
                                  );
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Total Price and Delete
          ],
        ),
      ),
    );
  }
}
