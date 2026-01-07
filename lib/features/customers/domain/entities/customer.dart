class Customer {
  final String id;
  final String? locationId; // Added locationId
  final String name;
  final String? phone;
  final String? code;
  final String? gender;
  final String? identityNumber; // CCCD
  final String? address; // Thuong tru
  final String? hometown; // Que quan
  final DateTime? dob;
  final DateTime? issueDate;
  final DateTime? expiryDate;
  final String? avatarPath;
  final String? frontImagePath;
  final String? backImagePath;
  final String? nationality;
  final String? groupId;

  Customer({
    required this.id,
    this.locationId, // Added locationId
    required this.name,
    this.phone,
    this.code,
    this.gender,
    this.identityNumber,
    this.address,
    this.hometown,
    this.dob,
    this.issueDate,
    this.expiryDate,
    this.avatarPath,
    this.frontImagePath,
    this.backImagePath,
    this.nationality,
    this.groupId,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'customerId': id, // Mapping for ScanCccdPage compatibility if needed
      'phone': phone,
      'code': code,
      'sex': gender,
      'id': identityNumber,
      'residence': address,
      'hometown': hometown,
      'dob': dob != null ? "${dob!.day}/${dob!.month}/${dob!.year}" : null,
      'issueDate': issueDate != null
          ? "${issueDate!.day}/${issueDate!.month}/${issueDate!.year}"
          : null,
      'expiry': expiryDate != null
          ? "${expiryDate!.day}/${expiryDate!.month}/${expiryDate!.year}"
          : null,
      'avatarPath': avatarPath,
      'nationality': nationality,
    };
  }
}
