part of 'product_bloc.dart';

abstract class ProductState extends Equatable {
  const ProductState();

  @override
  List<Object> get props => [];
}

class ProductInitial extends ProductState {}

class ProductLoading extends ProductState {}

class ProductsLoaded extends ProductState {
  final List<Product> products;
  final bool hasReachedMax;
  final int currentPage;
  final bool isLoadingMore;
  final List<ProductGroup> groups;
  final String? selectedGroupId;

  const ProductsLoaded({
    required this.products,
    this.hasReachedMax = false,
    this.currentPage = 0,
    this.isLoadingMore = false,
    this.groups = const [],
    this.selectedGroupId,
  });

  ProductsLoaded copyWith({
    List<Product>? products,
    bool? hasReachedMax,
    int? currentPage,
    bool? isLoadingMore,
    List<ProductGroup>? groups,
    String? selectedGroupId,
  }) {
    return ProductsLoaded(
      products: products ?? this.products,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      currentPage: currentPage ?? this.currentPage,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      groups: groups ?? this.groups,
      selectedGroupId: selectedGroupId ?? this.selectedGroupId,
    );
  }

  @override
  List<Object> get props => [
        products,
        hasReachedMax,
        currentPage,
        isLoadingMore,
        groups,
        selectedGroupId ?? ''
      ];
}

class ProductDetailLoaded extends ProductState {
  final Product product;

  const ProductDetailLoaded({required this.product});

  @override
  List<Object> get props => [product];
}

class ProductError extends ProductState {
  final String message;

  const ProductError({required this.message});

  @override
  List<Object> get props => [message];
}
