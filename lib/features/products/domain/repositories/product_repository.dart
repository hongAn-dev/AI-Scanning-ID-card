import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/product.dart';
import '../entities/product_detail.dart';
import '../entities/product_group.dart';

abstract class ProductRepository {
  Future<Either<Failure, List<Product>>> getProducts({
    String? productName,
    String? productCode,
    String? productGroupId,
    int pageSize = 50,
    int pageIndex = 0,
  });
  Future<Either<Failure, Product>> getProductById(int id);
  Future<Either<Failure, ProductDetail>> getProductDetail(String productId);
  Future<Either<Failure, List<Product>>> getProductsByCategory(String category);
  Future<Either<Failure, List<ProductGroup>>> getProductGroups();
}
