import 'package:flutter/material.dart';
import '../widgets/passport_input_form.dart';

class PassportDetailsPage extends StatelessWidget {
  final String frontImagePath;
  final String? backImagePath;
  final Map<String, dynamic> scannedData;

  const PassportDetailsPage({
    super.key,
    required this.frontImagePath,
    this.backImagePath,
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
          // FORCE Return to Home to avoid loop
          onPressed: () =>
              Navigator.of(context).popUntil((route) => route.isFirst),
        ),
        title: Text(
          isAddNew ? 'Thêm Hộ chiếu mới' : 'Chi tiết Hộ chiếu',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: PassportInputForm(
        frontImagePath: frontImagePath,
        backImagePath: backImagePath,
        scannedData: scannedData,
      ),
    );
  }
}
