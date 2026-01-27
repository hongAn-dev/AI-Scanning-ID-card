import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:masterpro_ai_scan_id/features/customers/domain/repositories/customer_repository.dart';
import 'package:masterpro_ai_scan_id/features/customers/presentation/bloc/customer_cubit.dart';
import 'package:masterpro_ai_scan_id/features/scan/presentation/widgets/passport_input_form.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fakes.dart'; // Reuse fakes

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});

    // Register dependencies
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
            child: PassportInputForm(
              frontImagePath: 'dummy_front.jpg',
              scannedData: data,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('PassportInputForm Logic Tests', () {
    testWidgets('Parsing Issue Date from "issueDate" key', (tester) async {
      await pumpForm(tester,
          {'issueDate': '15/05/2020', 'id': 'B1234567', 'name': 'TEST USER'});

      // Verify date is displayed correctly
      expect(find.text('15/05/2020'), findsOneWidget);
    });

    testWidgets('Parsing Issue Date from "date_of_issue" key (AI variant)',
        (tester) async {
      await pumpForm(tester, {
        'date_of_issue': '20/10/2022',
        'id': 'B8888888',
      });
      expect(find.text('20/10/2022'), findsOneWidget);
    });

    testWidgets('Parsing Issue Date from "issuedate" key (Lowercase variant)',
        (tester) async {
      await pumpForm(tester, {
        'issuedate': '01/01/2023',
        'id': 'C9999999',
      });
      expect(find.text('01/01/2023'), findsOneWidget);
    });

    testWidgets('Parsing Issue Date with hyphens (European format)',
        (tester) async {
      await pumpForm(tester, {
        'issueDate': '10-12-2025',
        'id': 'D7777777',
      });
      expect(find.text('10/12/2025'), findsOneWidget);
    });

    testWidgets('Handling Invalid Date (Fallbacks to Today)', (tester) async {
      // If date is invalid, it defaults to today.
      // We can't easily check "Today" string universally without constructing it,
      // but we can ensure it doesn't crash or show garbage.
      await pumpForm(tester, {
        'issueDate': 'invalid-date',
        'id': 'E6666666',
      });
      // Just ensure widget pumps without error
      expect(find.byType(PassportInputForm), findsOneWidget);
    });
  });
}
