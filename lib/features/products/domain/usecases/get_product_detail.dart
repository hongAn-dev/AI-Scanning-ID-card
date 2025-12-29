import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/product_detail.dart';
import '../repositories/product_repository.dart';

class GetProductDetail implements UseCase<ProductDetail, String> {
  final ProductRepository repository;

  GetProductDetail(this.repository);

  @override
  Future<Either<Failure, ProductDetail>> call(String productId) async {
    return await repository.getProductDetail(productId);
  }
}
