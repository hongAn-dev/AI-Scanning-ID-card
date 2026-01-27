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

class PassportInputForm extends StatefulWidget {
  final String frontImagePath;
  final String? backImagePath;
  final Map<String, dynamic> scannedData;

  const PassportInputForm({
    super.key,
    required this.frontImagePath,
    this.backImagePath,
    this.scannedData = const {},
  });

  @override
  State<PassportInputForm> createState() => _PassportInputFormState();
}

class _PassportInputFormState extends State<PassportInputForm> {
  // Controllers
  late TextEditingController _nameCtrl;
  late TextEditingController _passportNumCtrl;
  late TextEditingController _nationalityCtrl;
  late TextEditingController _pobCtrl; // Place of Birth (Nơi sinh)
  late TextEditingController _placeOfIssueCtrl; // Nơi cấp / Authority

  DateTime _dob = DateTime.now();
  DateTime _issueDate = DateTime.now();
  DateTime _expiryDate = DateTime.now();

  String _gender = 'Nam';
  String? _selectedLocationId;
  List<CustomerGroup> _locations = [];
  bool _isLoadingLocations = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _loadLocations();
  }

  void _initializeData() {
    final data = widget.scannedData;
    // Helper to find key case-insensitively
    String? getValue(List<String> keys) {
      for (var k in keys) {
        if (data.containsKey(k) &&
            data[k] != null &&
            data[k].toString().isNotEmpty) {
          return data[k].toString();
        }
        // Also check lowercase version in case data was normalized
        if (data.containsKey(k.toLowerCase()) &&
            data[k.toLowerCase()] != null) {
          return data[k.toLowerCase()].toString();
        }
      }
      return null;
    }

    _nameCtrl = TextEditingController(
        text:
            StringUtils.removeDiacritics(getValue(['name', 'full_name']) ?? '')
                .toUpperCase());

    _passportNumCtrl = TextEditingController(
        text: getValue(['id', 'passport_number', 'passportNumber']) ?? '');

    _nationalityCtrl = TextEditingController(
        text: getValue(['nationality', 'nat']) ?? 'Việt Nam');

    _pobCtrl = TextEditingController(
        text: getValue(['hometown', 'pob', 'place_of_birth']) ?? '');

    _placeOfIssueCtrl = TextEditingController(
        text: getValue(['residence', 'place_of_issue', 'authority']) ?? '');

    _dob = _parseDate(getValue(['dob', 'birth_date']));

    // [FIX] Robust Issue Date Parsing
    _issueDate = _parseDate(
        getValue(['issueDate', 'issuedate', 'date_of_issue', 'doi']));

    _expiryDate = _parseDate(getValue(['expiry', 'expiration_date', 'doe']));

    // Gender Logic
    String sexRaw = (getValue(['sex', 'gender']) ?? 'Nam').toLowerCase();
    if (sexRaw.contains('nam') || sexRaw.contains('male') || sexRaw == 'm') {
      _gender = 'Nam';
    } else {
      _gender = 'Nữ';
    }
  }

  DateTime _parseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return DateTime.now();
    try {
      // Try standard dd/MM/yyyy
      return DateFormat('dd/MM/yyyy')
          .parse(dateStr.replaceAll('-', '/').trim());
    } catch (_) {
      try {
        // Try MM/dd/yyyy just in case
        return DateFormat('MM/dd/yyyy').parse(dateStr.replaceAll('-', '/'));
      } catch (e) {
        return DateTime.now();
      }
    }
  }

  Future<void> _loadLocations() async {
    setState(() => _isLoadingLocations = true);
    try {
      final customerRepo = di.sl<CustomerRepository>();
      final groups = await customerRepo.getCustomerGroups();
      final prefs = await SharedPreferences.getInstance();
      final currentLocationId = prefs.getString('location_id');

      if (mounted) {
        setState(() {
          _locations = groups;
          if (currentLocationId != null &&
              groups.any((g) => g.id == currentLocationId)) {
            _selectedLocationId = currentLocationId;
          } else if (groups.isNotEmpty) {
            _selectedLocationId = groups.first.id;
          }
        });
      }
    } catch (e) {
      debugPrint("Error loading locations: $e");
    } finally {
      if (mounted) setState(() => _isLoadingLocations = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _passportNumCtrl.dispose();
    _nationalityCtrl.dispose();
    _pobCtrl.dispose();
    _placeOfIssueCtrl.dispose();
    super.dispose();
  }

  // --- UI BUILDERS ---

  @override
  Widget build(BuildContext context) {
    return BlocListener<CustomerCubit, CustomerState>(
      listener: (context, state) {
        if (state is CustomerLoading && _isSubmitting) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) =>
                const Center(child: CircularProgressIndicator()),
          );
        } else if (state is CustomerLoaded && _isSubmitting) {
          if (Navigator.of(context).canPop())
            Navigator.of(context).pop(); // Close Loading
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Lưu Hộ chiếu thành công!')));
          Navigator.of(context).pop(true); // Close Page
        } else if (state is CustomerError && _isSubmitting) {
          if (Navigator.of(context).canPop())
            Navigator.of(context).pop(); // Close Loading
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(state.message), backgroundColor: Colors.red));
          setState(() => _isSubmitting = false);
        }
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AVATAR
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: File(widget.frontImagePath).existsSync()
                        ? FileImage(File(widget.frontImagePath))
                        : null,
                    child: !File(widget.frontImagePath).existsSync()
                        ? const Icon(Icons.person, size: 60, color: Colors.grey)
                        : null,
                  ),
                  const CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.green,
                    child: Icon(Icons.check, color: Colors.white, size: 18),
                  )
                ],
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                _nameCtrl.text.isNotEmpty ? _nameCtrl.text : 'NO NAME',
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text("HỘ CHIẾU (PASSPORT)",
                    style: TextStyle(
                        color: AppColors.primary, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 30),

            // FORM FIELDS
            _buildLabel('Chi nhánh quản lý'),
            _buildLocationDropdown(),
            const SizedBox(height: 16),

            _buildLabel('Họ và tên'),
            _buildTextField(
              controller: _nameCtrl,
              icon: Icons.person,
              inputFormatters: [UpperCaseTextFormatter()],
            ),
            const SizedBox(height: 16),

            _buildLabel('Số Hộ chiếu'),
            _buildTextField(
                controller: _passportNumCtrl,
                icon: Icons.book,
                isVerified: true),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      _buildLabel('Ngày sinh'),
                      _buildDateField(
                          value: _formatDate(_dob),
                          icon: Icons.cake,
                          onTap: () =>
                              _selectDate(context, _dob, (d) => _dob = d)),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      _buildLabel('Giới tính'),
                      _buildGenderDropdown(),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildLabel('Quốc tịch'),
            _buildTextField(controller: _nationalityCtrl, icon: Icons.public),
            const SizedBox(height: 16),

            _buildLabel('Nơi sinh (Place of Birth)'),
            _buildTextField(controller: _pobCtrl, icon: Icons.location_city),
            const SizedBox(height: 16),

            _buildLabel('Nơi cấp / Authority'),
            _buildTextField(
                controller: _placeOfIssueCtrl, icon: Icons.account_balance),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      _buildLabel('Ngày cấp'),
                      _buildDateField(
                          value: _formatDate(_issueDate),
                          icon: Icons.date_range,
                          onTap: () => _selectDate(
                              context, _issueDate, (d) => _issueDate = d)),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      _buildLabel('Có giá trị đến'),
                      _buildDateField(
                          value: _formatDate(_expiryDate),
                          icon: Icons.event_busy,
                          onTap: () => _selectDate(
                              context, _expiryDate, (d) => _expiryDate = d)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                onPressed: _onSave,
                child: const Text("Lưu thông tin",
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _onSave() {
    final name = _nameCtrl.text.trim();
    final passportNum = _passportNumCtrl.text.trim();

    if (name.isEmpty) return _showMessage("Vui lòng nhập họ tên", Colors.red);
    if (passportNum.isEmpty)
      return _showMessage("Vui lòng nhập Số Hộ chúêu", Colors.red);
    if (passportNum.length < 6)
      return _showMessage("Số Hộ chiếu không hợp lệ", Colors.red);

    setState(() => _isSubmitting = true);

    final cubit = context.read<CustomerCubit>();
    final newCustomer = Customer(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      identityNumber: passportNum,
      dob: _dob,
      gender: _gender,
      nationality: _nationalityCtrl.text.trim(),
      hometown: _pobCtrl.text.trim(),
      address: _placeOfIssueCtrl.text
          .trim(), // Use Address field for Authority/Place of Issue
      issueDate: _issueDate,
      expiryDate: _expiryDate,
      frontImagePath: widget.frontImagePath,
      backImagePath: widget.backImagePath,
      code:
          "KH${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}",
      locationId: _selectedLocationId,
    );

    // Check duplicates by Passport Number
    cubit.checkCustomerExists(passportNum, '', '').then((exists) {
      if (exists && mounted) {
        showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
                  title: const Text("Đã tồn tại"),
                  content:
                      Text("Số Hộ chiếu $passportNum đã tồn tại. Tạo mới?"),
                  actions: [
                    TextButton(
                        onPressed: () {
                          setState(() => _isSubmitting = false);
                          Navigator.pop(ctx);
                        },
                        child: const Text("Hủy")),
                    TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          cubit.addCustomer(newCustomer);
                        },
                        child: const Text("Tiếp tục")),
                  ],
                ));
      } else {
        cubit.addCustomer(newCustomer);
      }
    });
  }

  // --- HELPERS ---
  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  void _showMessage(String msg, Color color) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  Widget _buildLabel(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text,
          style:
              TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500)));

  Widget _buildTextField(
      {required TextEditingController controller,
      required IconData icon,
      bool isVerified = false,
      List<TextInputFormatter>? inputFormatters}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12)),
      child: TextField(
        controller: controller,
        inputFormatters: inputFormatters,
        decoration: InputDecoration(
          border: InputBorder.none,
          icon: Icon(icon, color: Colors.grey),
          suffixIcon: isVerified
              ? const Icon(Icons.check_circle, color: Colors.green)
              : null,
        ),
      ),
    );
  }

  Widget _buildDateField(
      {required String value, required IconData icon, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          Icon(icon, color: Colors.grey),
          const SizedBox(width: 8),
          Text(value)
        ]),
      ),
    );
  }

  Widget _buildLocationDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: _selectedLocationId,
          hint: _isLoadingLocations
              ? const Text("Đang tải...")
              : const Text("Chọn chi nhánh"),
          items: _locations
              .map((e) => DropdownMenuItem(value: e.id, child: Text(e.name)))
              .toList(),
          onChanged: (v) => setState(() => _selectedLocationId = v),
        ),
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: _gender,
          items: const [
            DropdownMenuItem(value: 'Nam', child: Text('Nam')),
            DropdownMenuItem(value: 'Nữ', child: Text('Nữ'))
          ],
          onChanged: (v) => setState(() => _gender = v!),
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, DateTime initial,
      Function(DateTime) onPicked) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      locale: const Locale('vi', 'VN'),
    );
    if (picked != null) setState(() => onPicked(picked));
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
        text: StringUtils.removeDiacritics(newValue.text).toUpperCase(),
        selection: newValue.selection);
  }
}
