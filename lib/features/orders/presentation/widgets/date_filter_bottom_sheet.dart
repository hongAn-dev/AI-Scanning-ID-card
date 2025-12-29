import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum DateFilterType {
  today('Hôm nay'),
  yesterday('Hôm qua'),
  thisWeek('Tuần này'),
  thisMonth('Tháng này'),
  lastMonth('Tháng trước'),
  custom('Tuỳ chỉnh');

  final String displayName;
  const DateFilterType(this.displayName);
}

class DateFilterResult {
  final DateFilterType type;
  final DateTime fromDate;
  final DateTime toDate;

  DateFilterResult({
    required this.type,
    required this.fromDate,
    required this.toDate,
  });

  String get displayText {
    final dateFormat = DateFormat('dd/MM/yyyy');
    if (type == DateFilterType.custom) {
      return '${dateFormat.format(fromDate)} - ${dateFormat.format(toDate)}';
    }
    return type.displayName;
  }
}

class DateFilterBottomSheet extends StatefulWidget {
  final DateFilterResult? currentFilter;

  const DateFilterBottomSheet({
    super.key,
    this.currentFilter,
  });

  @override
  State<DateFilterBottomSheet> createState() => _DateFilterBottomSheetState();
}

class _DateFilterBottomSheetState extends State<DateFilterBottomSheet> {
  DateFilterType? _selectedType;
  DateTime? _customFromDate;
  DateTime? _customToDate;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.currentFilter?.type;
    if (_selectedType == DateFilterType.custom) {
      _customFromDate = widget.currentFilter?.fromDate;
      _customToDate = widget.currentFilter?.toDate;
    }
  }

  DateFilterResult _calculateDateRange(DateFilterType type) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (type) {
      case DateFilterType.today:
        return DateFilterResult(
          type: type,
          fromDate: today,
          toDate: today
              .add(const Duration(days: 1))
              .subtract(const Duration(seconds: 1)),
        );

      case DateFilterType.yesterday:
        final yesterday = today.subtract(const Duration(days: 1));
        return DateFilterResult(
          type: type,
          fromDate: yesterday,
          toDate: yesterday
              .add(const Duration(days: 1))
              .subtract(const Duration(seconds: 1)),
        );

      case DateFilterType.thisWeek:
        final weekday = now.weekday;
        final startOfWeek = today.subtract(Duration(days: weekday - 1));
        final endOfWeek = startOfWeek
            .add(const Duration(days: 7))
            .subtract(const Duration(seconds: 1));
        return DateFilterResult(
          type: type,
          fromDate: startOfWeek,
          toDate: endOfWeek,
        );

      case DateFilterType.thisMonth:
        final startOfMonth = DateTime(now.year, now.month, 1);
        final endOfMonth = DateTime(now.year, now.month + 1, 1)
            .subtract(const Duration(seconds: 1));
        return DateFilterResult(
          type: type,
          fromDate: startOfMonth,
          toDate: endOfMonth,
        );

      case DateFilterType.lastMonth:
        final startOfLastMonth = DateTime(now.year, now.month - 1, 1);
        final endOfLastMonth = DateTime(now.year, now.month, 1)
            .subtract(const Duration(seconds: 1));
        return DateFilterResult(
          type: type,
          fromDate: startOfLastMonth,
          toDate: endOfLastMonth,
        );

      case DateFilterType.custom:
        return DateFilterResult(
          type: type,
          fromDate: _customFromDate ?? today,
          toDate: _customToDate ?? today,
        );
    }
  }

  Future<void> _pickDate(bool isFromDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isFromDate
          ? (_customFromDate ?? DateTime.now())
          : (_customToDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.red,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isFromDate) {
          _customFromDate = picked;
          // Nếu fromDate > toDate, tự động set toDate = fromDate
          if (_customToDate != null &&
              _customFromDate!.isAfter(_customToDate!)) {
            _customToDate = _customFromDate;
          }
        } else {
          _customToDate = picked;
          // Nếu toDate < fromDate, tự động set fromDate = toDate
          if (_customFromDate != null &&
              _customToDate!.isBefore(_customFromDate!)) {
            _customFromDate = _customToDate;
          }
        }
      });
    }
  }

  void _applyFilter() {
    if (_selectedType == null) {
      return;
    }

    if (_selectedType == DateFilterType.custom) {
      if (_customFromDate == null || _customToDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng chọn ngày bắt đầu và ngày kết thúc'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }

    final result = _calculateDateRange(_selectedType!);
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Lọc theo ngày',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          const Divider(),

          // Filter options
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              children: [
                // Quick filters
                ...DateFilterType.values
                    .where((type) => type != DateFilterType.custom)
                    .map(
                      (type) => _buildFilterOption(type),
                    ),

                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 8),

                // Custom date range
                _buildCustomDateOption(),

                if (_selectedType == DateFilterType.custom) ...[
                  const SizedBox(height: 16),
                  _buildDatePickerRow(),
                ],

                const SizedBox(height: 24),

                // Apply button
                ElevatedButton(
                  onPressed: _selectedType != null ? _applyFilter : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text(
                    'Áp dụng',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterOption(DateFilterType type) {
    final isSelected = _selectedType == type;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedType = type;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Colors.red : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? Colors.red.withOpacity(0.1) : null,
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isSelected ? Colors.red : Colors.grey,
            ),
            const SizedBox(width: 12),
            Text(
              type.displayName,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? Colors.red : Colors.red[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomDateOption() {
    final isSelected = _selectedType == DateFilterType.custom;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedType = DateFilterType.custom;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Colors.red : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? Colors.red.withOpacity(0.1) : null,
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isSelected ? Colors.red : Colors.grey,
            ),
            const SizedBox(width: 12),
            Text(
              DateFilterType.custom.displayName,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? Colors.red : Colors.red[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePickerRow() {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Column(
      children: [
        // From Date
        InkWell(
          onTap: () => _pickDate(true),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  color: Colors.red,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Từ ngày',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _customFromDate != null
                            ? dateFormat.format(_customFromDate!)
                            : 'Chọn ngày bắt đầu',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: _customFromDate != null
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 16),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // To Date
        InkWell(
          onTap: () => _pickDate(false),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  color: Colors.red,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Đến ngày',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _customToDate != null
                            ? dateFormat.format(_customToDate!)
                            : 'Chọn ngày kết thúc',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: _customToDate != null
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
