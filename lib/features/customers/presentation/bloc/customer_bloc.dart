import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:masterpro_ghidon/features/customers/domain/entities/customer_group.dart';

import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/customer.dart';
import '../../domain/usecases/add_customer.dart';
import '../../domain/usecases/get_customer_groups.dart';
import '../../domain/usecases/get_customers.dart';

part 'customer_event.dart';
part 'customer_state.dart';

class CustomerBloc extends Bloc<CustomerEvent, CustomerState> {
  final GetCustomers getCustomers;
  final GetCustomerGroups getCustomerGroups;
  final AddCustomer addCustomer;

  CustomerBloc({
    required this.getCustomers,
    required this.getCustomerGroups,
    required this.addCustomer,
  }) : super(const CustomerInitial()) {
    on<FetchCustomersEvent>(_onFetchCustomers);
    on<FetchCustomerGroupsEvent>(_onFetchCustomerGroups);
    on<AddCustomerEvent>(_onAddCustomer);
  }

  Future<void> _onFetchCustomers(
    FetchCustomersEvent event,
    Emitter<CustomerState> emit,
  ) async {
    // Preserve groups from current state
    emit(CustomerLoading(groups: state.groups));

    final result = await getCustomers(
      GetCustomersParams(
        searchText: event.searchText,
        groupId: event.groupId,
        pageIndex: event.pageIndex,
        pageSize: event.pageSize,
      ),
    );

    result.fold(
      (failure) => emit(CustomerError(
        message: failure.message,
        groups: state.groups,
      )),
      (customers) => emit(CustomerLoaded(
        customers: customers,
        groups: state.groups,
      )),
    );
  }

  Future<void> _onFetchCustomerGroups(
    FetchCustomerGroupsEvent event,
    Emitter<CustomerState> emit,
  ) async {
    // Preserve customers from current state
    emit(CustomerGroupLoading(customers: state.customers));

    final result = await getCustomerGroups(NoParams());

    result.fold(
      (failure) => emit(CustomerGroupError(
        message: failure.message,
        customers: state.customers,
      )),
      (groups) => emit(CustomerGroupLoaded(
        groups: groups,
        customers: state.customers,
      )),
    );
  }

  Future<void> _onAddCustomer(
    AddCustomerEvent event,
    Emitter<CustomerState> emit,
  ) async {
    // Preserve current state data
    emit(CustomerAdding(
      customers: state.customers,
      groups: state.groups,
    ));

    final result = await addCustomer(event.customer);

    result.fold(
      (failure) => emit(CustomerAddError(
        message: failure.message,
        customers: state.customers,
        groups: state.groups,
      )),
      (customer) => emit(CustomerAdded(
        addedCustomer: customer,
        customers: state.customers,
        groups: state.groups,
      )),
    );
  }
}
