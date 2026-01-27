import 'package:flutter_test/flutter_test.dart';
import 'package:masterpro_ai_scan_id/features/scan/data/scan_function.dart';

void main() {
  group('Name Cleaning Logic', () {
    // final service = CccdScanService(); // No longer needed

    test('Should remove accents from uppercase name', () {
      String input = "VÕ HỒNG AN";
      String cleaned = CccdScanService.cleanName(input);
      expect(cleaned, "VO HONG AN");
    });

    test('Should handle mixed case and prefixes', () {
      String input2 = "NGUYỄN VĂN Á";
      String cleaned = CccdScanService.cleanName(input2);
      expect(cleaned, "NGUYEN VAN A");
    });

    test('Should remove prefix if matches pattern', () {
      String input = "HO VA TEN: LE THI B";
      String cleaned = CccdScanService.cleanName(input);
      expect(cleaned, "LE THI B");
    });
  });
}
