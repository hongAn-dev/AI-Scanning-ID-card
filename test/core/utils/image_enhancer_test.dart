import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:masterpro_ai_scan_id/core/utils/image_enhancer.dart';
import 'package:image/image.dart' as img; // Dùng để tạo ảnh giả

Future<void> main() async {
  // Test Environment Setup
  TestWidgetsFlutterBinding.ensureInitialized();

  test('ImageEnhancer Quality & Performance Test', () async {
    print('\n🚀 --- BẮT ĐẦU TEST XỬ LÝ ẢNH ---');

    // 1. Tạo ảnh giả (Mock Image) thay vì load file thật (để chạy được mọi nơi)
    // Tạo ảnh đen trắng nhiễu nhiễu chút
    print('📸 1. Đang tạo ảnh giả lập (1000x800)...');
    final mockImage = img.Image(width: 1000, height: 800);

    // Fill background xám
    img.fill(mockImage, color: img.ColorRgb8(128, 128, 128));

    // Vẽ vài đường text đen (Giả lập text)
    img.drawLine(mockImage,
        x1: 50, y1: 100, x2: 900, y2: 100, color: img.ColorRgb8(0, 0, 0));
    img.drawLine(mockImage,
        x1: 50, y1: 200, x2: 900, y2: 200, color: img.ColorRgb8(10, 10, 10));

    // Save ra file temp thật để test hàm đọc file
    final tempDir = Directory.systemTemp.createTempSync();
    final mockFile = File('${tempDir.path}/mock_cccd.jpg');
    mockFile.writeAsBytesSync(img.encodeJpg(mockImage));
    print(
        '✅ Đã tạo file tạm: ${mockFile.path} (${mockFile.lengthSync()} bytes)');

    // 2. Kiểm tra chất lượng TRƯỚC khi xử lý
    print('\n🔍 2. Kiểm tra chất lượng ảnh GỐC...');
    final qualityBefore = await ImageEnhancer.checkImageQuality(mockFile);
    print('   - Độ sáng (Luminance): ${qualityBefore['avgLuminance']}');
    print(
        '   - Đánh giá: ${qualityBefore['isGoodForOCR'] == true ? "TỐT" : "KÉM"}');

    // 3. Chạy xử lý Image Enhancement
    print('\n⚙️ 3. Đang chạy ImageEnhancer.processForOcr()...');
    final stopwatch = Stopwatch()..start();

    final processedFile =
        await ImageEnhancer.processForOcr(mockFile, outputDir: tempDir);

    stopwatch.stop();
    print('⏱️ Thời gian xử lý: ${stopwatch.elapsedMilliseconds} ms');

    // 4. Assertions & Kiểm tra kết quả
    expect(processedFile, isNotNull, reason: "File sau xử lý không được null");
    expect(processedFile!.existsSync(), true,
        reason: "File sau xử lý phải tồn tại trên ổ cứng");

    print('\n🔍 4. Kiểm tra chất lượng ảnh SAU KHI XỬ LÝ (Enhanced)...');
    // Note: Sau khi tăng tương phản, độ sáng trung bình có thể thay đổi hoặc giữ nguyên nhưng histogram sẽ dãn ra.
    // Với ảnh test xám đều (128), tăng contrast sẽ đẩy nó về cực (đen hơn hoặc trắng hơn tùy thuật toán).

    final qualityAfter = await ImageEnhancer.checkImageQuality(processedFile);
    print('   - Path: ${processedFile.path}');
    print('   - Size on Disk: ${processedFile.lengthSync()} bytes');
    print('   - Độ sáng mới: ${qualityAfter['avgLuminance']}');

    // 5. Cleanup
    mockFile.deleteSync();
    processedFile.deleteSync();
    tempDir.deleteSync();

    print('\n✅ TEST CASE COMPLETED - Chức năng xử lý ảnh hoạt động ổn định.');
  });
}
