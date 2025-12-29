import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/product.dart';
import '../repositories/product_repository.dart';

class GetProducts implements UseCase<List<Product>, ProductParams> {
  final ProductRepository repository;

  GetProducts(this.repository);

  @override
  Future<Either<Failure, List<Product>>> call(ProductParams params) async {
    return await repository.getProducts(
      productName: params.productName,
      productCode: params.productCode,
      productGroupId: params.productGroupId,
      pageSize: params.pageSize,
      pageIndex: params.pageIndex,
    );
  }
}

class ProductParams extends Equatable {
  final String? productName;
  final String? productCode;
  final String? productGroupId;
  final int pageSize;
  final int pageIndex;

  const ProductParams({
    this.productName,
    this.productCode,
    this.productGroupId,
    this.pageSize = 50,
    this.pageIndex = 0,
  });

  @override
  List<Object?> get props =>
      [productName, productCode, productGroupId, pageSize, pageIndex];
}

// Use core NoParams
