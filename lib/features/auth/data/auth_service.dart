import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../domain/entities/user_account.dart';
import 'models/user_account_model.dart';

class AuthService {
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyCustomerCode = 'customer_code';
  static const String _keyUsername = 'username';
  static const String _keyPassword = 'password';
  static const String _keyRememberMe = 'remember_me';
  static const String _keyAccessToken = 'access_token';
  static const String _keyUserAccount = 'user_account';
  static const String _keyLocationId = 'location_id';
  static const String _keyLocationName = 'location_name';

  final SharedPreferences _prefs;
  final DioClient _dioClient;

  AuthService(this._prefs, this._dioClient);

  // Login with API
  Future<bool> login({
    required String customerCode,
    required String username,
    required String password,
    required bool rememberMe,
  }) async {
    // Validate input
    if (customerCode.isEmpty || username.isEmpty || password.isEmpty) {
      return false;
    }

    try {
      print('🚀 Logging in with: CustomerCode=$customerCode, User=$username');
      final response = await _dioClient.post(
        '${ApiConstants.baseUrl}${ApiConstants.loginEndpoint}',
        data: {
          'UserName': username,
          'Password': password,
          'TenantCode': customerCode,
          'TenantId': 0,
          'Language': 'en',
          'IdChannel':
              'eyJhbGciOiJIUzI1NiJ9.eyJwYWNrYWdlbmFtZSI6Im1hc3RlcnByby5jdXN0b21lcl9hZGQifQ.hO_lurH-dRcESYrvbDdpUAZ9kM-dhJC3XEMv1eWN7qw',
        },
      );

      print('✅ Login Response Code: ${response.statusCode}');
      print('Response Data: ${response.data}');

      // Check if login successful
      if (response.statusCode == 200 && response.data != null) {
        final meta = response.data['meta'];
        final data = response.data['data'];

        // Check status code from meta (0 = success)
        if (meta != null && meta['status_code'] == 0 && data != null) {
          // Save access token from data.token
          final token = data['token'];
          if (token != null && token.isNotEmpty) {
            await _prefs.setString(_keyAccessToken, token);
          }

          // Save Account information as User model
          final account =
              data['Acount']; // Note: API uses 'Acount' (typo in API)
          if (account != null) {
            final userAccountModel = UserAccountModel.fromJson(account);
            await _prefs.setString(
                _keyUserAccount, userAccountModel.toJsonString());
            print('👤 Logged In User Info: ${userAccountModel.toJsonString()}');
          }

          // Save login state
          await _prefs.setBool(_keyIsLoggedIn, true);

          if (rememberMe) {
            await _prefs.setString(_keyCustomerCode, customerCode);
            await _prefs.setString(_keyUsername, username);
            await _prefs.setString(_keyPassword, password);
            await _prefs.setBool(_keyRememberMe, true);
          } else {
            // Clear saved credentials if not remember
            await _prefs.remove(_keyCustomerCode);
            await _prefs.remove(_keyUsername);
            await _prefs.remove(_keyPassword);
            await _prefs.setBool(_keyRememberMe, false);
          }

          return true;
        } else {
          print('❌ Login failed: Meta status not 0 or data null. Meta: $meta');
        }
      } else {
        print('❌ Login failed: StatusCode ${response.statusCode}');
      }

      return false;
    } catch (e) {
      print('❌ Login error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    await _prefs.setBool(_keyIsLoggedIn, false);
    await _prefs.remove(_keyAccessToken);
    await _prefs.remove(_keyUserAccount);

    // Không xóa credentials nếu remember me
  }

  bool isLoggedIn() {
    return _prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  bool isRememberMe() {
    return _prefs.getBool(_keyRememberMe) ?? false;
  }

  String? getSavedCustomerCode() {
    return _prefs.getString(_keyCustomerCode);
  }

  String? getSavedUsername() {
    return _prefs.getString(_keyUsername);
  }

  String? getSavedPassword() {
    return _prefs.getString(_keyPassword);
  }

  String? getAccessToken() {
    return _prefs.getString(_keyAccessToken);
  }

  // Get user account as object
  UserAccount? getUserAccount() {
    final jsonString = _prefs.getString(_keyUserAccount);
    if (jsonString == null || jsonString.isEmpty) {
      return null;
    }

    try {
      final entity = UserAccountModel.fromJsonString(jsonString).toEntity();
      print("👤 Current User Info (Cached): $jsonString");
      return entity;
    } catch (e) {
      print('Error parsing user account: $e');
      return null;
    }
  }

  Future<void> saveLocationId(String id) async {
    await _prefs.setString(_keyLocationId, id);
  }

  String? getLocationId() {
    return _prefs.getString(_keyLocationId);
  }

  Future<void> saveLocationName(String name) async {
    await _prefs.setString(_keyLocationName, name);
  }

  String? getLocationName() {
    return _prefs.getString(_keyLocationName);
  }

  // Change password
  Future<Map<String, dynamic>> changePassword({
    required String newPassword,
  }) async {
    try {
      // Get saved credentials
      final username = getSavedUsername();
      final oldPassword = getSavedPassword();

      if (username == null || username.isEmpty) {
        return {
          'success': false,
          'message': 'Không tìm thấy thông tin đăng nhập',
        };
      }

      if (oldPassword == null || oldPassword.isEmpty) {
        return {
          'success': false,
          'message': 'Không tìm thấy mật khẩu cũ',
        };
      }

      // Call API change password
      final response = await _dioClient.post(
        '${ApiConstants.baseUrl}${ApiConstants.changePasswordEndpoint}',
        data: {
          'UserName': username,
          'NewPassword': newPassword,
          'OldPassword': oldPassword,
        },
      );

      // Check if change password successful
      if (response.statusCode == 200 && response.data != null) {
        final meta = response.data['meta'];

        // Check status code from meta (0 = success)
        if (meta != null && meta['status_code'] == 0) {
          // Update saved password if remember me is enabled
          if (isRememberMe()) {
            await _prefs.setString(_keyPassword, newPassword);
          }

          return {
            'success': true,
            'message': meta['message'] ?? 'Đổi mật khẩu thành công',
          };
        } else {
          return {
            'success': false,
            'message': meta?['message'] ?? 'Đổi mật khẩu thất bại',
          };
        }
      }

      return {
        'success': false,
        'message': 'Đổi mật khẩu thất bại',
      };
    } catch (e) {
      print('Change password error: $e');
      return {
        'success': false,
        'message': 'Có lỗi xảy ra: ${e.toString()}',
      };
    }
  }
}
