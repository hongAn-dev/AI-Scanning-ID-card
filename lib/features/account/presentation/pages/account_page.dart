import 'package:flutter/material.dart';

import '../../../../injection_container.dart' as di;
import '../../../auth/data/auth_service.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../auth/presentation/widgets/change_password_bottom_sheet.dart';
import '../../../orders/presentation/pages/order_history_page.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  void _logout(BuildContext context) async {
    final authService = di.sl<AuthService>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Reset CartBloc before logout
              await di.resetCartBloc();

              // Perform logout
              await authService.logout();

              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LoginPage(authService: authService),
                  ),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }

  Future<void> _changePassword(BuildContext context) async {
    final authService = di.sl<AuthService>();

    // Show bottom sheet
    final newPassword = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: const ChangePasswordBottomSheet(),
      ),
    );

    if (newPassword != null && context.mounted) {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Đang đổi mật khẩu...'),
                ],
              ),
            ),
          ),
        ),
      );

      // Call change password
      final result = await authService.changePassword(newPassword: newPassword);

      // Close loading dialog
      if (context.mounted) {
        Navigator.pop(context);
      }

      // Show result
      if (context.mounted) {
        final isSuccess = result['success'] == true;
        final message = result['message'] ?? 'Không xác định';

        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Row(
              children: [
                Icon(
                  isSuccess ? Icons.check_circle : Icons.error,
                  color: isSuccess ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(isSuccess ? 'Thành công' : 'Thất bại'),
              ],
            ),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Đóng'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = di.sl<AuthService>();
    final userAccount = authService.getUserAccount();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tài khoản'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: userAccount == null
          ? const Center(child: Text('Không có thông tin người dùng'))
          : SingleChildScrollView(
              child: Column(
                children: [
                  // User Info Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(24),
                        bottomRight: Radius.circular(24),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Avatar
                        CircleAvatar(
                          backgroundColor: Colors.white,
                          radius: 50,
                          backgroundImage: userAccount.avatar.isNotEmpty
                              ? NetworkImage(userAccount.avatar)
                              : null,
                          child: userAccount.avatar.isEmpty
                              ? const Icon(Icons.person, size: 50)
                              : null,
                        ),
                        const SizedBox(height: 16),
                        // Display Name
                        Text(
                          userAccount.displayName,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        // const SizedBox(height: 4),
                        // // Username
                        // Text(
                        //   '@${userAccount.userName}',
                        //   style: TextStyle(
                        //     fontSize: 14,
                        //     color: Colors.grey[600],
                        //   ),
                        // ),
                        // if (userAccount.isSystemAccount)
                        //   const Padding(
                        //     padding: EdgeInsets.only(top: 8),
                        //     child: Chip(
                        //       label: Text(
                        //         'System Account',
                        //         style: TextStyle(fontSize: 12),
                        //       ),
                        //       backgroundColor: Colors.red,
                        //       labelStyle: TextStyle(color: Colors.white),
                        //     ),
                        //   ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Account Information
                  _buildInfoSection(
                    'Thông tin liên hệ',
                    [
                      if (userAccount.email.isNotEmpty) ...[
                        _buildInfoTile(
                          Icons.email,
                          'Email',
                          userAccount.email,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Divider(
                            color: Colors.grey.withOpacity(.4),
                          ),
                        ),
                      ],
                      if (userAccount.companyTel1.isNotEmpty) ...[
                        _buildInfoTile(
                          Icons.phone,
                          'Điện thoại 1',
                          userAccount.companyTel1,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Divider(
                            color: Colors.grey.withOpacity(.4),
                          ),
                        ),
                      ],
                      if (userAccount.companyTel2.isNotEmpty)
                        _buildInfoTile(
                          Icons.phone,
                          'Điện thoại 2',
                          userAccount.companyTel2,
                        ),
                    ],
                  ),

                  // const SizedBox(height: 16),

                  // // Employee Info
                  // if (userAccount.employeeId.isNotEmpty)
                  //   _buildInfoSection(
                  //     'Thông tin nhân viên',
                  //     [
                  //       _buildInfoTile(
                  //         Icons.badge,
                  //         'Employee ID',
                  //         userAccount.employeeId,
                  //       ),
                  //     ],
                  //   ),

                  const SizedBox(height: 24),

                  // Action Buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        _buildActionButton(
                          context,
                          Icons.history,
                          'Danh sách đơn hàng',
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const OrderHistoryPage(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildActionButton(
                          context,
                          Icons.lock,
                          'Đổi mật khẩu',
                          () => _changePassword(context),
                        ),
                        const SizedBox(height: 12),
                        _buildActionButton(
                          context,
                          Icons.logout,
                          'Đăng xuất',
                          () => _logout(context),
                          isDestructive: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          color: Colors.white,
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.withOpacity(.4), width: 1),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      subtitle: Text(value),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isDestructive ? Colors.red : Colors.grey.shade700,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDestructive ? Colors.red : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isDestructive ? Colors.red : null,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: isDestructive ? Colors.red : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}
