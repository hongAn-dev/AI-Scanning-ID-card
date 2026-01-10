import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:masterpro_ai_scan_id/core/theme/app_theme.dart';
import 'package:masterpro_ai_scan_id/utils/screen_utils.dart';
import 'package:responsive_framework/responsive_framework.dart';

import 'features/auth/data/auth_service.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/customers/presentation/bloc/customer_cubit.dart';
import 'features/main/presentation/pages/main_page.dart';
import 'features/users/presentation/bloc/user_bloc.dart';
import 'injection_container.dart' as di;

import 'features/intro/presentation/pages/splash_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();
  runApp(const MyApp());
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Auth check moved to SplashPage
    return MultiBlocProvider(
      providers: [
        // User Bloc
        BlocProvider<UserBloc>(
          create: (context) => di.sl<UserBloc>(),
        ),
        // Customer Cubit
        BlocProvider<CustomerCubit>(
          create: (context) => di.sl<CustomerCubit>()..loadCustomers(),
        ),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'MasterPro AI Scan ID',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.getTheme(),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('vi', 'VN'),
        ],
        home: const SplashPage(), // Start with Custom Splash
        builder: (context, child) {
          ScreenUtils.init(context);
          return ResponsiveBreakpoints.builder(
            child: ClampingScrollWrapper.builder(context, child!),
            breakpoints: [
              const Breakpoint(start: 0, end: 450, name: MOBILE),
              const Breakpoint(start: 451, end: 800, name: TABLET),
              const Breakpoint(start: 801, end: 1920, name: DESKTOP),
              const Breakpoint(start: 1921, end: double.infinity, name: '4K'),
            ],
          );
        },
      ),
    );
  }
}
