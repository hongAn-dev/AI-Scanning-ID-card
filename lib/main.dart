import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:masterpro_ghidon/core/theme/app_theme.dart';
import 'package:masterpro_ghidon/utils/screen_utils.dart';
import 'package:responsive_framework/responsive_framework.dart';

import 'features/auth/data/auth_service.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/cart/presentation/bloc/cart_bloc.dart';
import 'features/main/presentation/pages/main_page.dart';
import 'features/products/presentation/bloc/product_bloc.dart';
import 'features/users/presentation/bloc/user_bloc.dart';
import 'injection_container.dart' as di;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = di.sl<AuthService>();
    final isLoggedIn = authService.isLoggedIn();

    return MaterialApp(
      title: 'Masterpro Ghi Đơn',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.getTheme(),
      home: isLoggedIn
          ? MultiBlocProvider(
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
            )
          : LoginPage(authService: authService),
      builder: (context, child) {
        ScreenUtils.init(context);
        return ResponsiveBreakpoints.builder(
          breakpoints: [
            const Breakpoint(start: 0, end: 450, name: MOBILE),
            const Breakpoint(start: 451, end: 800, name: TABLET),
            const Breakpoint(start: 801, end: 1920, name: DESKTOP),
            const Breakpoint(start: 1921, end: double.infinity, name: '4K'),
          ],
          child: child!,
        );
      },
    );
  }
}
