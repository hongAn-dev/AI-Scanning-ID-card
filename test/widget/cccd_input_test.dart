import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:masterpro_ai_scan_id/features/customers/domain/repositories/customer_repository.dart';
import 'package:masterpro_ai_scan_id/features/customers/presentation/bloc/customer_cubit.dart';
import 'package:masterpro_ai_scan_id/features/scan/presentation/widgets/cccd_input_form.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fakes.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    final getIt = GetIt.instance;
    if (!getIt.isRegistered<CustomerRepository>()) {
      getIt.registerSingleton<CustomerRepository>(FakeCustomerRepository());
    }
  });

  Future<void> pumpForm(WidgetTester tester, Map<String, dynamic> data) async {
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
            create: (_) => CustomerCubit(repository: FakeCustomerRepository()),
            child: CccdInputForm(
              frontImagePath: 'dummy_front.jpg',
              backImagePath: 'dummy_back.jpg',
              scannedData: data,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('CccdInputForm Logic Tests', () {
    testWidgets('Parsing Issue Date from varied keys', (tester) async {
      await pumpForm(tester, {
        'issueDate': '12/12/2021',
        'id': '123456789012',
        'name': 'TEST CCCD'
      });
      expect(find.text('12/12/2021'), findsOneWidget);

      await pumpForm(tester, {
        'issuedate': '05/05/2025',
        'id': '123456789012',
      });
      expect(find.text('05/05/2025'), findsOneWidget);
    });

    testWidgets('Delete Button - Hidden for New Customer', (tester) async {
      await pumpForm(tester, {
        'id': '123456789012', // New scan, no customerId
      });
      // Should NOT find "Xóa khách hàng"
      expect(find.text('Xóa khách hàng'), findsNothing);
    });

    testWidgets('Delete Button - Visible for Existing Customer',
        (tester) async {
      await pumpForm(tester, {
        'id': '123456789012',
        'customerId': 'existing_123', // Existing customer
      });

      // Scroll down to make sure button is built/visible
      await tester.drag(
          find.byType(SingleChildScrollView), const Offset(0, -600));
      await tester.pumpAndSettle();

      // Should FIND "Xóa khách hàng"
      expect(find.text('Xóa khách hàng'), findsOneWidget);
    });
  });
}
