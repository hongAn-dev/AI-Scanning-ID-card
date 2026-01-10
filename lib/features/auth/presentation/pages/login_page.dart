import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../injection_container.dart' as di;
import '../../../customers/domain/repositories/customer_repository.dart'
    as repos;
import '../../../main/presentation/pages/main_page.dart';
import '../../../users/presentation/bloc/user_bloc.dart';
import '../../data/auth_service.dart';

class LoginPage extends StatefulWidget {
  final AuthService authService;

  const LoginPage({super.key, required this.authService});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _customerCodeController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  final _codeFocus = FocusNode();
  final _userFocus = FocusNode();
  final _passFocus = FocusNode();

  bool _rememberMe = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isKeyboardVisible = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
    _codeFocus.addListener(_updateKeyboardStatus);
    _userFocus.addListener(_updateKeyboardStatus);
    _passFocus.addListener(_updateKeyboardStatus);
  }

  void _updateKeyboardStatus() {
    final isFocused =
        _codeFocus.hasFocus || _userFocus.hasFocus || _passFocus.hasFocus;
    if (_isKeyboardVisible != isFocused) {
      if (mounted) setState(() => _isKeyboardVisible = isFocused);
    }
  }

  void _loadSavedCredentials() {
    if (widget.authService.isRememberMe()) {
      setState(() {
        _customerCodeController.text =
            widget.authService.getSavedCustomerCode() ?? '';
        _usernameController.text = widget.authService.getSavedUsername() ?? '';
        _passwordController.text = widget.authService.getSavedPassword() ?? '';
        _rememberMe = true;
      });
    }
  }

  @override
  void dispose() {
    _customerCodeController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();

    _codeFocus.removeListener(_updateKeyboardStatus);
    _userFocus.removeListener(_updateKeyboardStatus);
    _passFocus.removeListener(_updateKeyboardStatus);
    _codeFocus.dispose();
    _userFocus.dispose();
    _passFocus.dispose();

    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final success = await widget.authService.login(
        customerCode: _customerCodeController.text.trim(),
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        rememberMe: _rememberMe,
      );

      if (success && mounted) {
        // Fetch Customer Groups
        try {
          print("LoginPage: Login successful. Fetching customer groups...");
          // Note: using direct DI resolution because passing Repo via constructor requires refactoring upstream
          final customerRepo = di.sl<repos.CustomerRepository>();
          final groups = await customerRepo.getCustomerGroups();
          print("LoginPage: Fetched ${groups.length} groups");

          setState(() => _isLoading = false);

          if (groups.isNotEmpty && mounted) {
            print("LoginPage: Showing group selection dialog");
            final selected = await showDialog<bool>(
              context: context,
              barrierDismissible: true, // Allow dismissal
              builder: (ctx) => AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                titlePadding: EdgeInsets.zero,
                title: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  decoration: const BoxDecoration(
                    color: AppColors.red,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.store_mall_directory,
                          color: Colors.white, size: 24),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Chọn Chi Nhánh / Nhóm",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 17),
                        ),
                      ),
                    ],
                  ),
                ),
                contentPadding: const EdgeInsets.only(top: 12, bottom: 8),
                content: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: SizedBox(
                    width: double.maxFinite,
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: groups.length,
                      separatorBuilder: (_, __) => Divider(
                          color: Colors.grey.withOpacity(0.2), height: 1),
                      itemBuilder: (c, i) => ListTile(
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 0),
                        title: Text(
                          groups[i].name,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios,
                            size: 14, color: AppColors.red),
                        onTap: () async {
                          print(
                            "LoginPage: Selected group ${groups[i].name} (${groups[i].id})",
                          );
                          await widget.authService.saveLocationId(groups[i].id);
                          await widget.authService
                              .saveLocationName(groups[i].name);
                          Navigator.of(ctx).pop(true);
                        },
                      ),
                    ),
                  ),
                ),
              ),
            );

            if (selected != true) {
              // User dismissed dialog -> Cancel login
              print("LoginPage: Dialog dismissed. Logout.");
              await widget.authService.logout();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã hủy đăng nhập')),
                );
              }
              return; // Stop flow
            }
          } else {
            print("LoginPage: No groups to show or widget unmounted");
          }
        } catch (e) {
          print("LoginPage: Error fetching groups: $e");
          setState(() => _isLoading = false);
        }

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => MultiBlocProvider(
                providers: [
                  BlocProvider<UserBloc>(
                    create: (context) => di.sl<UserBloc>(),
                  ),
                ],
                child: const CustomersPage(),
              ),
            ),
          );
        }
      } else {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đăng nhập thất bại. Vui lòng thử lại.'),
              backgroundColor: AppColors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Dark Navy Blue Background
    const backgroundColor = Color(0xFF1B3B68);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // --- Top Content (Scrollable) ---
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // --- Logo (Animated) ---
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOutQuad,
                          width: _isKeyboardVisible ? 150 : 500,
                          height: _isKeyboardVisible ? 60 : 200,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                                _isKeyboardVisible ? 12 : 24),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(
                                _isKeyboardVisible ? 12 : 24),
                            child: Image.asset(
                              'assets/unnamed-removebg-preview.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // --- Form ---
                        Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildModernTextField(
                                controller: _customerCodeController,
                                focusNode: _codeFocus,
                                hint: 'Mã khách hàng',
                                icon: Icons.store_mall_directory_outlined,
                              ),
                              const SizedBox(height: 16),
                              _buildModernTextField(
                                controller: _usernameController,
                                focusNode: _userFocus,
                                hint: 'Tên đăng nhập',
                                icon: Icons.person_outline,
                              ),
                              const SizedBox(height: 16),
                              _buildModernTextField(
                                controller: _passwordController,
                                focusNode: _passFocus,
                                hint: 'Mật khẩu',
                                icon: Icons.vpn_key_outlined,
                                isPassword: true,
                              ),
                              const SizedBox(height: 16),
                              // --- Remember Me ---
                              Row(
                                children: [
                                  SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: Checkbox(
                                      value: _rememberMe,
                                      activeColor: AppColors.red,
                                      side: const BorderSide(
                                          color: Colors.white, width: 2),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      onChanged: (v) => setState(
                                        () => _rememberMe = v ?? false,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Ghi nhớ đăng nhập',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // --- Bottom Content (Fixed) ---
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Column(
                  children: [
                    // --- Button ---
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.red,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Đăng nhập',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),

                    // Hide Footer when keyboard is visible
                    if (!_isKeyboardVisible) ...[
                      const SizedBox(height: 24),
                      // --- Footer ---
                      Column(
                        children: [
                          const Text(
                            '1900 29 29 51',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Copyright @MasterPro',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      // Add extra padding at very bottom if needed
                      SizedBox(height: MediaQuery.of(context).padding.bottom),
                    ] else
                      // Add small padding when keyboard is up
                      const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Removed _buildLabel as it's not needed in this design

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    FocusNode? focusNode, // [ADDED]
    bool isPassword = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, // White background
        borderRadius:
            BorderRadius.circular(8), // Less rounded, more like the image
      ),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode, // [ADDED]
        obscureText: isPassword && _obscurePassword,
        style: const TextStyle(fontSize: 16, color: Colors.black87),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 15),
          prefixIcon: Icon(icon, color: Colors.grey.shade600, size: 22),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: Colors.grey.shade600,
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 16,
          ),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Vui lòng nhập thông tin';
          }
          return null;
        },
      ),
    );
  }
}
