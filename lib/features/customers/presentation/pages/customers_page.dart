import 'package:flutter/material.dart';

class CustomersPage extends StatelessWidget {
  const CustomersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Khách hàng'),
      ),
      body:
          const Center(child: Text('Danh sách khách hàng sẽ hiển thị ở đây.')),
    );
  }
}
