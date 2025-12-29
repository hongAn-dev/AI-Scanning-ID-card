import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/customer_group.dart';
import '../../domain/repositories/customer_repository.dart';
import '../datasources/customer_local_data_source.dart';
import '../datasources/customer_remote_data_source.dart';
import '../models/customer_model.dart';

class CustomerRepositoryImpl implements CustomerRepository {
  final CustomerRemoteDataSource remoteDataSource;
  final CustomerLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  CustomerRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<Customer>>> getCustomers({
    String searchText = '',
    String? email,
    String? groupId,
    int pageIndex = 0,
    int pageSize = 20,
  }) async {
    // if (await networkInfo.isConnected) {
    try {
      final remoteCustomers = await remoteDataSource.getCustomers(
        searchText: searchText,
        email: email,
        groupId: groupId,
        pageIndex: pageIndex,
        pageSize: pageSize,
      );
      return Right(remoteCustomers);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
    // }
    //  else {
    //   try {
    //     final localCustomers = localDataSource.getCustomers(
    //       groupId: groupId != null ? int.tryParse(groupId) : null,
    //     );
    //     return Right(localCustomers);
    //   } on CacheException catch (e) {
    //     return Left(CacheFailure(e.message));
    //   }
    // }
  }

  @override
  Future<Either<Failure, List<CustomerGroup>>> getCustomerGroups() async {
    try {
      // Try to get from API first
      final customerGroups = await remoteDataSource.getCustomerGroups();
      return Right(customerGroups);
    } on ServerException catch (e) {
      // Fallback to local data source if API fails
      try {
        final localGroups = localDataSource.getCustomerGroups();
        return Right(localGroups);
      } on CacheException catch (_) {
        return Left(ServerFailure(e.message));
      }
    }
  }

  @override
  Future<Either<Failure, Customer>> addCustomer(Customer customer) async {
    try {
      // Use API to add customer
      final newCustomer = await remoteDataSource.addNewCustomer(
        fullname: customer.name,
        mobile: customer.phone,
        address: customer.address,
        groupId: customer.group?.uuid,
        note: customer.note,
      );

      // Optionally save to local cache for offline access
      try {
        localDataSource.addCustomer(newCustomer);
      } catch (_) {
        // Ignore cache errors, API call succeeded
      }

      return Right(newCustomer);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> updateCustomer(Customer customer) async {
    try {
      final customerModel = CustomerModel(
        id: customer.id,
        name: customer.name,
        phone: customer.phone,
        address: customer.address,
        note: customer.note,
        group: customer.group,
        createdAt: customer.createdAt,
      );
      localDataSource.updateCustomer(customerModel);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> deleteCustomer(String id) async {
    try {
      localDataSource.deleteCustomer(int.parse(id));
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }
}
