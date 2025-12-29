import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../../../injection_container.dart' as di;
import '../../../cart/presentation/bloc/cart_bloc.dart';
import '../../../main/presentation/pages/main_page.dart';
import '../../../products/presentation/bloc/product_bloc.dart';
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

  bool _rememberMe = false;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
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

      setState(() => _isLoading = false);

      if (success && mounted) {
        // Navigate to home page with BlocProviders
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => MultiBlocProvider(
              providers: [
                // Cart Bloc - Singleton to maintain state across app
                BlocProvider<CartBloc>(
                  create: (context) => di.sl<CartBloc>(),
                ),
                // Product Bloc
                BlocProvider<ProductBloc>(
                  create: (context) =>
                      di.sl<ProductBloc>()..add(const GetProductsEvent()),
                ),
                // User Bloc
                BlocProvider<UserBloc>(
                  create: (context) => di.sl<UserBloc>(),
                ),
              ],
              child: const MainPage(),
            ),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đăng nhập thất bại. Vui lòng thử lại.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo or App Name
                  // App Logo
                  Image.asset(
                    'assets/logo.png',
                    width: ResponsiveBreakpoints.of(context).isTablet ||
                            ResponsiveBreakpoints.of(context).isDesktop
                        ? 120
                        : 100,
                    height: ResponsiveBreakpoints.of(context).isTablet ||
                            ResponsiveBreakpoints.of(context).isDesktop
                        ? 120
                        : 100,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Masterpro Ghi Đơn',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: ResponsiveBreakpoints.of(context).isTablet ||
                              ResponsiveBreakpoints.of(context).isDesktop
                          ? 36
                          : 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Customer Code Field
                  TextFormField(
                    controller: _customerCodeController,
                    decoration: InputDecoration(
                      labelText: 'Mã khách hàng',
                      hintText: 'Nhập mã khách hàng',
                      labelStyle: const TextStyle(color: Colors.black),
                      prefixIcon: const Icon(Icons.badge),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.black),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập mã khách hàng';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Username Field
                  TextFormField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: 'Tên đăng nhập',
                      hintText: 'Nhập tên đăng nhập',
                      labelStyle: const TextStyle(color: Colors.black),
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.black),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập tên đăng nhập';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password Field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu',
                      hintText: 'Nhập mật khẩu',
                      labelStyle: const TextStyle(color: Colors.black),
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.black),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập mật khẩu';
                      }
                      // if (value.length < 6) {
                      //   return 'Mật khẩu phải có ít nhất 6 ký tự';
                      // }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Remember Me Checkbox
                  Row(
                    children: [
                      Checkbox(
                        activeColor: Colors.red,
                        checkColor: Colors.white,
                        value: _rememberMe,
                        onChanged: (value) {
                          setState(() {
                            _rememberMe = value ?? false;
                          });
                        },
                      ),
                      const Text('Nhớ tài khoản'),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Login Button
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.blue),
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
                  const SizedBox(height: 24),

                  const Column(
                    children: [
                      Text(
                        '1900 29 29 51',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black,
                        ),
                      ),
                      //CopyRight
                      Text(
                        'Copyright © 2025 Masterpro',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
