import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/string_utils.dart';
import '../../../../injection_container.dart' as di;
import '../../../customers/domain/entities/customer.dart';
import '../../../customers/domain/entities/customer_group.dart';
import '../../../customers/domain/repositories/customer_repository.dart';
import '../../../customers/presentation/bloc/customer_cubit.dart';
import '../../../customers/presentation/bloc/customer_state.dart';
import '../../../auth/data/auth_service.dart'; // [FIX] Import AuthService

class CccdInputForm extends StatefulWidget {
  final String frontImagePath;
  final String backImagePath;
  final Map<String, dynamic> scannedData;

  const CccdInputForm({
    super.key,
    required this.frontImagePath,
    required this.backImagePath,
    required this.scannedData,
  });

  @override
  State<CccdInputForm> createState() => _CccdInputFormState();
}

class _CccdInputFormState extends State<CccdInputForm> {
  late TextEditingController _nameCtrl;
  late TextEditingController _cccdCtrl;
  late TextEditingController _nationalityCtrl;
  late TextEditingController _originCtrl;
  late TextEditingController _residenceCtrl;

  late DateTime _dob;
  late DateTime _issueDate;
  late DateTime _expiryDate;

  String _gender = 'Nam';

  List<CustomerGroup> _locations = [];
  String? _selectedLocationId;
  bool _isLoadingLocations = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _loadLocations();
    _nameCtrl.addListener(() {
      setState(() {});
    });
  }

  void _initializeData() {
    final data = widget.scannedData;

    // Normalize name to remove diacritics by default to avoid OCR mismatches
    _nameCtrl = TextEditingController(
        text: StringUtils.removeDiacritics(data['name'] ?? ''));
    _cccdCtrl = TextEditingController(text: data['id'] ?? '');
    _nationalityCtrl =
        TextEditingController(text: data['nationality'] ?? 'Việt Nam');
    _originCtrl = TextEditingController(text: data['hometown'] ?? '');
    _residenceCtrl = TextEditingController(text: data['residence'] ?? '');

    _dob = _parseDate(data['dob']);
    _issueDate = _parseDate(data['issueDate']);
    _expiryDate = _parseDate(data['expiry']);

    String sexRaw = (data['sex'] ?? 'Nam').toLowerCase();
    if (sexRaw.contains('nam') || sexRaw.contains('male') || sexRaw == 'm') {
      _gender = 'Nam';
    } else {
      _gender = 'Nữ';
    }
  }

  DateTime _parseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return DateTime.now();
    try {
      return DateFormat('dd/MM/yyyy').parse(dateStr.replaceAll('-', '/'));
    } catch (e) {
      return DateTime.now();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _cccdCtrl.dispose();
    _nationalityCtrl.dispose();
    _originCtrl.dispose();
    _residenceCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadLocations() async {
    setState(() => _isLoadingLocations = true);
    try {
      // [DEMO MODE] Use real logic handling or empty, validation will be skipped.
      // No need to inject fake branch.

      final customerRepo = di.sl<CustomerRepository>();
      final groups = await customerRepo.getCustomerGroups();
      final prefs = await SharedPreferences.getInstance();
      final currentLocationId = prefs.getString('location_id');

      if (mounted) {
        setState(() {
          _locations = groups;
          // Default to current location if exists in list, else first, else null
          if (currentLocationId != null &&
              groups.any((g) => g.id == currentLocationId)) {
            _selectedLocationId = currentLocationId;
          } else if (groups.isNotEmpty) {
            _selectedLocationId = groups.first.id;
          }
        });
      }
    } catch (e) {
      print("Error loading locations: $e");
    } finally {
      if (mounted) setState(() => _isLoadingLocations = false);
    }
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  // --- DATE PICKER HELPER ---
  Future<void> _selectDate(BuildContext context, DateTime initialDate,
      Function(DateTime) onPicked) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      locale:
          const Locale('vi', 'VN'), // Requires initialization supportedLocales
    );
    if (picked != null && picked != initialDate) {
      setState(() {
        onPicked(picked);
      });
    }
  }

  void _showMessage(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Logic kiểm tra ảnh avatar cắt
    bool hasCroppedAvatar = widget.scannedData['avatarPath'] != null &&
        File(widget.scannedData['avatarPath']!).existsSync();

    return BlocListener<CustomerCubit, CustomerState>(
      listener: (context, state) {
        if (state is CustomerLoading) {
          if (_isSubmitting) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => const Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
        } else if (state is CustomerLoaded) {
          // Check if we are currently showing a loading dialog
          if (_isSubmitting && Navigator.of(context).canPop()) {
            Navigator.of(context).pop(); // Close Dialog
          }

          if (_isSubmitting) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Xử lý thành công!')));
            Navigator.of(context).pop(true); // Close Page
          }
        } else if (state is CustomerError) {
          if (_isSubmitting) {
            // Only handle error if we were submitting
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop(); // Close Dialog
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
            setState(() => _isSubmitting = false); // Reset
          }
        }
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          children: [
            // --- AVATAR SECTION ---
            Center(
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey[200],
                          // Ưu tiên hiển thị ảnh cắt, sau đó đến ảnh gốc
                          backgroundImage: hasCroppedAvatar
                              ? FileImage(
                                  File(widget.scannedData['avatarPath']!))
                              : (File(widget.frontImagePath).existsSync()
                                  ? FileImage(File(widget.frontImagePath))
                                  : null),
                          child: (!hasCroppedAvatar &&
                                  !File(widget.frontImagePath).existsSync())
                              ? const Icon(Icons.person,
                                  size: 60, color: Colors.grey)
                              : null,
                        ),
                      ),
                      Positioned(
                        bottom: 5,
                        right: 5,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _nameCtrl.text.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'KHÁCH HÀNG THÂN THIẾT',
                      style: TextStyle(
                        color: AppColors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // --- LOCATION SELECTION ---
            // [DEMO MODE] Hide logic moved to validation check.
            // Hide UI if Demo or standard logic
            if (!_isLoadingLocations &&
                _locations.isNotEmpty &&
                !di.sl<AuthService>().isDemoMode()) ...[
              _buildLabel('Chi nhánh quản lý'),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedLocationId,
                    isExpanded: true,
                    hint: const Text("Chọn chi nhánh"),
                    icon: const Icon(Icons.store, color: AppColors.red),
                    items: _locations.map((loc) {
                      return DropdownMenuItem(
                        value: loc.id,
                        child: Text(
                          loc.name,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      );
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _selectedLocationId = v);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // --- FORM FIELDS ---
            _buildLabel('Họ và tên'),
            _buildTextField(
              controller: _nameCtrl,
              icon: Icons.person,
              inputFormatters: [UpperCaseTextFormatter()],
            ),
            const SizedBox(height: 16),

            _buildLabel(widget.scannedData['type'] == 'PASSPORT'
                ? 'Số Hộ chiếu'
                : 'Số CCCD'),
            _buildTextField(
                controller: _cccdCtrl,
                icon: Icons.fingerprint,
                isVerified: true),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      _buildLabel('Ngày sinh'),
                      _buildDateField(
                          // [MODIFIED]
                          value: _formatDate(_dob),
                          icon: Icons.cake,
                          onTap: () => _selectDate(
                              context, _dob, (date) => _dob = date)),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      _buildLabel('Giới tính'),
                      _buildDropdownField(),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildLabel('Quốc tịch'),
            _buildTextField(controller: _nationalityCtrl, icon: Icons.public),
            const SizedBox(height: 16),

            _buildLabel('Quê quán'),
            _buildTextField(
                controller: _originCtrl,
                icon: Icons.home_work_outlined,
                maxLines: 3),
            const SizedBox(height: 16),

            _buildLabel('Nơi thường trú'),
            _buildTextField(
                controller: _residenceCtrl,
                icon: Icons.location_on_outlined,
                maxLines: 3),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      _buildLabel('Ngày cấp'),
                      _buildDateField(
                          // [MODIFIED]
                          value: _formatDate(_issueDate),
                          icon: Icons.date_range,
                          onTap: () => _selectDate(context, _issueDate,
                              (date) => _issueDate = date)),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      _buildLabel('Có giá trị đến'),
                      _buildDateField(
                          // [MODIFIED]
                          value: _formatDate(_expiryDate),
                          icon: Icons.event_busy,
                          onTap: () => _selectDate(context, _expiryDate,
                              (date) => _expiryDate = date)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // --- ACTION BUTTONS ---
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  // --- VALIDATION START ---
                  final isDemo = di.sl<AuthService>().isDemoMode();

                  // 1. Check Location
                  // [DEMO_CHANGE] Tắt logic kiểm tra chi nhánh nếu là Demo
                  if (!isDemo && _selectedLocationId == null) {
                    _showMessage(
                        "Vui lòng chọn Chi nhánh quản lý!", AppColors.red);
                    return;
                  }

                  // 2. Check Name
                  final name = _nameCtrl.text.trim();
                  if (name.isEmpty) {
                    _showMessage("Vui lòng nhập Họ và tên!", AppColors.red);
                    return;
                  }
                  if (name.length < 2) {
                    _showMessage("Họ tên quá ngắn!", AppColors.red);
                    return;
                  }

                  // 3. Check CCCD / Passport
                  final cccd = _cccdCtrl.text.trim();
                  if (cccd.isEmpty) {
                    _showMessage(
                        "Vui lòng nhập Số CCCD/Hộ chiếu!", AppColors.red);
                    return;
                  }

                  final isPassport = widget.scannedData['type'] == 'PASSPORT';

                  if (isPassport) {
                    // Passport: Có thể có chữ và số, độ dài >= 6
                    if (cccd.length < 6) {
                      _showMessage("Số Hộ chiếu phải có ít nhất 6 ký tự!",
                          AppColors.red);
                      return;
                    }
                  } else {
                    // CCCD: Chỉ số, 9 hoặc 12 số
                    if (!RegExp(r'^\d+$').hasMatch(cccd)) {
                      _showMessage(
                          "Số CCCD chỉ được chứa chữ số!", AppColors.red);
                      return;
                    }
                    if (cccd.length != 9 && cccd.length != 12) {
                      _showMessage(
                          "Số CCCD phải có 9 hoặc 12 chữ số!", AppColors.red);
                      return;
                    }
                  }

                  // 4. Check Dates
                  final now = DateTime.now();

                  // Tuổi (Ví dụ: Phải >= 14 hoặc 15 tuổi để làm CCCD)
                  final age = now.year - _dob.year;
                  if (age < 14) {
                    _showMessage(
                        "Người lao động/Khách hàng phải từ 14 tuổi trở lên!",
                        AppColors.red);
                    return;
                  }

                  if (_issueDate.isAfter(now)) {
                    _showMessage(
                        "Ngày cấp không hợp lệ (Tương lai)!", AppColors.red);
                    return;
                  }

                  if (_expiryDate.isBefore(_issueDate)) {
                    _showMessage(
                        "Ngày hết hạn phải sau Ngày cấp!", AppColors.red);
                    return;
                  }

                  if (_expiryDate.isBefore(now)) {
                    // Cảnh báo nhưng vẫn cho phép (chỉ nhắc nhở)
                    // Hoặc chặn luôn tuỳ nghiệp vụ. Ở đây chỉ show warning toast nếu cần, hoặc bỏ qua.
                    // _showMessage("Cảnh báo: CCCD đã hết hạn!", Colors.orange);
                  }

                  // 5. Check Hometown / Residence (Optional but recommended)
                  if (_originCtrl.text.trim().isEmpty) {
                    _showMessage("Vui lòng nhập Quê quán!", AppColors.red);
                    return;
                  }

                  // --- VALIDATION END ---

                  if (mounted) setState(() => _isSubmitting = true);

                  final cubit = context.read<CustomerCubit>();
                  final customerId = widget.scannedData['customerId'];
                  final bool isEditing =
                      customerId != null && customerId.isNotEmpty;

                  final newCustomer = Customer(
                    id: isEditing
                        ? customerId
                        : DateTime.now().millisecondsSinceEpoch.toString(),
                    name: name, // Was trimmed above
                    identityNumber: cccd, // Was trimmed above
                    dob: _dob,
                    gender: _gender,
                    nationality: _nationalityCtrl.text.trim(),
                    hometown: _originCtrl.text.trim(),
                    address: _residenceCtrl.text.trim(),
                    issueDate: _issueDate,
                    expiryDate: _expiryDate,
                    avatarPath: widget.scannedData['avatarPath'] ??
                        widget.frontImagePath,
                    frontImagePath: widget.frontImagePath,
                    backImagePath: widget.backImagePath,
                    code: isEditing
                        ? (widget.scannedData['code'] ??
                            "KH${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}")
                        : "KH${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}",
                    phone: widget.scannedData[
                        'phone'], // Preserve phone if available (though not edited here yet)
                    groupId: widget.scannedData[
                        'groupId'], // If creating from CCCD, this is likely null. We handle it in Repo.
                    locationId: _selectedLocationId, // Pass selected location
                  );

                  if (isEditing) {
                    // The BlocListener handles the UI now
                    cubit.updateCustomer(newCustomer);
                  } else {
                    // Check Duplicate First
                    // Only check by CCCD/identity number to avoid false positives by name
                    final exists = await cubit.checkCustomerExists(
                        newCustomer.identityNumber ?? '', '', '');
                    if (exists && context.mounted) {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text("Khách hàng đã tồn tại"),
                          content: const Text(
                              "Số CCCD này đã có trong hệ thống (hoặc tìm thấy Trùng Tên). Bạn có muốn tạo mới không?"),
                          actions: [
                            TextButton(
                              onPressed: () {
                                setState(() => _isSubmitting = false);
                                Navigator.of(ctx).pop();
                              },
                              child: const Text("Hủy"),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(ctx).pop();
                                cubit.addCustomer(newCustomer);
                              },
                              child: const Text("Vẫn tạo",
                                  style: TextStyle(color: AppColors.red)),
                            ),
                          ],
                        ),
                      );
                    } else {
                      cubit.addCustomer(newCustomer);
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Lưu thông tin',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext ctx) {
                      return AlertDialog(
                        title: const Text("Xác nhận"),
                        content: const Text(
                            "Bạn có chắc chắn muốn xóa khách hàng này không?"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text("Hủy",
                                style: TextStyle(color: Colors.grey)),
                          ),
                          TextButton(
                            onPressed: () {
                              final customerId =
                                  widget.scannedData['customerId'];
                              if (customerId == null || customerId.isEmpty) {
                                Navigator.of(ctx).pop(); // Close Dialog
                                Navigator.of(context).pop(true); // Exit Page
                                return;
                              }

                              Navigator.of(ctx).pop(); // Close Dialog

                              // [FIX] Update flag to let BlocListener know we are performing an action
                              if (mounted) setState(() => _isSubmitting = true);

                              // Call Delete
                              context
                                  .read<CustomerCubit>()
                                  .deleteCustomer(customerId);
                            },
                            child: const Text("Xóa",
                                style: TextStyle(color: AppColors.red)),
                          ),
                        ],
                      );
                    },
                  );
                },
                icon: const Icon(Icons.delete_outline, color: AppColors.red),
                label: const Text(
                  'Xóa khách hàng',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.red,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.red),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            text,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required IconData icon,
    bool isVerified = false,
    int maxLines = 1,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment:
            maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.only(top: maxLines > 1 ? 12 : 0),
            child: Icon(icon, color: Colors.grey, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: maxLines,
              inputFormatters: inputFormatters,
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ),
          if (isVerified)
            Padding(
              padding: EdgeInsets.only(top: maxLines > 1 ? 12 : 0),
              child:
                  const Icon(Icons.check_circle, color: Colors.green, size: 20),
            ),
        ],
      ),
    );
  }

  // [MODIFIED] Added onTap
  Widget _buildDateField(
      {required String value, required IconData icon, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(fontSize: 16, color: Colors.black87),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _gender,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
          items: const [
            DropdownMenuItem(value: 'Nam', child: Text('Nam')),
            DropdownMenuItem(value: 'Nữ', child: Text('Nữ')),
          ],
          onChanged: (v) {
            if (v != null) setState(() => _gender = v);
          },
        ),
      ),
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    // 1. Remove diacritics
    String cleanText = StringUtils.removeDiacritics(newValue.text);
    // 2. Uppercase
    cleanText = cleanText.toUpperCase();

    return TextEditingValue(
      text: cleanText,
      selection: newValue.selection,
    );
  }
}
