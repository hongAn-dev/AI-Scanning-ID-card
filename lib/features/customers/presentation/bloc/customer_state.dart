part of 'customer_bloc.dart';

abstract class CustomerState extends Equatable {
  final List<Customer> customers;
  final List<CustomerGroup> groups;
  final bool isLoadingCustomers;
  final bool isLoadingGroups;
  final String? errorMessage;

  const CustomerState({
    this.customers = const [],
    this.groups = const [],
    this.isLoadingCustomers = false,
    this.isLoadingGroups = false,
    this.errorMessage,
  });

  @override
  List<Object?> get props => [
        customers,
        groups,
        isLoadingCustomers,
        isLoadingGroups,
        errorMessage,
      ];

  // Helper method to copy state with new values
  CustomerState copyWith({
    List<Customer>? customers,
    List<CustomerGroup>? groups,
    bool? isLoadingCustomers,
    bool? isLoadingGroups,
    String? errorMessage,
  });
}

class CustomerInitial extends CustomerState {
  const CustomerInitial() : super();

  @override
  CustomerState copyWith({
    List<Customer>? customers,
    List<CustomerGroup>? groups,
    bool? isLoadingCustomers,
    bool? isLoadingGroups,
    String? errorMessage,
  }) {
    return CustomerDataState(
      customers: customers ?? this.customers,
      groups: groups ?? this.groups,
      isLoadingCustomers: isLoadingCustomers ?? this.isLoadingCustomers,
      isLoadingGroups: isLoadingGroups ?? this.isLoadingGroups,
      errorMessage: errorMessage,
    );
  }
}

class CustomerDataState extends CustomerState {
  const CustomerDataState({
    super.customers,
    super.groups,
    super.isLoadingCustomers,
    super.isLoadingGroups,
    super.errorMessage,
  });

  @override
  CustomerState copyWith({
    List<Customer>? customers,
    List<CustomerGroup>? groups,
    bool? isLoadingCustomers,
    bool? isLoadingGroups,
    String? errorMessage,
  }) {
    return CustomerDataState(
      customers: customers ?? this.customers,
      groups: groups ?? this.groups,
      isLoadingCustomers: isLoadingCustomers ?? this.isLoadingCustomers,
      isLoadingGroups: isLoadingGroups ?? this.isLoadingGroups,
      errorMessage: errorMessage,
    );
  }
}

// Legacy states for backward compatibility
class CustomerLoading extends CustomerDataState {
  const CustomerLoading({super.groups}) : super(isLoadingCustomers: true);
}

class CustomerLoaded extends CustomerDataState {
  const CustomerLoaded({required super.customers, super.groups});
}

class CustomerError extends CustomerDataState {
  const CustomerError({required String message, super.groups})
      : super(errorMessage: message);
}

class CustomerGroupLoading extends CustomerDataState {
  const CustomerGroupLoading({super.customers}) : super(isLoadingGroups: true);
}

class CustomerGroupLoaded extends CustomerDataState {
  const CustomerGroupLoaded({required super.groups, super.customers});
}

class CustomerGroupError extends CustomerDataState {
  const CustomerGroupError({required String message, super.customers})
      : super(errorMessage: message);
}

// Add Customer States
class CustomerAdding extends CustomerDataState {
  const CustomerAdding({super.customers, super.groups});
}

class CustomerAdded extends CustomerDataState {
  final Customer addedCustomer;

  const CustomerAdded({
    required this.addedCustomer,
    super.customers,
    super.groups,
  });

  @override
  List<Object?> get props => [...super.props, addedCustomer];
}

class CustomerAddError extends CustomerDataState {
  const CustomerAddError({
    required String message,
    super.customers,
    super.groups,
  }) : super(errorMessage: message);
}
