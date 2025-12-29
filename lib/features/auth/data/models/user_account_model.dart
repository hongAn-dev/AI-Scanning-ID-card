import 'dart:convert';

import '../../domain/entities/user_account.dart';

class UserAccountModel extends UserAccount {
  const UserAccountModel({
    required super.userName,
    required super.displayName,
    required super.email,
    required super.isSystemAccount,
    required super.avatar,
    required super.companyTel1,
    required super.companyTel2,
    required super.employeeId,
  });

  // From JSON (API Response)
  factory UserAccountModel.fromJson(Map<String, dynamic> json) {
    return UserAccountModel(
      userName: json['UserName'] ?? '',
      displayName: json['DisplayName'] ?? '',
      email: json['Email'] ?? '',
      isSystemAccount: json['IsSystemAccount'] ?? false,
      avatar: json['Avatar'] ?? '',
      companyTel1: json['Company_Tel1'] ?? '',
      companyTel2: json['Company_Tel2'] ?? '',
      employeeId: json['EmployeeId'] ?? '',
    );
  }

  // To JSON (for SharedPreferences)
  Map<String, dynamic> toJson() {
    return {
      'UserName': userName,
      'DisplayName': displayName,
      'Email': email,
      'IsSystemAccount': isSystemAccount,
      'Avatar': avatar,
      'Company_Tel1': companyTel1,
      'Company_Tel2': companyTel2,
      'EmployeeId': employeeId,
    };
  }

  // To Entity
  UserAccount toEntity() {
    return UserAccount(
      userName: userName,
      displayName: displayName,
      email: email,
      isSystemAccount: isSystemAccount,
      avatar: avatar,
      companyTel1: companyTel1,
      companyTel2: companyTel2,
      employeeId: employeeId,
    );
  }

  // From SharedPreferences string
  factory UserAccountModel.fromJsonString(String jsonString) {
    return UserAccountModel.fromJson(json.decode(jsonString));
  }

  // To SharedPreferences string
  String toJsonString() {
    return json.encode(toJson());
  }
}
