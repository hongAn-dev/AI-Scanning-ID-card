import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/customer.dart';
import '../repositories/customer_repository.dart';

class GetCustomers implements UseCase<List<Customer>, GetCustomersParams> {
  final CustomerRepository repository;

  GetCustomers(this.repository);

  @override
  Future<Either<Failure, List<Customer>>> call(
      GetCustomersParams params) async {
    return await repository.getCustomers(
      searchText: params.searchText,
      email: params.email,
      groupId: params.groupId,
      pageIndex: params.pageIndex,
      pageSize: params.pageSize,
    );
  }
}

class GetCustomersParams extends Equatable {
  final String searchText;
  final String? email;
  final String? groupId;
  final int pageIndex;
  final int pageSize;

  const GetCustomersParams({
    this.searchText = '',
    this.email,
    this.groupId,
    this.pageIndex = 0,
    this.pageSize = 20,
  });

  @override
  List<Object?> get props => [searchText, email, groupId, pageIndex, pageSize];
}
