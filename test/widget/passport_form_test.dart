import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:masterpro_ai_scan_id/features/auth/data/auth_service.dart';
import 'package:masterpro_ai_scan_id/features/customers/domain/repositories/customer_repository.dart';
import 'package:masterpro_ai_scan_id/features/customers/presentation/bloc/customer_cubit.dart';
import 'package:masterpro_ai_scan_id/features/scan/presentation/widgets/cccd_input_form.dart';

import '../helpers/fakes.dart';

final sl = GetIt.instance;

void main() {
  setUp(() {
    sl.reset();
    sl.registerLazySingleton<CustomerRepository>(
        () => FakeCustomerRepository());
    sl.registerLazySingleton<AuthService>(() => FakeAuthService());
    SharedPreferences.setMockInitialValues({});
  });

  // Helper to pump widget
  Future<void> pumpForm(
      WidgetTester tester, Map<String, dynamic> scannedData) async {
    final repo = FakeCustomerRepository();
    final cubit = CustomerCubit(repository: repo);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('vi', 'VN')],
        home: Scaffold(
          body: BlocProvider<CustomerCubit>(
            create: (_) => cubit,
            child: CccdInputForm(
              frontImagePath: 'path/to/front.jpg', // Dummy path
              backImagePath: 'path/to/back.jpg', // Dummy path
              scannedData: scannedData,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle(); // Wait for futures (loadLocations)
  }

  group('CccdInputForm UI Labels', () {
    testWidgets('Should display Passport labels when type is PASSPORT',
        (tester) async {
      final data = {
        'type': 'PASSPORT',
        'name': 'NGUYEN VAN A',
        'id': 'P1234567',
        'hometown': 'Ha Noi',
        'residence': 'HCM',
        'dob': '01/01/1990',
        'issueDate': '01/01/2020',
        'expiry': '01/01/2030',
        'sex': 'Nam'
      };

      await pumpForm(tester, data);

      // Verify Labels
      expect(find.text('Số Hộ chiếu'), findsOneWidget);
      expect(find.text('Số CCCD'), findsNothing);

      expect(find.text('Nơi sinh'), findsOneWidget);
      expect(find.text('Quê quán'), findsNothing);

      expect(find.text('Địa chỉ / Nơi cấp'), findsOneWidget);
      expect(find.text('Nơi thường trú'), findsNothing);
    });

    testWidgets('Should display CCCD labels when type is CCCD', (tester) async {
      final data = {
        'type': 'CCCD', // or default
        'name': 'LE THI B',
        'id': '012345678912',
        'hometown': 'Da Nang',
        'residence': 'Da Nang',
        'dob': '02/02/1992',
        'issueDate': '02/02/2021',
        'expiry': '02/02/2031',
        'sex': 'Nữ'
      };

      await pumpForm(tester, data);

      // Verify Labels
      expect(find.text('Số CCCD'), findsOneWidget);
      expect(find.text('Số Hộ chiếu'), findsNothing);

      expect(find.text('Quê quán'), findsOneWidget);
      expect(find.text('Nơi sinh'), findsNothing);

      expect(find.text('Nơi thường trú'), findsOneWidget);
      expect(find.text('Địa chỉ / Nơi cấp'), findsNothing);
    });
  });
}
