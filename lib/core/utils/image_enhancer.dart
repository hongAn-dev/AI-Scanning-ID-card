import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class ImageEnhancer {
  /// Xử lý ảnh để tối ưu cho OCR
  /// 1. Resize (nếu cần) để tăng tốc
  /// 2. Grayscale (Chuyển đen trắng)
  /// 3. Tăng độ tương phản (Contrast) -> Giả lập Binarization
  /// 4. Khử nhiễu (Denoise) - *Optional, tốn resource nên cân nhắc*
  static Future<File?> processForOcr(File inputFile,
      {Directory? outputDir}) async {
    final stopwatch = Stopwatch()..start();
    try {
      debugPrint("🔄 [ImageEnhancer] Start processing: ${inputFile.path}");

      final bytes = await inputFile.readAsBytes();
      img.Image? originalImage = img.decodeImage(bytes);

      if (originalImage == null) {
        debugPrint("❌ [ImageEnhancer] Error: Could not decode image.");
        return null;
      }

      debugPrint(
          "📊 [ImageEnhancer] Original Size: ${originalImage.width}x${originalImage.height}");

      // 1. Resize nếu quá to (Giữ width tầm 1500px là đủ cho OCR)
      img.Image processed = originalImage;
      if (processed.width > 1500) {
        processed = img.copyResize(processed, width: 1500);
        debugPrint("📉 [ImageEnhancer] Resized to width 1500");
      }

      // 2. Grayscale
      processed = img.grayscale(processed);
      debugPrint("🎨 [ImageEnhancer] Applied Grayscale");

      // 3. Tăng tương phản (Contrast) - Value > 100
      // Trong lib image v4: adjustColor(contrast: ...)
      processed = img.adjustColor(processed, contrast: 1.5); // 1.5 = 150%
      debugPrint("🌗 [ImageEnhancer] Applied Contrast (1.5)");

      // 4. Sharpen (Làm sắc nét cạnh) - Giúp text rõ hơn
      // processed = img.convolution(processed, filter: [0,-1,0, -1,5,-1, 0,-1,0]); // Kernel Sharpen cơ bản
      // debugPrint("🔪 [ImageEnhancer] Applied Sharpening");

      stopwatch.stop();
      debugPrint(
          "✅ [ImageEnhancer] Processing finished in ${stopwatch.elapsedMilliseconds}ms");

      // Lưu file tạm
      final Directory dir = outputDir ?? await getTemporaryDirectory();
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String newPath = '${dir.path}/ocr_enhanced_$timestamp.jpg';
      final File newFile = File(newPath);

      // Save as JPEG with high quality
      await newFile.writeAsBytes(img.encodeJpg(processed, quality: 90));

      return newFile;
    } catch (e) {
      debugPrint("❌ [ImageEnhancer] Exception: $e");
      return null;
    }
  }

  /// Hàm kiểm tra nhanh chất lượng ảnh (độ sáng)
  static Future<Map<String, dynamic>> checkImageQuality(File file) async {
    try {
      final bytes = await file.readAsBytes();
      img.Image? image = img.decodeImage(bytes);
      if (image == null) return {'error': 'Cannot decode'};

      // Tính độ sáng trung bình (Luminance)
      double totalLuminance = 0;
      // Sample 1% pixels for speed
      int step = 10;
      int count = 0;

      for (int y = 0; y < image.height; y += step) {
        for (int x = 0; x < image.width; x += step) {
          final pixel = image.getPixel(x, y);
          totalLuminance +=
              pixel.luminance; // 0-1 range or 0-255 depending on version
          count++;
        }
      }

      double avgLuminance = count > 0 ? totalLuminance / count : 0;
      // Normalize to 0-255 if needed, image v4 luminance usually returns 0-1 for normalized or 0-255

      // Basic heuristic
      bool isTooDark = avgLuminance < 50; // Giả sử range 0-255
      bool isTooBright = avgLuminance > 230;

      return {
        'width': image.width,
        'height': image.height,
        'avgLuminance': avgLuminance.toStringAsFixed(2),
        'isTooDark': isTooDark,
        'isTooBright': isTooBright,
        'isGoodForOCR': !isTooDark && !isTooBright
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}
