import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart'; // Để dùng compute
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/utils/string_utils.dart';

enum ScanType { cccd, passport }

class CccdScanService {
  final TextRecognizer _textRecognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  // Dùng mode accurate nhưng minFaceSize nhỏ để bắt mặt tốt trên thẻ
  final FaceDetector _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
          performanceMode: FaceDetectorMode.accurate,
          enableLandmarks: true,
          enableContours: true,
          minFaceSize: 0.1));

  final String _groqApiKey =
      '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';
  final String _groqUrl = 'https://api.groq.com/openai/v1/chat/completions';

  void dispose() {
    _textRecognizer.close();
    _faceDetector.close();
  }

  /// Hàm xử lý chính
  Future<Map<String, dynamic>> processImage(
      File imageFile, bool isFrontSide, ScanType scanType) async {
    final Stopwatch stopwatch = Stopwatch()..start();
    try {
      String sideLabel = isFrontSide ? "MẶT TRƯỚC" : "MẶT SAU";
      debugPrint("\n=== 📷 [$sideLabel] BẮT ĐẦU XỬ LÝ (Start) ===");

      // 1. Khởi chạy song song (Parallel Execution)
      // Task A: Cắt ảnh khuôn mặt (Chỉ mặt trước) - Dùng ảnh GỐC (Màu)
      Future<String?>? avatarFuture;
      if (isFrontSide) {
        avatarFuture = _cropFaceHybrid(imageFile);
      } else {
        avatarFuture = Future.value(null);
      }

      // [REVERTED] Pre-processing removed to fix lag/performance issues.
      // Final decision: Use original image.
      File ocrInputFile = imageFile;

      /* 
      // [DISABLED] ImageEnhancer 
      try {
         // ... 
      } catch (e) { ... }
      */

      // Task B: OCR Text (Native ML Kit) - Dùng ảnh GỐC
      final inputImageForOcr = InputImage.fromFilePath(ocrInputFile.path);
      Future<RecognizedText> ocrFuture =
          _textRecognizer.processImage(inputImageForOcr);

      // Chờ Task OCR xong trước để lấy text gọi AI
      final RecognizedText recognizedText = await ocrFuture;
      debugPrint("⏱️ OCR Time: ${stopwatch.elapsedMilliseconds}ms");

      // Task C: Gọi AI (Phụ thuộc vào OCR)
      Future<Map<String, String>> aiFuture =
          _callGroqAI(recognizedText.text, !isFrontSide, scanType);

      // Chờ cả AI và Cut Face hoàn thành
      final results = await Future.wait([aiFuture, avatarFuture]);
      debugPrint("⏱️ Total Process Time: ${stopwatch.elapsedMilliseconds}ms");

      Map<String, String> extractedData = results[0] as Map<String, String>;
      String? avatarPath = results[1] as String?;

      if (isFrontSide) {
        // [VALIDATION] Chỉ áp dụng validate ID nếu là CCCD
        // Nếu là Passport, ID có thể khác format 12 số, nhưng thường cũng > 6 số.
        // Ta sẽ validation lỏng hơn cho Passport hoặc giữ nguyên nếu Passport VN cũng dài.
        String? id = extractedData['id'];

        bool isValidId = false;
        if (scanType == ScanType.cccd) {
          isValidId =
              id != null && id.length >= 9 && id.contains(RegExp(r'[0-9]'));
        } else {
          // Passport validation: Thường có 1 ký tự chữ + 7 số (8 ký tự) hoặc hơn.
          isValidId = id != null && id.length >= 6;
        }

        // [VALIDATION MỚI] Check Front vs Back confusion
        // Nếu là CCCD mặt trước mà lại thấy MRZ (dấu hiệu mặt sau) -> Cảnh báo
        if (scanType == ScanType.cccd &&
            extractedData.containsKey('mrz') &&
            extractedData['mrz']!.length > 20) {
          debugPrint(
              "⚠️ Phát hiện MRZ ở chế độ Mặt Trước -> Có thể là Mặt Sau");
          return {
            'success': false,
            'error':
                'Có vẻ bạn đang quét MẶT SAU. Vui lòng chuyển sang chế độ quét MẶT TRƯỚC hoặc lật thẻ lại.'
          };
        }

        if (!isValidId) {
          debugPrint("❌ [$sideLabel] ID không hợp lệ.");
          return {
            'success': false,
            'error':
                'Không tìm thấy số ${scanType == ScanType.cccd ? 'CCCD' : 'Hộ chiếu'}. Vui lòng chụp rõ nét hơn.'
          };
        }

        if (avatarPath != null) {
          extractedData['avatarPath'] = avatarPath;
          debugPrint("✅ [FINAL] Avatar Path: $avatarPath");
        } else {
          debugPrint("⚠️ [FINAL] Không cắt được ảnh, sẽ dùng ảnh gốc.");
        }
      } else {
        // --- MẶT SAU (CCCD Only) ---
        // [VALIDATION MỚI] Check Back vs Front confusion
        // Nếu thấy khuôn mặt rõ ràng -> Có thể là Mặt Trước
        // FaceDetector đã chạy ở extractedData không? Không, FaceDetector chạy riêng.
        // Ta cần check kết quả detect face ở step cropFaceHybrid?
        // Nhưng logic cropFaceHybrid chỉ chạy khi isFrontSide = true (Line 46).
        // Vậy nên ta cần chạy check face sơ bộ nếu muốn validate kỹ.
        // Tuy nhiên, để tối ưu hiệu năng, ta check gián tiếp qua keywords.

        // Nếu KHÔNG thấy MRZ -> Khả năng cao không phải mặt sau.
        String? mrz = extractedData['mrz'];
        if (mrz == null || mrz.length < 10) {
          debugPrint("❌ [$sideLabel] Không thấy MRZ.");
          return {
            'success': false,
            'error':
                'Không tìm thấy mã MRZ (Dòng chữ số ở gáy thẻ). Có thể bạn đang quét MẶT TRƯỚC?'
          };
        }
      }

      return {
        'success': true,
        'data': extractedData,
      };
    } catch (e) {
      debugPrint("❌ Lỗi xử lý: $e");
      return {'success': false, 'error': e.toString()};
    }
  }

  // --- HÀM GỌI AI ---
  Future<Map<String, String>> _callGroqAI(
      String rawText, bool isBackSide, ScanType scanType) async {
    String sideLabel = !isBackSide ? "MẶT TRƯỚC" : "MẶT SAU";
    debugPrint("📜 RAW OCR TEXT ($sideLabel):\n$rawText");

    String systemPrompt = "";

    if (scanType == ScanType.cccd) {
      // --- LOGIC GỐC CHO CCCD (KHÔNG ĐỔI) ---
      systemPrompt = isBackSide
          ? '''You are an OCR parser for Vietnamese Citizen ID (Back side). 
Input contains "Nơi cư trú" (Residence), "Nơi đăng ký khai sinh" (Hometown), "Ngày, tháng, năm / Date of issue", and MRZ.
Labels might be noisy (e.g., "Noi cutrà" = "Nơi cư trú").

Extract:
1. "issueDate": Date of issue (dd/MM/yyyy).
2. "mrz": Machine Readable Zone text (lines with <<).
3. "hometown": Extract ONLY if you see explicit label "Nơi sinh" or "Quê quán".
   - CRITICAL: IGNORE MRZ lines (containing "<<") completely for this field.
   - If no label found, return empty string "".
   - Do NOT autocorrect proper names to generic terms.
4. "residence": CAPTURE EVERYTHING after the label "Nơi cư trú" / "Residence". 
   - INCLUDE leading numbers.
   - Fix phonetic errors (e.g. "Csang Nhiê" -> "Sông Nhuệ", "Ha Dông" -> "Hà Đông").
   - IGNORE MRZ lines.
Output JSON.'''
          : '''You are an advanced OCR Data Extractor for Vietnamese Citizen ID (CCCD).
Fields to Extract:
1. "id": 12-digit number (CCCD) or 9-digit (CMND).
2. "name": Full Name (ALL CAPS). Fix OCR typos (e.g. "VẪN"->"VĂN", "TH!"->"THỊ").
3. "dob": dd/MM/yyyy.
4. "sex": "Nam"/"Nữ".
5. "nationality": "Việt Nam".
6. "hometown": "Quê quán" / "Nơi sinh". Fix address typos.
7. "residence": "Nơi thường trú". Reconstruct address.
8. "expiry": Expiration date (dd/MM/yyyy).
9. "type": "CHIP" (12 digits) or "OLD" (9 digits).
   - If ID has 12 digits, set "type": "CHIP".
   - If ID has 9 digits, set "type": "OLD".

Rules:
- JSON Only.
- Fix typos aggressively based on Vietnamese dictionary.
- If field is missing, return empty string.''';
    } else {
      // --- LOGIC MỚI CHO PASSPORT ---
      // Passport thường chỉ quét 1 mặt (Mặt chính có ảnh)
      systemPrompt =
          '''You are an advanced OCR Data Extractor for Passports (Hộ Chiếu).
Fields to Extract:
1. "id": Passport Number (Số hộ chiếu).
2. "name": Full Name (ALL CAPS). Fix OCR typos.
3. "dob": Date of birth (dd/MM/yyyy).
4. "sex": "Nam"/"Nữ" or "M"/"F". Map M->Nam, F->Nữ if possible.
5. "nationality": Nationality (e.g. "Việt Nam").
6. "hometown": Place of birth (Nơi sinh).
7. "residence": Place of issue or blank if not clear. (Passports dont usually have detailed residence).
8. "expiry": Date of expiration (dd/MM/yyyy).
9. "issueDate": Date of issue.
10. "mrz": Machine Readable Zone if found.

Rules:
- JSON Only.
- Fix typos.
- If field is missing, return empty string.''';
    }

    try {
      final response = await http.post(
        Uri.parse(_groqUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_groqApiKey'
        },
        body: jsonEncode({
          "model": "llama-3.3-70b-versatile",
          "messages": [
            {"role": "system", "content": systemPrompt},
            {"role": "user", "content": "Raw OCR Text:\n$rawText"}
          ],
          "response_format": {"type": "json_object"},
          "temperature": 0.1
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        String content = data['choices'][0]['message']['content'];
        int start = content.indexOf('{');
        int end = content.lastIndexOf('}');
        if (start != -1 && end != -1) {
          Map<String, dynamic> jsonResult =
              jsonDecode(content.substring(start, end + 1));

          debugPrint("📝 AI EXTRACTED DATA: ${jsonEncode(jsonResult)}");

          Map<String, String> result =
              jsonResult.map((k, v) => MapEntry(k, v?.toString() ?? ""));

          // [POST-PROCESSING] Validate Name specifically
          if (result.containsKey("name")) {
            result["name"] = _cleanName(result["name"]!);
          }

          // [LOGIC BỔ SUNG] Chỉ chạy logic tính ngày hết hạn cho CCCD
          if (scanType == ScanType.cccd &&
              !isBackSide &&
              result.containsKey("dob") &&
              result["dob"]!.isNotEmpty) {
            String dob = result["dob"]!;
            String ocrExpiry = result["expiry"] ?? "";
            String cardType = result["type"] ?? "OLD";
            String id = result["id"] ?? "";

            bool isModernCard = cardType == "CHIP" || (id.length == 12);

            if (isModernCard) {
              String calcExpiry = _calculateExpiry(dob);
              if (calcExpiry.isNotEmpty &&
                  (ocrExpiry.isEmpty || ocrExpiry != calcExpiry)) {
                debugPrint(
                    "👉 [Expiry Logic] Detected Modern/12-digit Card. Overriding/Filling exp: $calcExpiry (OCR was: $ocrExpiry)");
                result["expiry"] = calcExpiry;
              }
            } else {
              debugPrint(
                  "👉 [Expiry Logic] Detected OLD/9-digit Card. Trusting OCR Expiry: $ocrExpiry");
            }
          }
          return result;
        }
      }
    } catch (e) {
      debugPrint("❌ AI Error: $e");
    }
    return {};
  }

  // [NEW] Helper to clean Name
  String _cleanName(String input) {
    try {
      if (input.isEmpty) return "";

      // 1. Remove prefixes
      String cleaned =
          input.replaceAll(RegExp(r'(?i)^(HO VA TEN|HO TEN|NAME)[:\s]*'), '');

      // 2. To Uppercase
      cleaned = cleaned.toUpperCase();

      // 3. Remove non-name characters (Digits, Symbols). ALLOW Vietnamese accents.
      // Using Blacklist approach is safer than Whitelist \p{L} to avoid crashing.
      cleaned = cleaned.replaceAll(
          RegExp(r'[0-9!@#\$%^&*()_+={}\[\]|\\:;"<>,.?/~`-]'), '');

      // 4. Normalize spaces
      cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();

      // 5. [NEW] Remove Diacritics (Chuyển thành không dấu)
      // Input đang là Uppercase có dấu (do step 2) -> toLowerCase -> remove -> toUpperCase
      cleaned =
          StringUtils.removeDiacritics(cleaned.toLowerCase()).toUpperCase();

      return cleaned;
    } catch (e) {
      debugPrint("⚠️ _cleanName Error: $e");
      return input.toUpperCase(); // Fallback
    }
  }

  // --- [FIXED] HÀM CẮT ẢNH HYBRID ---
  // Chiến thuật: Detect trên ảnh gốc -> Truyền tọa độ vào Isolate -> Cắt trên ảnh đã bakeOrientation
  Future<String?> _cropFaceHybrid(File originalFile) async {
    try {
      // BƯỚC 1: Detect trên ảnh gốc (Giống file A -> Đảm bảo luôn tìm thấy mặt)
      final inputImage = InputImage.fromFilePath(originalFile.path);
      final faces = await _faceDetector.processImage(inputImage);

      debugPrint(
          "🔍 [Hybrid] Tìm thấy ${faces.length} khuôn mặt trên ảnh gốc.");

      if (faces.isEmpty) {
        // Fallback: Nếu không thấy mặt, cắt vùng mặc định bên trái (Blind Crop)
        debugPrint("⚠️ Không thấy mặt -> Chuyển sang Blind Crop.");
        return await compute(_blindCrop, {
          'path': originalFile.path,
          'saveDir': (await getApplicationDocumentsDirectory()).path
        });
      }

      // Lấy mặt to nhất
      faces.sort((a, b) => (b.boundingBox.width * b.boundingBox.height)
          .compareTo(a.boundingBox.width * a.boundingBox.height));
      final face = faces.first;

      // BƯỚC 2: Truyền tọa độ và file gốc vào Isolate để cắt
      // Lưu ý: ML Kit trả về tọa độ "Upright" (đã tính xoay).
      // Khi vào Isolate, ta bakeOrientation thì ảnh cũng thành "Upright".
      // => Tọa độ khớp nhau!
      final appDir = await getApplicationDocumentsDirectory();

      final croppedPath = await compute(_cropImageInIsolate, {
        'imagePath': originalFile.path,
        'saveDir': appDir.path,
        // Bounding Box
        'l': face.boundingBox.left.toInt(),
        't': face.boundingBox.top.toInt(),
        'w': face.boundingBox.width.toInt(),
        'h': face.boundingBox.height.toInt(),
        // Contours
        'contours': face.contours[FaceContourType.face]?.points
                .map((p) => [p.x, p.y])
                .toList() ??
            []
      });

      return croppedPath;
    } catch (e) {
      debugPrint("❌ Lỗi crop: $e");
      return null;
    }
  }

  String _calculateExpiry(String dobStr) {
    try {
      DateTime dob =
          DateFormat("dd/MM/yyyy").parse(dobStr.replaceAll('-', '/').trim());
      DateTime now = DateTime.now();
      int age = now.year - dob.year;
      if (now.month < dob.month ||
          (now.month == dob.month && now.day < dob.day)) age--;
      int targetYear;
      if (age < 25)
        targetYear = dob.year + 25;
      else if (age < 40)
        targetYear = dob.year + 40;
      else if (age < 60)
        targetYear = dob.year + 60;
      else
        return "Vô thời hạn";
      return DateFormat("dd/MM/yyyy")
          .format(DateTime(targetYear, dob.month, dob.day));
    } catch (e) {
      return "";
    }
  }
}

// -----------------------------------------------------------
// CÁC HÀM ISOLATE
// -----------------------------------------------------------

Future<String?> _cropImageInIsolate(Map<String, dynamic> params) async {
  try {
    final File file = File(params['imagePath']);
    final bytes = await file.readAsBytes();
    img.Image? src = img.decodeImage(bytes);
    if (src == null) return null;

    // [QUAN TRỌNG] Xoay ảnh để khớp với hệ tọa độ của ML Kit
    src = img.bakeOrientation(src);

    // Không resize 'src' ở đây để đảm bảo tọa độ không bị lệch
    // Cắt xong mới resize

    int x, y, w, h;
    final List<dynamic> points = params['contours'];

    if (points.isNotEmpty) {
      // Logic Contours
      int minX = src.width;
      int maxX = 0;
      int minY = src.height;
      int maxY = 0;

      for (var p in points) {
        int px = (p[0] as num).toInt();
        int py = (p[1] as num).toInt();
        if (px < minX) minX = px;
        if (px > maxX) maxX = px;
        if (py < minY) minY = py;
        if (py > maxY) maxY = py;
      }

      // Padding
      int padW = ((maxX - minX) * 0.20).toInt();
      int padH_Top = ((maxY - minY) * 0.45).toInt();
      int padH_Bot = ((maxY - minY) * 0.35).toInt();

      x = (minX - padW).clamp(0, src.width);
      y = (minY - padH_Top).clamp(0, src.height);
      int x2 = (maxX + padW).clamp(0, src.width);
      int y2 = (maxY + padH_Bot).clamp(0, src.height);

      w = x2 - x;
      h = y2 - y;
    } else {
      // Logic Bounding Box
      int bx = params['l'];
      int by = params['t'];
      int bw = params['w'];
      int bh = params['h'];

      int padX = (bw * 0.2).toInt();
      x = (bx - padX).clamp(0, src.width);
      y = (by - (bh * 0.4).toInt()).clamp(0, src.height);
      w = (bw + padX * 2).clamp(1, src.width - x);
      h = (bh + (bh * 0.7).toInt()).clamp(1, src.height - y);
    }

    if (w <= 0 || h <= 0) return null;

    // Cắt ảnh
    img.Image faceCrop = img.copyCrop(src, x: x, y: y, width: w, height: h);

    // Resize ảnh KẾT QUẢ (Avatar) cho nhẹ app
    if (faceCrop.width > 400) {
      faceCrop = img.copyResize(faceCrop, width: 400);
    }

    final String finalPath =
        '${params['saveDir']}/avatar_final_${DateTime.now().millisecondsSinceEpoch}.jpg';
    File(finalPath).writeAsBytesSync(img.encodeJpg(faceCrop, quality: 90));

    return finalPath;
  } catch (e) {
    return null;
  }
}

// Cắt mù (dự phòng)
Future<String?> _blindCrop(Map<String, dynamic> params) async {
  try {
    final File file = File(params['path']);
    final bytes = await file.readAsBytes();
    img.Image? src = img.decodeImage(bytes);
    if (src == null) return null;
    src = img.bakeOrientation(src);

    // Vị trí áng chừng của ảnh thẻ trên CCCD (Bên trái, giữa)
    int x = (src.width * 0.05).toInt();
    int y = (src.height * 0.25).toInt();
    int w = (src.width * 0.35).toInt();
    int h = (src.height * 0.50).toInt();

    img.Image face = img.copyCrop(src, x: x, y: y, width: w, height: h);
    if (face.width > 400) face = img.copyResize(face, width: 400);

    final path =
        '${params['saveDir']}/avatar_blind_${DateTime.now().millisecondsSinceEpoch}.jpg';
    File(path).writeAsBytesSync(img.encodeJpg(face, quality: 85));
    return path;
  } catch (_) {
    return null;
  }
}
