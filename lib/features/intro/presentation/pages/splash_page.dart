import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../injection_container.dart' as di;
import '../../../auth/data/auth_service.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../customers/presentation/bloc/customer_cubit.dart';
import '../../../users/presentation/bloc/user_bloc.dart';
import '../../../main/presentation/pages/main_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2), // Total splash duration
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.5)),
    );

    _controller.forward();

    _navigateNext();
  }

  Future<void> _navigateNext() async {
    // Wait for animation + artificial delay
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final authService = di.sl<AuthService>();
    final isLoggedIn = authService.isLoggedIn();

    if (isLoggedIn) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => MultiBlocProvider(
            providers: [
              BlocProvider<UserBloc>(
                create: (context) => di.sl<UserBloc>(),
              ),
              BlocProvider<CustomerCubit>(
                create: (context) => di.sl<CustomerCubit>()..loadCustomers(),
              ),
            ],
            child: const CustomersPage(),
          ),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => LoginPage(authService: authService)),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B3B68), // Dark Navy
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _opacityAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: child,
              ),
            );
          },
          child: SizedBox(
            width: 500, // Explicit big size
            height: 200,
            child: Image.asset(
              'assets/unnamed-removebg-preview.png', // Use the original full quality one or optimized one
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
