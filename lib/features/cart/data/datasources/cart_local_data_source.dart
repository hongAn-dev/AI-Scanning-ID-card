import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../../../core/database/database_helper.dart';
import '../../../../core/error/exceptions.dart';
import '../models/cart_item_model.dart';

abstract class CartLocalDataSource {
  Future<List<CartItemModel>> getCartItems();
  Future<void> addCartItem(CartItemModel item);
  Future<void> updateCartItem(CartItemModel item);
  Future<void> removeCartItem(String productId);
  Future<void> clearCart();
}

class CartLocalDataSourceImpl implements CartLocalDataSource {
  final DatabaseHelper databaseHelper;

  CartLocalDataSourceImpl({required this.databaseHelper});

  @override
  Future<List<CartItemModel>> getCartItems() async {
    try {
      final db = await databaseHelper.database;
      final result = await db.query('cart_items', orderBy: 'created_at DESC');

      return result.map((row) {
        final productData = jsonDecode(row['product_data'] as String);
        return CartItemModel.fromDatabase(
          id: row['id'].toString(),
          productData: productData,
          quantity: row['quantity'] as int,
        );
      }).toList();
    } catch (e) {
      throw CacheException('Failed to get cart items: $e');
    }
  }

  @override
  Future<void> addCartItem(CartItemModel item) async {
    try {
      final db = await databaseHelper.database;

      // Check if item already exists
      final existing = await db.query(
        'cart_items',
        where: 'product_id = ?',
        whereArgs: [item.product.id],
      );

      if (existing.isNotEmpty) {
        // Update quantity if exists
        final currentQuantity = existing.first['quantity'] as int;
        await db.update(
          'cart_items',
          {
            'quantity': currentQuantity + item.quantity,
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'product_id = ?',
          whereArgs: [item.product.id],
        );
      } else {
        // Insert new item
        await db.insert(
          'cart_items',
          item.toDatabase(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    } catch (e) {
      throw CacheException('Failed to add cart item: $e');
    }
  }

  @override
  Future<void> updateCartItem(CartItemModel item) async {
    try {
      final db = await databaseHelper.database;

      if (item.quantity <= 0) {
        await removeCartItem(item.product.id);
        return;
      }

      await db.update(
        'cart_items',
        {
          'quantity': item.quantity,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'product_id = ?',
        whereArgs: [item.product.id],
      );
    } catch (e) {
      throw CacheException('Failed to update cart item: $e');
    }
  }

  @override
  Future<void> removeCartItem(String productId) async {
    try {
      final db = await databaseHelper.database;
      await db.delete(
        'cart_items',
        where: 'product_id = ?',
        whereArgs: [productId],
      );
    } catch (e) {
      throw CacheException('Failed to remove cart item: $e');
    }
  }

  @override
  Future<void> clearCart() async {
    try {
      final db = await databaseHelper.database;
      await db.delete('cart_items');
    } catch (e) {
      throw CacheException('Failed to clear cart: $e');
    }
  }
}
