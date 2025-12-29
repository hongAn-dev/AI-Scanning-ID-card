import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../utils/screen_utils.dart';
import '../../../cart/presentation/bloc/cart_bloc.dart';
import '../../../cart/presentation/pages/cart_page.dart';
import '../../domain/entities/product.dart';
import '../bloc/product_bloc.dart';
import '../widgets/product_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // load product groups initially
    context.read<ProductBloc>().add(GetProductGroupsEvent());
    // also load initial products
    context.read<ProductBloc>().add(const GetProductsEvent());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      final state = context.read<ProductBloc>().state;
      final selectedGroupId =
          state is ProductsLoaded ? state.selectedGroupId : null;
      context.read<ProductBloc>().add(
            LoadMoreProductsEvent(
              searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
              productGroupId: selectedGroupId,
            ),
          );
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  List<Product> _filterProducts(List<Product> products) {
    if (_searchQuery.isEmpty) {
      return products;
    }

    return products.where((product) {
      final nameLower = product.name.toLowerCase();
      final codeLower = product.productCode.toLowerCase();
      final branchLower = product.branchName.toLowerCase();
      final searchLower = _searchQuery.toLowerCase();

      return nameLower.contains(searchLower) ||
          codeLower.contains(searchLower) ||
          branchLower.contains(searchLower);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        drawer: _buildDrawer(),
        appBar: AppBar(
          title: const Text(
            'Danh sách sản phẩm',
            style: TextStyle(
              color: Colors.black,
            ),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.white,
          actions: [
            // Cart Icon with Badge
            BlocBuilder<CartBloc, CartState>(
              builder: (context, state) {
                return Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.shopping_cart),
                      color: Colors.red,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BlocProvider.value(
                              value: context.read<CartBloc>(),
                              child: const CartPage(),
                            ),
                          ),
                        );
                      },
                    ),
                    if (state.itemCount > 0)
                      Positioned(
                        right: 5,
                        top: 3,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            '${state.itemCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
        body: BlocListener<ProductBloc, ProductState>(
          listener: (context, state) {
            if (state is ProductError) {
              _showErrorDialog(context, state.message);
            }
          },
          child: BlocBuilder<ProductBloc, ProductState>(
            builder: (context, state) {
              if (state is ProductLoading) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              } else if (state is ProductsLoaded) {
                final filteredProducts = _filterProducts(state.products);

                return Column(
                  children: [
                    // Search Bar
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Tìm kiếm sản phẩm...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  color: Colors.black,
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchQuery = '';
                                    });
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: Colors.black, width: 1),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: Colors.black, width: 1),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: Colors.black, width: 2),
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                          // Trigger new search when search query changes
                          context.read<ProductBloc>().add(
                                GetProductsEvent(
                                    searchQuery: value.isEmpty ? null : value),
                              );
                        },
                      ),
                    ),

                    // Results count
                    if (_searchQuery.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Tìm thấy ${filteredProducts.length} sản phẩm${filteredProducts.length != 1 ? 's' : ''}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),

                    // Products Grid
                    Expanded(
                      child: filteredProducts.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.search_off,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Không tìm thấy sản phẩm',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Thử tìm kiếm với từ khác',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: () async {
                                context.read<ProductBloc>().add(
                                      GetProductsEvent(
                                        searchQuery: _searchQuery.isEmpty
                                            ? null
                                            : _searchQuery,
                                      ),
                                    );
                              },
                              child: GridView.builder(
                                controller: _scrollController,
                                padding:
                                    ScreenUtils.getResponsivePadding(context),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount:
                                      ScreenUtils.getResponsiveColumns(context),
                                  childAspectRatio: ScreenUtils.responsiveValue(
                                    context,
                                    mobile: 0.65,
                                    tablet: 0.7,
                                    desktop: 0.75,
                                  ),
                                  crossAxisSpacing:
                                      ScreenUtils.getResponsiveSpacing(
                                          context, 12),
                                  mainAxisSpacing:
                                      ScreenUtils.getResponsiveSpacing(
                                          context, 12),
                                ),
                                itemCount: filteredProducts.length +
                                    (state.isLoadingMore ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (index >= filteredProducts.length) {
                                    return const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(16.0),
                                        child: CircularProgressIndicator(),
                                      ),
                                    );
                                  }
                                  final product = filteredProducts[index];
                                  return ProductCard(product: product);
                                },
                              ),
                            ),
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
        // floatingActionButton: FloatingActionButton(
        //   onPressed: () {
        //     context.read<ProductBloc>().add(
        //           GetProductsEvent(
        //             searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
        //           ),
        //         );
        //   },
        //   child: const Icon(Icons.refresh),
        // ),
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.red[300],
                size: 28,
              ),
              const SizedBox(width: 12),
              const Text(
                'Lỗi',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          actions: [
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                context.read<ProductBloc>().add(
                      GetProductsEvent(
                        searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
                      ),
                    );
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: SafeArea(
        child: BlocBuilder<ProductBloc, ProductState>(
          builder: (context, state) {
            final groups = state is ProductsLoaded ? state.groups : const [];

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Nhóm sản phẩm',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                // ListTile(
                //   leading: const Icon(Icons.all_inbox),
                //   title: const Text('Tất cả'),
                //   selected: state is ProductsLoaded &&
                //       (state.selectedGroupId == null ||
                //           state.selectedGroupId!.isEmpty),
                //   onTap: () {
                //     Navigator.pop(context);
                //     context.read<ProductBloc>().add(GetProductsEvent(
                //           searchQuery:
                //               _searchQuery.isEmpty ? null : _searchQuery,
                //           productGroupId: null,
                //         ));
                //     context.read<ProductBloc>().add(GetProductGroupsEvent());
                //   },
                // ),
                // const Divider(height: 0),
                Expanded(
                  child: groups.isEmpty
                      ? ListView(
                          children: const [
                            Padding(
                              padding: EdgeInsets.all(24.0),
                              child: Text('Không có nhóm sản phẩm',
                                  textAlign: TextAlign.center),
                            )
                          ],
                        )
                      : ListView.separated(
                          itemCount: groups.length,
                          separatorBuilder: (_, __) => Divider(
                            height: 0,
                            color: Colors.grey.withOpacity(.4),
                          ),
                          itemBuilder: (context, index) {
                            final g = groups[index];
                            final selected = state is ProductsLoaded &&
                                state.selectedGroupId == g.id;
                            return ListTile(
                              leading: _buildGroupAvatar(g.picture),
                              title: Text(g.name.isEmpty ? '' : g.name),
                              selected: selected,
                              onTap: () {
                                Navigator.pop(context);
                                context
                                    .read<ProductBloc>()
                                    .add(GetProductsEvent(
                                      searchQuery: _searchQuery.isEmpty
                                          ? null
                                          : _searchQuery,
                                      productGroupId: g.id,
                                    ));
                              },
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildGroupAvatar(String? url) {
    if (url == null || url.isEmpty) {
      return const CircleAvatar(
        backgroundImage: AssetImage('assets/placeholder.png'),
      );
    }
    return CircleAvatar(
      backgroundColor: Colors.transparent,
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: url,
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          placeholder: (context, _) => const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          errorWidget: (context, _, __) => Image.asset(
            'assets/placeholder.png',
            width: 40,
            height: 40,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
