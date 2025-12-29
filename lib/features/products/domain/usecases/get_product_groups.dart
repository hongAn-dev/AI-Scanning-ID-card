import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/product_group.dart';
import '../repositories/product_repository.dart';

class GetProductGroups implements UseCase<List<ProductGroup>, NoParams> {
  final ProductRepository repository;

  GetProductGroups(this.repository);

  @override
  Future<Either<Failure, List<ProductGroup>>> call(NoParams params) {
    return repository.getProductGroups();
  }
}
