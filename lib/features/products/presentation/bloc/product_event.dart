part of 'product_bloc.dart';

abstract class ProductEvent extends Equatable {
  const ProductEvent();

  @override
  List<Object?> get props => [];
}

class GetProductsEvent extends ProductEvent {
  final String? searchQuery;
  final String? productGroupId;

  const GetProductsEvent({this.searchQuery, this.productGroupId});

  @override
  List<Object?> get props => [searchQuery, productGroupId];
}

class LoadMoreProductsEvent extends ProductEvent {
  final String? searchQuery;
  final String? productGroupId;

  const LoadMoreProductsEvent({this.searchQuery, this.productGroupId});

  @override
  List<Object?> get props => [searchQuery, productGroupId];
}

class GetProductGroupsEvent extends ProductEvent {}

class GetProductByIdEvent extends ProductEvent {
  final int id;

  const GetProductByIdEvent({required this.id});

  @override
  List<Object> get props => [id];
}
