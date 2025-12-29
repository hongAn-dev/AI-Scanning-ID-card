part of 'customer_bloc.dart';

abstract class CustomerEvent extends Equatable {
  const CustomerEvent();

  @override
  List<Object?> get props => [];
}

class FetchCustomersEvent extends CustomerEvent {
  final String searchText;
  final String? groupId;
  final int pageIndex;
  final int pageSize;

  const FetchCustomersEvent({
    this.searchText = '',
    this.groupId,
    this.pageIndex = 0,
    this.pageSize = 20,
  });

  @override
  List<Object?> get props => [searchText, groupId, pageIndex, pageSize];
}

class FetchCustomerGroupsEvent extends CustomerEvent {
  const FetchCustomerGroupsEvent();
}

class AddCustomerEvent extends CustomerEvent {
  final Customer customer;

  const AddCustomerEvent(this.customer);

  @override
  List<Object?> get props => [customer];
}
