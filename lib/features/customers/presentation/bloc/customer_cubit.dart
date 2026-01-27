import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/customer.dart';
import '../../domain/repositories/customer_repository.dart';
import 'customer_state.dart';

class CustomerCubit extends Cubit<CustomerState> {
  final CustomerRepository repository;

  CustomerCubit({required this.repository}) : super(CustomerInitial());

  int _currentPage = 0;
  bool _isFetching = false;
  String _currentSearchQuery = "";
  final int _pageSize = 20;

  // Cache for local search
  // List<Customer> _allCustomers = []; // Removed as per instruction

  Future<void> loadCustomers({bool refresh = false}) async {
    if (_isFetching) return;
    print(
        "Cubit: loadCustomers(refresh: $refresh) called. Search: '$_currentSearchQuery'");

    if (refresh) {
      _currentPage = 0;
      emit(CustomerLoading());
    } else if (state is CustomerInitial) {
      emit(CustomerLoading());
    }

    _isFetching = true;
    try {
      final rawCustomers = await repository.getCustomers(
          pageIndex: _currentPage,
          pageSize: _pageSize,
          searchText: _currentSearchQuery);

      _isFetching = false;

      if (_currentPage == 0) {
        emit(CustomerLoaded(
          customers: rawCustomers,
          hasReachedMax: rawCustomers.length < _pageSize,
        ));
      } else {
        if (state is CustomerLoaded) {
          final currentList = (state as CustomerLoaded).customers;
          emit(CustomerLoaded(
            customers: currentList + rawCustomers,
            hasReachedMax: rawCustomers.length < _pageSize,
          ));
        }
      }
    } catch (e) {
      _isFetching = false;
      print("Cubit: Load failed with error: $e");
      emit(CustomerError(message: e.toString()));
    }
  }

  Future<void> loadMoreCustomers() async {
    if (_isFetching) return;
    final currentState = state;
    if (currentState is CustomerLoaded && !currentState.hasReachedMax) {
      _isFetching = true;
      try {
        final nextPage = _currentPage + 1;
        final rawCustomers = await repository.getCustomers(
            pageIndex: nextPage,
            pageSize: _pageSize,
            searchText: _currentSearchQuery);

        if (rawCustomers.isEmpty) {
          emit(currentState.copyWith(hasReachedMax: true));
        } else {
          _currentPage = nextPage;
          emit(currentState.copyWith(
            customers: List.of(currentState.customers)..addAll(rawCustomers),
            hasReachedMax: rawCustomers.length < _pageSize,
          ));
        }
        _isFetching = false;
      } catch (e) {
        _isFetching = false;
        print("Cubit: Load more failed: $e");
      }
    }
  }

  Future<void> addCustomer(Customer customer) async {
    emit(CustomerLoading());
    try {
      await repository.addCustomer(customer);
      // Reload to ensure consistency (Repo handles mock data persistence in Demo)
      loadCustomers(refresh: true);
    } catch (e) {
      emit(CustomerError(message: "Lỗi thêm khách hàng: $e"));
    }
  }

  Future<void> deleteCustomer(String id) async {
    emit(CustomerLoading());
    try {
      await repository.deleteCustomer(id);
      loadCustomers(refresh: true);
    } catch (e) {
      emit(CustomerError(message: "Lỗi xóa khách hàng: $e"));
      loadCustomers(refresh: true);
    }
  }

  // Server-side search (Repo handles local filter in Demo)
  void searchCustomers(String query) {
    print("SEARCH (Server): '$query'");
    _currentSearchQuery = query.trim();
    _currentPage = 0;
    emit(CustomerLoading());
    loadCustomers(refresh: true);
  }

  Future<void> updateCustomer(Customer customer) async {
    emit(CustomerLoading());
    try {
      await repository.updateCustomer(customer);
      loadCustomers(refresh: true);
    } catch (e) {
      print("❌ Error during update: $e");
      emit(CustomerError(message: "Lỗi cập nhật khách hàng: $e"));
      loadCustomers(refresh: true);
    }
  }

  Future<bool> checkCustomerExists(
      String identityNumber, String code, String name) async {
    try {
      return await repository.checkCustomerExists(identityNumber, code, name);
    } catch (e) {
      print("Check exists failed: $e");
      return false;
    }
  }

  /// Reset toàn bộ dữ liệu (Gọi khi Logout)
  void reset() {
    print("Cubit: RESETTING DATA...");
    _currentPage = 0;
    _currentSearchQuery = "";
    _isFetching = false;
    emit(CustomerInitial());
  }
}
