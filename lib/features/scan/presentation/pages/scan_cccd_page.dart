import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

// [QUAN TRỌNG] Đảm bảo import đúng đường dẫn 2 file này
import '../../data/scan_function.dart';
import '../widgets/ui_scan.dart';
import 'cccd_details_page.dart';
import '../../../../core/theme/app_colors.dart';

class ScanCccdPage extends StatefulWidget {
  const ScanCccdPage({super.key});

  @override
  State<ScanCccdPage> createState() => _ScanCccdPageState();
}

class _ScanCccdPageState extends State<ScanCccdPage>
    with SingleTickerProviderStateMixin {
  bool _isFlashOn = false;
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isFrontSide = true; // True: Mặt trước, False: Mặt sau
  bool _isProcessing = false;
  ScanType _scanType = ScanType.cccd;

  late AnimationController _animationController;

  // [LOGIC] Sử dụng Service xử lý ảnh (Đã chứa logic Cắt Contour + Xoay ảnh)
  final CccdScanService _scanService = CccdScanService();

  // Biến lưu trữ dữ liệu quét được
  final Map<String, String> _collectedData = {};
  String? _frontImagePath;
  String? _backImagePath;

  @override
  void initState() {
    super.initState();
    _initializeCamera();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        final backCam = cameras.firstWhere(
            (c) => c.lensDirection == CameraLensDirection.back,
            orElse: () => cameras.first);

        _cameraController = CameraController(
          backCam,
          ResolutionPreset.high, // Dùng độ phân giải cao để detect mặt tốt hơn
          enableAudio: false,
          imageFormatGroup: Platform.isAndroid
              ? ImageFormatGroup.nv21
              : ImageFormatGroup.bgra8888,
        );

        await _cameraController!.initialize();
        await _cameraController!
            .setFocusMode(FocusMode.auto); // Để tự động lấy nét (Continuous AF)

        if (mounted) {
          setState(() => _isCameraInitialized = true);
        }
      }
    } catch (e) {
      debugPrint('Lỗi camera: $e');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _cameraController?.dispose();
    _scanService.dispose(); // Giải phóng Service
    super.dispose();
  }

  // --- HÀM XỬ LÝ CHÍNH ---
  Future<void> _captureAndProcess() async {
    if (_isProcessing || !_isCameraInitialized || _cameraController == null)
      return;

    setState(() => _isProcessing = true);
    // Lưu ý: Không stop animation để tránh cảm giác app bị đơ khi xử lý ngầm

    try {
      // 1. Chụp ảnh
      final imageXFile = await _cameraController!.takePicture();
      final imageFile = File(imageXFile.path);

      // 2. GỌI SERVICE (Tất cả logic cắt ảnh/OCR nằm trong này)
      // Hàm này sẽ trả về Map chứa: id, name, ... và quan trọng là 'avatarPath'
      final result =
          await _scanService.processImage(imageFile, _isFrontSide, _scanType);

      if (!mounted) return;

      if (result['success'] == true) {
        final data = result['data'] as Map<String, String>;

        if (_isFrontSide) {
          // --- MẶT TRƯỚC (Hoặc Hộ Chiếu - Chỉ 1 mặt) ---
          _collectedData.addAll(data); // Lưu hết dữ liệu (bao gồm avatarPath)

          if (data.containsKey('avatarPath')) {
            debugPrint("✅ Tìm thấy ảnh khuôn mặt: ${data['avatarPath']}");
          } else {
            debugPrint("⚠️ Không tìm thấy ảnh khuôn mặt trong kết quả.");
          }

          setState(() {
            _frontImagePath = imageFile.path;
            _isProcessing = false;
          });

          // [LOGIC MỚI] Nếu là Passport -> Hoàn tất luôn
          if (_scanType == ScanType.passport) {
            _showMessage("Hoàn tất quét Hộ Chiếu!", Colors.green);
            _navigateToDetails();
          } else {
            // [LOGIC CŨ] CCCD -> Chuyển sang mặt sau
            _showMessage("Đã chụp mặt trước. Vui lòng lật thẻ!", Colors.green);
            Future.delayed(const Duration(milliseconds: 800), () {
              if (mounted) {
                setState(() => _isFrontSide = false);
              }
            });
          }
        } else {
          // --- MẶT SAU (Chỉ dành cho CCCD) ---
          // Chỉ lấy bổ sung ngày cấp và MRZ, không ghi đè tên/số
          if (data.containsKey('issueDate') && data['issueDate']!.isNotEmpty) {
            _collectedData['issueDate'] = data['issueDate']!;
          }
          if (data.containsKey('mrz')) {
            _collectedData['mrz'] = data['mrz']!;
          }
          // [NEW] Cho thẻ CCCD mẫu mới (2024): Quê quán & ĐC thường trú ở mặt sau
          // Logic: Chỉ cập nhật nếu dữ liệu từ Mặt Trước (đã quét xong) bị thiếu/trống.
          // Tránh trường hợp AI mặt sau "ảo giác" (nhìn nhầm MRZ thành địa chỉ) ghi đè lên dữ liệu đúng của mặt trước.
          if (data.containsKey('hometown') &&
              data['hometown']!.isNotEmpty &&
              (_collectedData['hometown']?.isEmpty ?? true)) {
            _collectedData['hometown'] = data['hometown']!;
          }
          if (data.containsKey('residence') &&
              data['residence']!.isNotEmpty &&
              (_collectedData['residence']?.isEmpty ?? true)) {
            _collectedData['residence'] = data['residence']!;
          }

          setState(() {
            _backImagePath = imageFile.path;
            _isProcessing = false;
          });

          _showMessage("Hoàn tất quét CCCD!", Colors.green);
          _navigateToDetails();
        }
      } else {
        throw Exception(result['error']);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        _showMessage(
            "Lỗi: ${e.toString().replaceAll('Exception:', '')}", AppColors.red);
      }
    }
  }

  void _navigateToDetails() async {
    _animationController.stop();

    final shouldClose = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CccdDetailsPage(
          frontImagePath: _frontImagePath!,
          backImagePath:
              _backImagePath ?? _frontImagePath!, // Passport has no back image
          scannedData: _collectedData,
        ),
      ),
    );

    // Nếu trang chi tiết trả về true (đã Lưu/Xóa) -> Đóng luôn trang Scan
    if (shouldClose == true && mounted) {
      Navigator.of(context).pop();
      return;
    }

    // Resume khi quay lại (nếu chưa đóng)
    if (mounted) _animationController.repeat(reverse: true);
  }

  void _showMessage(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(msg),
          backgroundColor: color,
          duration: const Duration(seconds: 2)),
    );
  }

  Widget _buildTypeButton(String title, ScanType type) {
    final isSelected = _scanType == type;
    return GestureDetector(
      onTap: () {
        if (!isSelected) {
          setState(() {
            _scanType = type;
            _isFrontSide = true; // Reset to front whenever switching
            _collectedData.clear();
            _frontImagePath = null;
            _backImagePath = null;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.red : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  String _getInstructionText() {
    if (_scanType == ScanType.passport) return "Trang thông tin Hộ Chiếu";
    return _isFrontSide ? 'Mặt trước CCCD' : 'Mặt sau CCCD';
  }

  // --- UI ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Camera Preview
          if (_isCameraInitialized && _cameraController != null)
            Positioned.fill(child: CameraPreview(_cameraController!))
          else
            const Center(child: CircularProgressIndicator(color: Colors.white)),

          // 2. Overlay
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return CustomPaint(
                  painter: ScannerOverlayPainter(
                    // Widget từ ui_scan.dart
                    scanValue: _animationController.value,
                  ),
                );
              },
            ),
          ),

          // 3. Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text('Quét CCCD',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: Icon(_isFlashOn ? Icons.flash_on : Icons.flash_off,
                      color: Colors.white),
                  onPressed: () {
                    setState(() => _isFlashOn = !_isFlashOn);
                    _cameraController?.setFlashMode(
                        _isFlashOn ? FlashMode.torch : FlashMode.off);
                  },
                ),
              ],
            ),
          ),

          // 4. Footer Control
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.only(bottom: 20, top: 10),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 15),
                    decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2)),
                  ),
                  // --- Type Selector ---
                  Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildTypeButton("CCCD/CMND", ScanType.cccd),
                        _buildTypeButton("Hộ Chiếu", ScanType.passport),
                      ],
                    ),
                  ),

                  Text(
                    _getInstructionText(),
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'Di chuyển camera để căn chỉnh khung hình khớp với giấy tờ',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 14, color: Colors.grey[500], height: 1.4),
                    ),
                  ),
                  const SizedBox(height: 25),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ScanSquareButton(
                          icon: Icons.image_outlined,
                          iconColor: AppColors.red,
                          bgColor: AppColors.red.withOpacity(0.1),
                          onTap: () {},
                        ),
                        CaptureButton(
                          // Nút chụp chính
                          onTap: _captureAndProcess,
                          isProcessing: _isProcessing,
                        ),
                        ScanSquareButton(
                          icon: Icons.file_upload_outlined,
                          iconColor: AppColors.red,
                          bgColor: AppColors.red.withOpacity(0.1),
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).padding.bottom),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
