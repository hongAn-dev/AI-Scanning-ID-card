import 'package:flutter/material.dart';
import '../widgets/cccd_input_form.dart';

class CccdDetailsPage extends StatelessWidget {
  final String frontImagePath;
  final String backImagePath;
  final Map<String, dynamic> scannedData;

  const CccdDetailsPage({
    super.key,
    required this.frontImagePath,
    required this.backImagePath,
    this.scannedData = const {},
  });

  @override
  Widget build(BuildContext context) {
    // Determine Mode for Title
    bool isAddNew = scannedData.isEmpty ||
        (scannedData['id'] == null && scannedData['customerId'] == null);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          isAddNew ? 'Thêm khách hàng mới' : 'Chi tiết khách hàng',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: CccdInputForm(
        frontImagePath: frontImagePath,
        backImagePath: backImagePath,
        scannedData: scannedData,
      ),
    );
  }
}
