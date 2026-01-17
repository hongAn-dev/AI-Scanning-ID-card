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

  Customer copyWith({
    String? id,
    String? locationId,
    String? name,
    String? phone,
    String? code,
    String? gender,
    String? identityNumber,
    String? address,
    String? hometown,
    DateTime? dob,
    DateTime? issueDate,
    DateTime? expiryDate,
    String? avatarPath,
    String? frontImagePath,
    String? backImagePath,
    String? nationality,
    String? groupId,
  }) {
    return Customer(
      id: id ?? this.id,
      locationId: locationId ?? this.locationId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      code: code ?? this.code,
      gender: gender ?? this.gender,
      identityNumber: identityNumber ?? this.identityNumber,
      address: address ?? this.address,
      hometown: hometown ?? this.hometown,
      dob: dob ?? this.dob,
      issueDate: issueDate ?? this.issueDate,
      expiryDate: expiryDate ?? this.expiryDate,
      avatarPath: avatarPath ?? this.avatarPath,
      frontImagePath: frontImagePath ?? this.frontImagePath,
      backImagePath: backImagePath ?? this.backImagePath,
      nationality: nationality ?? this.nationality,
      groupId: groupId ?? this.groupId,
    );
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['customerId'] ?? map['id'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'],
      code: map['code'],
      gender: map['sex'],
      identityNumber: map['id'], // 'id' in map is identityNumber based on toMap
      address: map['residence'],
      hometown: map['hometown'],
      dob: map['dob'] != null ? _parseDate(map['dob']) : null,
      issueDate: map['issueDate'] != null ? _parseDate(map['issueDate']) : null,
      expiryDate: map['expiry'] != null ? _parseDate(map['expiry']) : null,
      avatarPath: map['avatarPath'],
      nationality: map['nationality'],
    );
  }

  static DateTime? _parseDate(String dateStr) {
    try {
      final parts = dateStr.split('/');
      if (parts.length == 3) {
        return DateTime(
            int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
      }
      return DateTime.tryParse(dateStr);
    } catch (_) {
      return null;
    }
  }

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
