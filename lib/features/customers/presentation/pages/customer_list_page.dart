import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/datasources/customer_local_data_source.dart';
import '../../data/models/customer_model.dart';
import '../../domain/entities/customer.dart';
import '../bloc/customer_bloc.dart';
import 'add_customer_page.dart';

class CustomerListPage extends StatefulWidget {
  final CustomerLocalDataSource dataSource;
  final Function(Customer) onCustomerSelected;

  const CustomerListPage({
    super.key,
    required this.dataSource,
    required this.onCustomerSelected,
  });

  @override
  State<CustomerListPage> createState() => _CustomerListPageState();
}

class _CustomerListPageState extends State<CustomerListPage> {
  String? _selectedGroupId; // Now using UUID string
  String _searchText = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadGroups();
    _loadCustomers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadGroups() async {
    context.read<CustomerBloc>().add(
          const FetchCustomerGroupsEvent(),
        );
  }

  void _loadCustomers() {
    context.read<CustomerBloc>().add(
          FetchCustomersEvent(
            searchText: _searchText,
            groupId: _selectedGroupId, // Pass UUID directly
          ),
        );
  }

  void _filterByGroup(String? groupId) {
    setState(() {
      _selectedGroupId = groupId;
    });
    _loadCustomers();
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchText = value;
    });
    // Debounce search
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_searchText == value) {
        _loadCustomers();
      }
    });
  }

  void _showGroupFilterBottomSheet() {
    final customerBloc = context.read<CustomerBloc>();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => BlocProvider.value(
        value: customerBloc,
        child: BlocBuilder<CustomerBloc, CustomerState>(
          builder: (context, state) {
            // Show loading only if groups are being loaded and no groups available yet
            if (state.isLoadingGroups && state.groups.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(48.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            // Always show UI with available data
            return SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Chọn nhóm khách hàng',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 8),
                    // All customers option
                    ListTile(
                      leading: Icon(
                        Icons.people,
                        color: _selectedGroupId == null ? Colors.red : Colors.grey,
                      ),
                      title: const Text(
                        'Tất cả khách hàng',
                        style: TextStyle(color: Colors.black),
                      ),
                      trailing: _selectedGroupId == null
                          ? const Icon(
                              Icons.check_circle,
                              color: Colors.red,
                            )
                          : null,
                      selected: _selectedGroupId == null,
                      onTap: () {
                        _filterByGroup(null);
                        Navigator.pop(ctx);
                      },
                    ),
                    const Divider(),

                    // Show empty message if no groups
                    if (state.groups.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(
                          child: Text('Không có nhóm khách hàng'),
                        ),
                      )
                    // Show groups
                    else
                      ...state.groups.map((group) => ListTile(
                            leading: Icon(
                              Icons.group,
                              color: _selectedGroupId == group.uuid ? Colors.red : Colors.grey,
                            ),
                            title: Text(group.name),
                            subtitle: group.description != null
                                ? Text(
                                    group.description!,
                                    style: const TextStyle(fontSize: 12),
                                  )
                                : null,
                            trailing: _selectedGroupId == group.uuid
                                ? const Icon(
                                    Icons.check_circle,
                                    color: Colors.red,
                                  )
                                : null,
                            selected: _selectedGroupId == group.uuid,
                            onTap: () {
                              _filterByGroup(group.uuid);
                              Navigator.pop(ctx);
                            },
                          )),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _addCustomer() async {
    // Get groups from current state
    final currentState = context.read<CustomerBloc>().state;
    List<CustomerGroupModel> groups = [];

    if (currentState.groups.isNotEmpty) {
      groups = currentState.groups.cast<CustomerGroupModel>();
    } else {
      // Fallback to local data source
      groups = widget.dataSource.getCustomerGroups();
    }

    final customerBloc = context.read<CustomerBloc>();

    final result = await Navigator.push<Customer>(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: customerBloc,
          child: AddCustomerPage(
            groups: groups,
          ),
        ),
      ),
    );

    if (result != null) {
      _loadCustomers();
    }
  }

  void _selectCustomer(Customer customer) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận'),
        content: Text('Chọn khách hàng: ${customer.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx); // Close dialog
              Navigator.pop(context, customer); // Return customer to previous screen
              widget.onCustomerSelected(customer);
            },
            child: const Text('Chọn', style: TextStyle(color: Colors.white),),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chọn khách hàng'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Lọc theo nhóm',
            onPressed: _showGroupFilterBottomSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm khách hàng...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchText.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.black.withOpacity(.5), width: 1),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.black.withOpacity(.5), width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.black.withOpacity(.5), width: 2),
                ),
              ),
              onChanged: _onSearchChanged,
            ),
          ),

          // Filter indicator
          if (_selectedGroupId != null)
            BlocBuilder<CustomerBloc, CustomerState>(
              builder: (context, state) {
                String groupName = 'Đang tải...';

                // Always check groups from state
                if (state.groups.isNotEmpty) {
                  final groups = state.groups.cast<CustomerGroupModel>();
                  final selectedGroup = groups.firstWhere(
                    (g) => g.uuid == _selectedGroupId,
                    orElse: () => const CustomerGroupModel(
                      id: 0,
                      name: 'Không xác định',
                    ),
                  );
                  groupName = selectedGroup.name;
                }

                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: Colors.red.withOpacity(0.1),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.filter_alt,
                        size: 16,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Lọc: $groupName',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.red,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => _filterByGroup(null),
                        child: const Text(
                          'Xóa bộ lọc',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

          // Customer List
          Expanded(
            child: BlocBuilder<CustomerBloc, CustomerState>(
              builder: (context, state) {
                // Show loading only if customers are being loaded and no customers available yet
                if (state.isLoadingCustomers && state.customers.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                // Show error if there's an error and no customers to display
                if (state.errorMessage != null && state.customers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Lỗi: ${state.errorMessage}',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadCustomers,
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  );
                }

                // Always show customers from state
                final customers = state.customers;

                if (customers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchText.isNotEmpty ? 'Không tìm thấy khách hàng' : 'Chưa có khách hàng',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: customers.length,
                  itemBuilder: (context, index) {
                    final customer = customers[index];
                    return Card(
                      elevation: 3,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: GestureDetector(
                        onTap: () => _selectCustomer(customer),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            customer.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addCustomer,
        icon: const Icon(Icons.person_add),
        label: const Text('Thêm khách hàng'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
    );
  }
}
