import 'package:equatable/equatable.dart';

class UserAccount extends Equatable {
  final String userName;
  final String displayName;
  final String email;
  final bool isSystemAccount;
  final String avatar;
  final String companyTel1;
  final String companyTel2;
  final String employeeId;

  const UserAccount({
    required this.userName,
    required this.displayName,
    required this.email,
    required this.isSystemAccount,
    required this.avatar,
    required this.companyTel1,
    required this.companyTel2,
    required this.employeeId,
  });

  @override
  List<Object?> get props => [
        userName,
        displayName,
        email,
        isSystemAccount,
        avatar,
        companyTel1,
        companyTel2,
        employeeId,
      ];
}
