import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

// [QUAN TRỌNG] Đảm bảo import đúng đường dẫn 2 file này
import '../../data/scan_function.dart';
import '../widgets/ui_scan.dart';
import 'cccd_details_page.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../injection_container.dart' as di;
import '../../../auth/data/auth_service.dart';

class ScanCccdPage extends StatefulWidget {
  const ScanCccdPage({super.key});

  @override
  State<ScanCccdPage> createState() => _ScanCccdPageState();
}

class _ScanCccdPageState extends State<ScanCccdPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
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
    WidgetsBinding.instance
        .addObserver(this); // [FIX] Quan sát vòng đời ứng dụng
    _initializeCamera();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // [FIX] Xử lý khi app bị ẩn hoặc mở lại (Background/Foreground)
    final CameraController? cameraController = _cameraController;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      // App bị ẩn -> Dừng camera
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      // App mở lại -> Khởi tạo lại camera
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    debugPrint("📷 Bắt đầu khởi tạo Camera...");
    if (_cameraController != null) {
      // Dispose cũ nếu có
      await _cameraController!.dispose();
    }

    try {
      // 1. Xin quyền Camera trước
      var status = await Permission.camera.request();
      debugPrint("📷 Trạng thái quyền Camera: $status");

      if (!status.isGranted) {
        if (status.isPermanentlyDenied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                    'Bạn đã từ chối quyền Camera. Vui lòng bật trong Cài đặt.'),
                action: SnackBarAction(
                  label: 'Mở Cài đặt',
                  onPressed: () => openAppSettings(),
                ),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
              ),
            );
          }
          return;
        }

        if (mounted)
          _showMessage(
              "Bạn cần cấp quyền Camera để sử dụng tính năng này", Colors.red);
        return;
      }

      // 2. Lấy danh sách camera
      final cameras = await availableCameras();
      debugPrint("📷 Tìm thấy ${cameras.length} camera");

      if (cameras.isEmpty) {
        if (mounted)
          _showMessage(
              "Không tìm thấy camera (Nếu chạy trên Simulator, vui lòng dùng máy thật)",
              Colors.orange);
        return;
      }

      final backCam = cameras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.back,
          orElse: () => cameras.first);

      debugPrint(
          "📷 Đã chọn camera: ${backCam.name} - ${backCam.lensDirection}");

      _cameraController = CameraController(
        backCam,
        ResolutionPreset.veryHigh,
        enableAudio: false,
        // [FIX] Bỏ imageFormatGroup trên iOS để tránh lỗi màn hình đen
      );

      debugPrint("📷 Đang gọi controller.initialize()...");
      await _cameraController!.initialize();
      debugPrint("📷 initialize() xong. Đang set focus mode...");

      await _cameraController!.setFocusMode(FocusMode.auto);
      debugPrint("📷 Set focus mode xong.");

      if (mounted) {
        setState(() => _isCameraInitialized = true);
        debugPrint("📷 State đã update: _isCameraInitialized = true");
      }
    } catch (e, stackTrace) {
      debugPrint('📷 ❌ Lỗi khởi tạo camera: $e');
      debugPrint('📷 ❌ StackTrace: $stackTrace');
      if (mounted) _showMessage("Không thể khởi tạo Camera: $e", Colors.red);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // [FIX] Remove observer
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

      // --- DEMO MODE CHECK ---
      try {
        if (di.sl.isRegistered<AuthService>()) {
          final authService = di.sl<AuthService>();
          if (authService.isDemoMode()) {
            await Future.delayed(const Duration(seconds: 1)); // Fake processing

            if (_isFrontSide) {
              _collectedData.addAll({
                "id": "001202029221",
                "name": "NGUYỄN VĂN DEMO",
                "dob": "01/01/1995",
                "sex": "Nam",
                "nationality": "Việt Nam",
                "hometown": "Hoàn Kiếm, Hà Nội",
                "residence": "Số 1 Đại Cồ Việt, Hai Bà Trưng, Hà Nội",
                "doe": "01/01/2035",
                "avatarPath": imageFile.path, // Use captured image as avatar
              });

              if (mounted) {
                setState(() {
                  _frontImagePath = imageFile.path;
                  _isProcessing = false;
                });
              }

              if (_scanType == ScanType.passport) {
                _showMessage("Hoàn tất quét Hộ Chiếu (Demo)!", Colors.green);
                _navigateToDetails();
              } else {
                _showMessage("Đã chụp mặt trước (Demo). Vui lòng lật thẻ!",
                    Colors.green);
                Future.delayed(const Duration(milliseconds: 800), () {
                  if (mounted) setState(() => _isFrontSide = false);
                });
              }
              return; // Stop here
            } else {
              // Back side
              _collectedData['issueDate'] = "01/01/2021";
              _collectedData['mrz'] =
                  "IDVNM001202029221<<001202029221\n9501010M3501010VNM<<<<<<<<<<<6\nNGUYEN<<VAN<DEMO<<<<<<<<<<<<<<<";

              if (mounted) {
                setState(() {
                  _backImagePath = imageFile.path;
                  _isProcessing = false;
                });
              }

              _showMessage("Hoàn tất quét CCCD (Demo)!", Colors.green);
              _navigateToDetails();
              return; // Stop here
            }
          }
        }
      } catch (e) {
        debugPrint("Demo mode check failed: $e");
      }
      // -----------------------

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
          scannedData: {
            ..._collectedData,
            'type': _scanType == ScanType.passport ? 'PASSPORT' : 'CCCD',
          },
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

  // --- HÀM XỬ LÝ ẢNH TỪ THƯ VIỆN ---
  Future<void> _pickImageFromGallery() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image == null) return;

      setState(() => _isProcessing = true);

      final imageFile = File(image.path);

      // Gọi Service xử lý ảnh giống như chụp camera
      final result =
          await _scanService.processImage(imageFile, _isFrontSide, _scanType);

      if (!mounted) return;

      if (result['success'] == true) {
        final data = result['data'] as Map<String, String>;

        // [MODIFIED] Smart Merge logic tương tự _captureAndProcess
        if (_isFrontSide || _scanType == ScanType.passport) {
          _collectedData.addAll(data);
        } else {
          // Mặt sau: Chỉ update các trường còn thiếu hoặc đặc thù mặt sau
          if (data.containsKey('issueDate') && data['issueDate']!.isNotEmpty) {
            _collectedData['issueDate'] = data['issueDate']!;
          }
          if (data.containsKey('mrz')) {
            _collectedData['mrz'] = data['mrz']!;
          }

          // Chỉ ghi đè quê quán/thường trú nếu chưa tìm thấy ở mặt trước
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
        }

        // Với ảnh thư viện, ta coi như là quét xong 1 mặt luôn

        setState(() {
          if (_isFrontSide) {
            _frontImagePath = imageFile.path;
          } else {
            _backImagePath = imageFile.path;
          }
          _isProcessing = false;
        });

        _showMessage("Đã tải ảnh thành công!", Colors.green);

        // Logic điều hướng
        if (_scanType == ScanType.passport || !_isFrontSide) {
          _navigateToDetails();
        } else {
          _showMessage("Vui lòng tải tiếp mặt sau (nếu có)", Colors.blue);
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) setState(() => _isFrontSide = false);
          });
        }
      } else {
        throw Exception(result['error']);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        _showMessage("Lỗi xử lý ảnh: $e", Colors.red);
      }
    }
  }

  // --- HÀM NHẬP TAY ---
  void _navigateToManualInput() {
    _animationController.stop();
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (_) => CccdDetailsPage(
          frontImagePath: "", // Không có ảnh
          backImagePath: "",
          scannedData: {}, // Dữ liệu trống để nhập tay
        ),
      ),
    )
        .then((_) {
      if (mounted) _animationController.repeat(reverse: true);
    });
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
                          icon: Icons.photo_library_outlined,
                          iconColor: AppColors.red,
                          bgColor: AppColors.red.withOpacity(0.1),
                          onTap: _pickImageFromGallery,
                        ),
                        CaptureButton(
                          // Nút chụp chính
                          onTap: _captureAndProcess,
                          isProcessing: _isProcessing,
                        ),
                        ScanSquareButton(
                          icon: Icons.edit_note, // Icon nhập tay
                          iconColor: AppColors.red,
                          bgColor: AppColors.red.withOpacity(0.1),
                          onTap: _navigateToManualInput,
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
