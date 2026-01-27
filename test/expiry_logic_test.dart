import 'package:flutter_test/flutter_test.dart';
import 'package:masterpro_ai_scan_id/features/scan/data/scan_function.dart';

void main() {
  group('Expiry Calculation Logic', () {
    // No instance needed for static methods

    test('Should calculate expiry for age < 25 (add 25 years)', () {
      // DOB: 01/01/2010 (Age ~16 in 2026) -> Expiry: 01/01/2035 (2010 + 25)
      String dob = "01/01/2010";
      String expiry = CccdScanService.calculateExpiry(dob);
      expect(expiry, "01/01/2035");
    });

    test('Should calculate expiry for age 25-40 (add 40 years)', () {
      // DOB: 01/01/1995 (Age ~31 in 2026) -> Expiry: 01/01/2035 (1995 + 40)
      String dob = "01/01/1995";
      String expiry = CccdScanService.calculateExpiry(dob);
      expect(expiry, "01/01/2035");
    });

    test('Should calculate expiry for age 40-60 (add 60 years)', () {
      // DOB: 01/01/1975 (Age ~51 in 2026) -> Expiry: 01/01/2035 (1975 + 60)
      String dob = "01/01/1975";
      String expiry = CccdScanService.calculateExpiry(dob);
      expect(expiry, "01/01/2035");
    });

    test('Should return "Vô thời hạn" for age > 60', () {
      // DOB: 01/01/1950 (Age ~76 in 2026) -> Expiry: Vô thời hạn
      String dob = "01/01/1950";
      String expiry = CccdScanService.calculateExpiry(dob);
      expect(expiry, "Vô thời hạn");
    });

    test('Should handle invalid date format gracefully', () {
      String dob = "invalid-date";
      String expiry = CccdScanService.calculateExpiry(dob);
      expect(expiry, "");
    });
  });
}
