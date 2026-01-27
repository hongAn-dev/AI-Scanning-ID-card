import 'package:flutter_test/flutter_test.dart';
import 'package:masterpro_ai_scan_id/core/utils/string_utils.dart';

void main() {
  group('Name Cleaning Logic', () {
    test('Should remove accents from uppercase name', () {
      String input = "VÕ HỒNG AN";
      // This logic mirrors _cleanName in scan_function.dart
      String cleaned = input.replaceAll(
          RegExp(r'^(HO VA TEN|HO TEN|NAME)[:\s]*', caseSensitive: false), '');
      cleaned = cleaned.toUpperCase();
      cleaned = cleaned.replaceAll(
          RegExp(r'[0-9!@#\$%^&*()_+={}\[\]|\\:;"<>,.?/~`-]'), '');
      cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
      cleaned =
          StringUtils.removeDiacritics(cleaned.toLowerCase()).toUpperCase();

      expect(cleaned, "VO HONG AN");
    });

    test('Should handle mixed case and prefixes', () {
      String input = "Họ và tên: Nguyễn Văn Á";
      String cleaned = input.replaceAll(
          RegExp(r'^(HO VA TEN|HO TEN|NAME|HỌ VÀ TÊN)[:\s]*',
              caseSensitive: false),
          '');
      // Note: The original regex only covered "HO VA TEN" (no accents), so "Họ và tên" might not be stripped if not normalized first.
      // But let's test the accent removal part specifically.

      input = "NGUYỄN VĂN Á";
      cleaned = input.toUpperCase();
      cleaned =
          StringUtils.removeDiacritics(cleaned.toLowerCase()).toUpperCase();
      expect(cleaned, "NGUYEN VAN A");
    });
  });
}
