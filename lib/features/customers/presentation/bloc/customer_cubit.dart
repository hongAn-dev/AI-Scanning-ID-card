import '../../../../core/utils/string_utils.dart';
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

  // No longer forcing "KH" filter
  String get _effectiveSearchText => _currentSearchQuery;

  // Cache for local search
  // List<Customer> _allCustomers = []; // Removed as per instruction

  Future<void> loadCustomers({bool refresh = false}) async {
    if (_isFetching) return;
    print(
        "Cubit: loadCustomers(refresh: $refresh) called. Search: '$_currentSearchQuery'");

    if (refresh) {
      _currentPage = 0;
      // Note: Do NOT clear _currentSearchQuery on refresh if we want to refresh the current search result
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
    // Since we fetch 1000 items, loadMore might be redundant or just same logic
    // For now, keep existing logic but update _allCustomers
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

  // ... addCustomer/deleteCustomer update _allCustomers too ...

  Future<void> addCustomer(Customer customer) async {
    emit(CustomerLoading());
    try {
      await repository.addCustomer(customer);
      // Reload to ensure consistency
      loadCustomers(refresh: true);
    } catch (e) {
      emit(CustomerError(message: "Lỗi thêm khách hàng: $e"));
    }
  }

  Future<void> deleteCustomer(String id) async {
    emit(CustomerLoading());
    try {
      // Optimistic remove (Optional, but let's just rely on reload for now to be safe with Loading state)
      // actually, if we emit Loading, the list shows loading. So optimistic update isn't shown securely.
      // Let's just do standard: Loading -> Delete API -> Success -> Refresh.

      await repository.deleteCustomer(id);
      loadCustomers(refresh: true);
    } catch (e) {
      emit(CustomerError(message: "Lỗi xóa khách hàng: $e"));
      loadCustomers(refresh: true); // Revert on error
    }
  }

  // Server-side search
  void searchCustomers(String query) {
    print("SEARCH (Server): '$query'");
    _currentSearchQuery = query.trim();
    _currentPage = 0;

    // Create query specific state or just use loadCustomers
    // Using loadCustomers(refresh: true) effectively does the search
    // But we need to handle the debounce which is UI side.
    // Here we just execute the fetch.

    emit(CustomerLoading());
    loadCustomers(refresh: true);
  }

  Future<void> updateCustomer(Customer customer) async {
    emit(CustomerLoading()); // Show loading UI immediately
    try {
      print("Cubit: Attempting update via Delete -> Add strategy...");
      // 1. Delete old customer
      if (customer.id.isNotEmpty) {
        print("   -> Deleting old customer ID: ${customer.id}");
        await repository.deleteCustomer(customer.id);
      }

      // 2. Add as new customer (Backend will generate new ID)
      print("   -> Adding new customer data...");
      await repository.addCustomer(customer);

      // 3. Refresh list
      print("   ✅ Update (Replacement) successful. Refreshing list...");
      loadCustomers(refresh: true);
    } catch (e) {
      print("❌ Error during update (replacement): $e");
      emit(CustomerError(message: "Lỗi cập nhật khách hàng (Replacement): $e"));
      // Refresh to ensure consistent state
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
    emit(CustomerInitial()); // Reset về trạng thái ban đầu
  }
}
