import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:masterpro_ai_scan_id/core/network/network_info.dart';
import 'package:masterpro_ai_scan_id/features/customers/data/datasources/customer_remote_data_source.dart';
import 'package:masterpro_ai_scan_id/features/customers/data/repositories/customer_repository_impl.dart';
import 'package:masterpro_ai_scan_id/features/customers/domain/repositories/customer_repository.dart';
import 'package:masterpro_ai_scan_id/features/customers/domain/usecases/add_customer.dart';
import 'package:masterpro_ai_scan_id/features/customers/domain/usecases/get_customer_groups.dart';
import 'package:masterpro_ai_scan_id/features/customers/domain/usecases/get_customers.dart';
import 'package:masterpro_ai_scan_id/features/customers/presentation/bloc/customer_cubit.dart';
// Orders feature removed for customer-only app
import 'package:shared_preferences/shared_preferences.dart';

import 'core/database/database_helper.dart';
import 'core/network/dio_client.dart';
import 'features/auth/data/auth_service.dart';
// Cart feature removed for customer-only app
import 'features/customers/data/datasources/customer_local_data_source.dart';
// Products feature removed for customer-only app
import 'features/users/data/datasources/user_remote_data_source.dart';
import 'features/users/data/repositories/user_repository_impl.dart';
import 'features/users/domain/repositories/user_repository.dart';
import 'features/users/domain/usecases/get_user_by_id.dart';
import 'features/users/domain/usecases/get_users.dart';
import 'features/users/presentation/bloc/user_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  //! Features - Auth
  sl.registerLazySingleton<AuthService>(() => AuthService(sl(), sl()));

  //! Features - Customers
  // Cubit
  sl.registerFactory(
    () => CustomerCubit(repository: sl()),
  );

  // Use cases
  sl.registerLazySingleton(() => GetCustomers(sl()));
  sl.registerLazySingleton(() => GetCustomerGroups(sl()));
  sl.registerLazySingleton(() => AddCustomer(sl()));

  // Repository
  sl.registerLazySingleton<CustomerRepository>(
    () => CustomerRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
    ),
  );

  // Data sources
  sl.registerLazySingleton(() => CustomerLocalDataSourceImpl());

  sl.registerLazySingleton(
    () => CustomerRemoteDataSourceImpl(
      dioClient: sl(),
    ),
  );

  //! Features - Cart
  // Cart feature removed

  //! Features - Orders
  // Orders feature removed

  //! Features - Products
  // Products feature removed

  //! Features - Users
  // Bloc
  sl.registerFactory(
    () => UserBloc(
      getUsers: sl(),
      getUserById: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetUsers(sl()));
  sl.registerLazySingleton(() => GetUserById(sl()));

  // Repository
  sl.registerLazySingleton<UserRepository>(
    () => UserRepositoryImpl(
      remoteDataSource: sl(),
    ),
  );

  // Data sources
  sl.registerLazySingleton<UserRemoteDataSource>(
    () => UserRemoteDataSourceImpl(
      dioClient: sl(),
    ),
  );

  //! Core
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));
  sl.registerLazySingleton(() => DioClient(sl()));
  sl.registerLazySingleton(() => DatabaseHelper.instance);

  //! External
  sl.registerLazySingleton(() => Dio());
  sl.registerLazySingleton(() => InternetConnectionChecker());

  // SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);
}

// Cart feature removed; no reset needed
