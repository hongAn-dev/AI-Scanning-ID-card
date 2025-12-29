import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:masterpro_ghidon/core/network/network_info.dart';
import 'package:masterpro_ghidon/features/customers/data/datasources/customer_remote_data_source.dart';
import 'package:masterpro_ghidon/features/customers/data/repositories/customer_repository_impl.dart';
import 'package:masterpro_ghidon/features/customers/domain/repositories/customer_repository.dart';
import 'package:masterpro_ghidon/features/customers/domain/usecases/add_customer.dart';
import 'package:masterpro_ghidon/features/customers/domain/usecases/get_customer_groups.dart';
import 'package:masterpro_ghidon/features/customers/domain/usecases/get_customers.dart';
import 'package:masterpro_ghidon/features/customers/presentation/bloc/customer_bloc.dart';
import 'package:masterpro_ghidon/features/orders/data/datasources/order_remote_data_source.dart';
import 'package:masterpro_ghidon/features/orders/data/repositories/order_repository_impl.dart';
import 'package:masterpro_ghidon/features/orders/domain/repositories/order_repository.dart';
import 'package:masterpro_ghidon/features/orders/domain/usecases/create_order.dart';
import 'package:masterpro_ghidon/features/orders/domain/usecases/get_order_detail.dart';
import 'package:masterpro_ghidon/features/orders/domain/usecases/get_orders.dart';
import 'package:masterpro_ghidon/features/orders/presentation/bloc/order_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/database/database_helper.dart';
import 'core/network/dio_client.dart';
import 'features/auth/data/auth_service.dart';
import 'features/cart/data/datasources/cart_local_data_source.dart';
import 'features/cart/presentation/bloc/cart_bloc.dart';
import 'features/customers/data/datasources/customer_local_data_source.dart';
import 'features/products/data/datasources/product_remote_data_source.dart';
import 'features/products/data/repositories/product_repository_impl.dart';
import 'features/products/domain/repositories/product_repository.dart';
import 'features/products/domain/usecases/get_product_by_id.dart';
import 'features/products/domain/usecases/get_product_detail.dart';
import 'features/products/domain/usecases/get_product_groups.dart';
import 'features/products/domain/usecases/get_products.dart';
import 'features/products/presentation/bloc/product_bloc.dart';
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
  // Bloc
  sl.registerFactory(
    () => CustomerBloc(
      getCustomers: sl(),
      getCustomerGroups: sl(),
      addCustomer: sl(),
    ),
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
      networkInfo: sl(),
    ),
  );

  // Data sources
  sl.registerLazySingleton<CustomerLocalDataSource>(
    () => CustomerLocalDataSourceImpl(),
  );

  sl.registerLazySingleton<CustomerRemoteDataSource>(
    () => CustomerRemoteDataSourceImpl(
      dioClient: sl(),
    ),
  );

  //! Features - Cart
  // Bloc (Singleton to maintain cart state across the app)
  sl.registerLazySingleton(
    () => CartBloc(localDataSource: sl()),
  );

  // Data sources
  sl.registerLazySingleton<CartLocalDataSource>(
    () => CartLocalDataSourceImpl(databaseHelper: sl()),
  );

  //! Features - Orders
  // Bloc
  sl.registerFactory(
    () => OrderBloc(
      getOrders: sl(),
      getOrderDetail: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetOrders(sl()));
  sl.registerLazySingleton(() => GetOrderDetail(sl()));
  sl.registerLazySingleton(() => CreateOrder(sl()));

  // Repository
  sl.registerLazySingleton<OrderRepository>(
    () => OrderRepositoryImpl(
      remoteDataSource: sl(),
    ),
  );

  // Data sources
  sl.registerLazySingleton<OrderRemoteDataSource>(
    () => OrderRemoteDataSourceImpl(
      dioClient: sl(),
    ),
  );

  //! Features - Products
  // Bloc
  sl.registerFactory(
    () => ProductBloc(
      getProducts: sl(),
      getProductById: sl(),
      getProductGroups: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetProducts(sl()));
  sl.registerLazySingleton(() => GetProductById(sl()));
  sl.registerLazySingleton(() => GetProductDetail(sl()));
  sl.registerLazySingleton(() => GetProductGroups(sl()));

  // Repository
  sl.registerLazySingleton<ProductRepository>(
    () => ProductRepositoryImpl(
      remoteDataSource: sl(),
    ),
  );

  // Data sources
  sl.registerLazySingleton<ProductRemoteDataSource>(
    () => ProductRemoteDataSourceImpl(
      dioClient: sl(),
    ),
  );

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

// Reset CartBloc when user logs out
Future<void> resetCartBloc() async {
  // Close the existing CartBloc if it exists
  if (sl.isRegistered<CartBloc>()) {
    final cartBloc = sl<CartBloc>();
    await cartBloc.close();

    // Unregister the old instance
    await sl.unregister<CartBloc>();
  }

  // Register a new CartBloc instance
  sl.registerLazySingleton(
    () => CartBloc(localDataSource: sl()),
  );
}
