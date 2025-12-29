import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/product_group.dart';
import '../../domain/usecases/get_product_by_id.dart';
import '../../domain/usecases/get_product_groups.dart';
import '../../domain/usecases/get_products.dart';

part 'product_event.dart';
part 'product_state.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final GetProducts getProducts;
  final GetProductById getProductById;
  final GetProductGroups getProductGroups;

  ProductBloc({
    required this.getProducts,
    required this.getProductById,
    required this.getProductGroups,
  }) : super(ProductInitial()) {
    on<GetProductsEvent>(_onGetProducts);
    on<LoadMoreProductsEvent>(_onLoadMoreProducts);
    on<GetProductByIdEvent>(_onGetProductById);
    on<GetProductGroupsEvent>(_onGetGroups);
  }

  Future<void> _onGetProducts(
    GetProductsEvent event,
    Emitter<ProductState> emit,
  ) async {
    // Preserve groups and show lightweight loading if already loaded
    if (state is ProductsLoaded) {
      final current = state as ProductsLoaded;
      emit(current.copyWith(
        isLoadingMore: true,
        currentPage: 0,
        hasReachedMax: false,
        products: const [],
        selectedGroupId: event.productGroupId,
      ));
    } else {
      emit(ProductLoading());
    }

    final result = await getProducts(
      ProductParams(
        productName: event.searchQuery,
        productGroupId: event.productGroupId,
        pageSize: 50,
        pageIndex: 0,
      ),
    );

    result.fold(
      (failure) => emit(ProductError(message: failure.message)),
      (products) {
        final current = state;
        final groups =
            current is ProductsLoaded ? current.groups : <ProductGroup>[];
        emit(ProductsLoaded(
          products: products,
          hasReachedMax: products.length < 50,
          currentPage: 0,
          groups: groups,
          selectedGroupId: event.productGroupId,
        ));
      },
    );
  }

  Future<void> _onLoadMoreProducts(
    LoadMoreProductsEvent event,
    Emitter<ProductState> emit,
  ) async {
    if (state is ProductsLoaded) {
      final currentState = state as ProductsLoaded;

      if (currentState.hasReachedMax || currentState.isLoadingMore) {
        return;
      }

      emit(currentState.copyWith(isLoadingMore: true));

      final nextPage = currentState.currentPage + 1;

      final result = await getProducts(
        ProductParams(
          productName: event.searchQuery,
          productGroupId: event.productGroupId ?? currentState.selectedGroupId,
          pageSize: 50,
          pageIndex: nextPage,
        ),
      );

      result.fold(
        (failure) => emit(currentState.copyWith(isLoadingMore: false)),
        (newProducts) {
          final allProducts = List<Product>.from(currentState.products)
            ..addAll(newProducts);

          emit(ProductsLoaded(
            products: allProducts,
            hasReachedMax: newProducts.length < 50,
            currentPage: nextPage,
            isLoadingMore: false,
            groups: currentState.groups,
            selectedGroupId: currentState.selectedGroupId,
          ));
        },
      );
    }
  }

  Future<void> _onGetProductById(
    GetProductByIdEvent event,
    Emitter<ProductState> emit,
  ) async {
    emit(ProductLoading());

    final result = await getProductById(GetProductByIdParams(id: event.id));

    result.fold(
      (failure) => emit(ProductError(message: failure.message)),
      (product) => emit(ProductDetailLoaded(product: product)),
    );
  }

  Future<void> _onGetGroups(
    GetProductGroupsEvent event,
    Emitter<ProductState> emit,
  ) async {
    final groupsResult = await getProductGroups(NoParams());

    final current = state;
    final groups = groupsResult.fold<List<ProductGroup>>((_) => [], (g) => g);

    if (current is ProductsLoaded) {
      emit(current.copyWith(groups: groups));
    } else {
      emit(ProductsLoaded(products: const [], groups: groups));
    }
  }
}
