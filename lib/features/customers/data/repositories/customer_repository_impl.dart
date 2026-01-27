import 'package:shared_preferences/shared_preferences.dart';

import 'dart:convert';
import 'dart:io';
import '../../domain/entities/customer.dart';
import '../../domain/entities/customer_group.dart';
import '../../domain/repositories/customer_repository.dart';
import '../datasources/customer_local_data_source.dart';
import '../datasources/customer_remote_data_source.dart';
import '../../../../core/utils/string_utils.dart';

class CustomerRepositoryImpl implements CustomerRepository {
  final CustomerRemoteDataSourceImpl remoteDataSource;
  final CustomerLocalDataSourceImpl localDataSource;

  CustomerRepositoryImpl(
      {required this.remoteDataSource, required this.localDataSource});

  List<Customer> _demoCustomers = [];
  bool _isDemoDataLoaded = false;

  // Load demo data from Prefs (Persistence)
  Future<void> _ensureDemoDataLoaded() async {
    if (_isDemoDataLoaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('demo_customers_data');
      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        _demoCustomers = jsonList
            .map((e) => Customer.fromMap(e))
            .toList(); // Ensure Customer.fromMap exists
      } else {
        // Init default data
        _demoCustomers = [
          Customer(
            id: "DEMO001",
            code: "KH00001",
            name: "Nguyễn Văn Demo",
            phone: "0912345678",
            address: "Hà Nội, Việt Nam",
            identityNumber: "001202029221",
            gender: "Nam",
            dob: DateTime(1990, 1, 1),
          ),
          Customer(
            id: "DEMO002",
            code: "KH00002",
            name: "Trần Thị Test",
            phone: "0987654321",
            address: "TP. Hồ Chí Minh",
            identityNumber: "036198000000",
            gender: "Nữ",
            dob: DateTime(1995, 5, 15),
          ),
        ];
        _saveDemoCustomers();
      }
      _isDemoDataLoaded = true;
    } catch (e) {
      print("Error loading demo data: $e");
    }
  }

  Future<void> _saveDemoCustomers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _demoCustomers.map((e) => e.toMap()).toList();
      await prefs.setString('demo_customers_data', jsonEncode(jsonList));
    } catch (e) {
      print("Error saving demo data: $e");
    }
  }

  // We need to check async because SharedPreferences.getInstance is async
  // But our public methods are async so it's fine.
  Future<bool> _isDemoMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isDemo = prefs.getBool('is_demo') ?? false;
      final token = prefs.getString('access_token');

      print("🔍 [Checking Demo Mode] is_demo: $isDemo, token: $token");

      // Strict check
      if (isDemo) return true;
      if (token == "DEMO_TOKEN_123456") return true;

      return false;
    } catch (e) {
      print("Check demo mode failed: $e");
      return false;
    }
  }

  // --- LOCAL HELPERS ---
  Future<void> _localAdd(Customer customer) async {
    await _ensureDemoDataLoaded();
    print("🚀 Repository (Demo/Fallback): Adding customer locally.");
    await Future.delayed(const Duration(milliseconds: 300));
    final newCustomer =
        customer.copyWith(id: "DEMO${DateTime.now().millisecondsSinceEpoch}");
    _demoCustomers.insert(0, newCustomer);
    await _saveDemoCustomers();
  }

  Future<void> _localUpdate(Customer customer) async {
    await _ensureDemoDataLoaded();
    print("🚀 Repository (Demo/Fallback): Updating customer locally.");
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _demoCustomers.indexWhere((c) => c.id == customer.id);
    if (index != -1) {
      _demoCustomers[index] = customer;
      await _saveDemoCustomers();
    }
  }

  Future<void> _localDelete(String id) async {
    await _ensureDemoDataLoaded();
    print("🚀 Repository (Demo/Fallback): Deleting customer locally.");
    await Future.delayed(const Duration(milliseconds: 300));
    _demoCustomers.removeWhere((c) => c.id == id);
    await _saveDemoCustomers();
  }

  List<Customer> _filterLocalCustomers(String searchText) {
    if (searchText.isEmpty) return _demoCustomers;
    final lower = searchText.toLowerCase();
    return _demoCustomers
        .where((c) =>
            (c.name.toLowerCase().contains(lower)) ||
            (c.code?.toLowerCase().contains(lower) ?? false) ||
            (c.phone?.contains(lower) ?? false) ||
            (c.identityNumber?.contains(lower) ?? false))
        .toList();
  }
  // ---------------------

  @override
  Future<void> addCustomer(Customer customer) async {
    // 1. Proactive Demo Check
    if (await _isDemoMode()) {
      await _localAdd(customer);
      return;
    }

    try {
      // 2. Prepare API Call
      String avatarBase64 = "";
      if (customer.avatarPath != null && customer.avatarPath!.isNotEmpty) {
        final file = File(customer.avatarPath!);
        if (file.existsSync()) {
          try {
            final bytes = await file.readAsBytes();
            avatarBase64 = base64Encode(bytes);
          } catch (e) {
            print("Error converting avatar to base64: $e");
          }
        }
      }

      // Serialize extra fields to JSON
      Map<String, dynamic> extraData = {
        "sex": customer.gender,
        "nat": customer.nationality,
        "id": customer.identityNumber,
        "issue": customer.issueDate?.toIso8601String(),
        "expiry": customer.expiryDate?.toIso8601String(),
        "front": customer.frontImagePath,
        "back": customer.backImagePath,
        "home": customer.hometown,
      };
      String jsonExtra = jsonEncode(extraData);

      // [OPTIMIZATION] Check length against safe limit (e.g. 400-500 chars)
      // If too long, remove image paths to preserve critical data (Gender, Hometown)
      if (jsonExtra.length > 400) {
        Map<String, dynamic> optimized = Map.from(extraData);
        optimized.remove('front');
        optimized.remove('back');
        optimized.remove('avatarPath');
        jsonExtra = jsonEncode(optimized);
        print("⚠️ JSON too long. Optimized to length: ${jsonExtra.length}");
      }

      String shortJson = jsonExtra;
      const int maxJsonLen = 2000;
      if (shortJson.length > maxJsonLen) {
        print(
            '⚠️ JSON still too long (${shortJson.length}). Risk of truncation.');
      }

      String description = "Quét từ CCCD: ${customer.identityNumber ?? ''}";
      description += " ||JSON:$shortJson";

      // Get LocationId from prefs or use customer.locationId
      final prefs = await SharedPreferences.getInstance();
      final prefLocationId = prefs.getString('location_id') ?? "";
      final locationId =
          (customer.locationId != null && customer.locationId!.isNotEmpty)
              ? customer.locationId!
              : prefLocationId;

      // [TEST REQUEST] Force GroupId to null to test backend behavior
      String? finalGroupId = null;
      print("⚠️ [TEST] Forcing GroupId to NULL for testing purpose.");

      /*
      // [FIX] Ensure GroupId is a valid GUID from existing groups
      // The error "Foreign Key constraint" means we cannot send arbitrary strings like "CN01"
      String? finalGroupId = customer.groupId;

      try {
        final clusters = await getCustomerGroups();
        if (clusters.isNotEmpty) {
          // 1. Is current finalGroupId valid?
          bool isValid = clusters.any((g) => g.id == finalGroupId);

          if (!isValid) {
            print(
                "⚠️ Invalid/Empty GroupId '$finalGroupId'. Attempting auto-assign...");

            // 2. Try to match by LocationId (assuming LocationId might match Group Name/Code)
            // Clean locationId to ensure better matching if needed
            final matchByLocation = clusters.firstWhere(
                (g) => g.name.trim() == locationId.trim() || g.id == locationId,
                orElse: () =>
                    clusters.first // Fallback to first available group
                );

            finalGroupId = matchByLocation.id;
            print(
                "✅ Auto-assigned GroupId: '$finalGroupId' (Name: ${matchByLocation.name})");
          }
        }
      } catch (e) {
        print("⚠️ Could not fetch groups for validation: $e");
      }
      */

      // Ensure CustomerName length is within reasonable bounds to avoid DB truncation
      final safeName = (customer.name.length > 150)
          ? customer.name.substring(0, 150)
          : customer.name;

      final Map<String, dynamic> body = {
        "Id": "",
        "CustomerCode": customer.code ?? "",
        "CustomerName": safeName,
        "BirthDay": (customer.dob != null && customer.dob!.year > 1753)
            ? customer.dob!.toIso8601String()
            : DateTime(1990, 1, 1).toIso8601String(), // Default safe date
        "GroupId": finalGroupId,
        "Address": customer.address ?? "",
        "Tel": customer.phone ?? "",
        "Email": "",
        "Description": description,
        // Avoid sending very large avatar payloads (base64) that may overflow DB columns.
        "Avatar": (avatarBase64.length > 100000) ? "" : avatarBase64,
        "TaxCode":
            customer.identityNumber ?? "", // Map CCCD to TaxCode for Search
        "Longitude": 0,
        "Latitude": 0,
        "Password": "123",
        "LocationId": locationId
      };

      print(
          "🚀 AddCustomer Body: GroupId='${body['GroupId']}', LocationId='${body['LocationId']}'");

      // 3. Attempt API Call
      await remoteDataSource.addNewCustomer(body);
    } catch (e) {
      // 4. Fail-Safe: If API fails with specific errors (302, 401) or we suspect demo
      print("⚠️ Add Customer API Failed: $e");
      if (e.toString().contains("302") || e.toString().contains("401")) {
        print(
            "⚠️ Detected 302/401 Error -> Falling back to LOCAL SAVE for Demo/Offline experience.");
        await _localAdd(customer);
      } else {
        rethrow;
      }
    }
  }

  @override
  Future<List<Customer>> getCustomers(
      {int pageIndex = 0, int pageSize = 20, String searchText = ""}) async {
    // Proactive Check
    if (await _isDemoMode()) {
      await _ensureDemoDataLoaded();
      print("🚀 GetCustomers (Demo): Returning mock list.");
      return _filterLocalCustomers(searchText);
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final locationId = prefs.getString('location_id') ?? "";
      print(
          "🔎 Repository: Fetching customers with LocationId='$locationId', SearchText='$searchText'");

      final raw = await remoteDataSource.fetchCustomers(
          pageIndex: pageIndex,
          pageSize: pageSize,
          searchText: searchText,
          locationId: locationId);
      print("Repository: Received ${raw.length} raw records. Mapping...");

      final rawMapped = raw.reversed.map((e) {
        DateTime? dob;
        if (e['BirthDay'] != null) {
          try {
            dob = DateTime.parse(e['BirthDay']);
          } catch (_) {}
        }

        // Parse Description for extra data
        String? gender;
        String? nationality;
        String? identityNumber;
        DateTime? issueDate;
        DateTime? expiryDate;
        String? frontImagePath;
        String? backImagePath;
        String? hometown;

        String description = e['Description']?.toString() ?? "";
        if (description.contains("||JSON:")) {
          try {
            final parts = description.split("||JSON:");
            if (parts.length > 1) {
              final jsonStr = parts[1];
              final Map<String, dynamic> extra = jsonDecode(jsonStr);
              gender = extra['sex'];
              nationality = extra['nat'];
              identityNumber = extra['id'];
              hometown = extra['home'];
              frontImagePath = extra['front'];
              backImagePath = extra['back'];
              if (extra['issue'] != null)
                issueDate = DateTime.tryParse(extra['issue']);
              if (extra['expiry'] != null)
                expiryDate = DateTime.tryParse(extra['expiry']);
            }
          } catch (e) {
            print("Error parsing extra JSON from description: $e");
          }
        }

        // Fallback: Use TaxCode for CCCD if not in JSON (or if needed)
        if (identityNumber == null || identityNumber.isEmpty) {
          identityNumber = e['TaxCode']?.toString();
        }

        return Customer(
          id: e['Id']?.toString() ?? '',
          name: e['Name']?.toString() ?? 'Khách lẻ',
          code: e['CustomerCode']?.toString(),
          phone: e['Tel']?.toString(),
          address: e['Address']?.toString(),
          dob: dob,
          avatarPath: e['Avatar']?.toString(),

          // Mapped extra fields
          gender: gender,
          nationality: nationality,
          identityNumber: identityNumber,
          issueDate: issueDate,
          expiryDate: expiryDate,
          frontImagePath: frontImagePath,
          backImagePath: backImagePath,
          hometown: hometown,
          groupId: e['GroupId']?.toString(),
          locationId: e['GroupId']
              ?.toString(), // Use GroupId as LocationId since that's where we store it
        );
      }).toList();

      return rawMapped;
    } catch (e) {
      print("⚠️ Get Customer API Failed: $e");
      if (e.toString().contains("302") || e.toString().contains("401")) {
        print("⚠️ Detected 302/401 -> Returning LOCAL DEMO LIST.");
        await _ensureDemoDataLoaded();
        return _filterLocalCustomers(searchText);
      }
      rethrow;
    }
  }

  @override
  Future<void> updateCustomer(Customer customer) async {
    // Proactive
    if (await _isDemoMode()) {
      await _localUpdate(customer);
      return;
    }

    try {
      // Reuse AddCustomer logic for mapping, just call update endpoint
      // 1. Convert Avatar to Base64
      String avatarBase64 = "";
      if (customer.avatarPath != null && customer.avatarPath!.isNotEmpty) {
        final file = File(customer.avatarPath!);
        if (file.existsSync()) {
          try {
            final bytes = await file.readAsBytes();
            avatarBase64 = base64Encode(bytes);
          } catch (e) {
            print("Error converting avatar to base64: $e");
          }
        }
      }

      // 2. Map Entity to API JSON
      Map<String, dynamic> extraData = {
        "sex": customer.gender,
        "nat": customer.nationality,
        "id": customer.identityNumber,
        "issue": customer.issueDate?.toIso8601String(),
        "expiry": customer.expiryDate?.toIso8601String(),
        "front": customer.frontImagePath,
        "back": customer.backImagePath,
        "home": customer.hometown,
      };
      String jsonExtra = jsonEncode(extraData);

      // [OPTIMIZATION]
      if (jsonExtra.length > 400) {
        Map<String, dynamic> optimized = Map.from(extraData);
        optimized.remove('front');
        optimized.remove('back');
        optimized.remove('avatarPath');
        jsonExtra = jsonEncode(optimized);
        print("⚠️ JSON too long. Optimized to length: ${jsonExtra.length}");
      }

      String shortJson = jsonExtra;
      const int maxJsonLen = 2000;
      if (shortJson.length > maxJsonLen) {
        print(
            '⚠️ JSON Extra Data is too long (${shortJson.length} chars). Might be truncated by server.');
      }

      String description = "Quét từ CCCD: ${customer.identityNumber ?? ''}";
      description += " ||JSON:$shortJson";

      final prefs = await SharedPreferences.getInstance();
      final prefLocationId = prefs.getString('location_id') ?? "";
      final locationId =
          (customer.locationId != null && customer.locationId!.isNotEmpty)
              ? customer.locationId!
              : prefLocationId;

      // Fix FK Conflict:
      String? finalGroupId = customer.groupId;
      if (finalGroupId == null ||
          finalGroupId.isEmpty ||
          finalGroupId.toLowerCase() == "null") {
        finalGroupId = (locationId.isNotEmpty ? locationId : null);
      }

      // Ensure CustomerName length is within reasonable bounds to avoid DB truncation
      final safeNameUpd = (customer.name.length > 150)
          ? customer.name.substring(0, 150)
          : customer.name;

      final Map<String, dynamic> body = {
        "Id": customer.id, // Mandatory for Update
        "CustomerCode": customer.code ?? "",
        "CustomerName": safeNameUpd,
        "BirthDay": (customer.dob != null && customer.dob!.year > 1753)
            ? customer.dob!.toIso8601String()
            : DateTime(1990, 1, 1).toIso8601String(),
        "GroupId": finalGroupId,
        "Address": customer.address ?? "",
        "Tel": customer.phone ?? "",
        "Email": "",
        "Description": description,
        "Avatar": (avatarBase64.length > 100000) ? "" : avatarBase64,
        "TaxCode": customer.identityNumber ?? "", // Map CCCD to TaxCode
        "Longitude": 0,
        "Latitude": 0,
        "Password": "123",
        "LocationId": locationId
      };

      // 3. Call Remote Data Source
      await remoteDataSource.updateCustomer(body);
    } catch (e) {
      print("⚠️ Update Customer API Failed: $e");
      if (e.toString().contains("302") ||
          e.toString().contains("401") ||
          e.toString().contains("404")) {
        print("⚠️ Detected Api Error -> Falling back to LOCAL UPDATE.");
        await _localUpdate(customer);
      } else {
        rethrow;
      }
    }
  }

  @override
  Future<bool> checkCustomerExists(
      String identityNumber, String code, String name) async {
    // [DEMO MODE]
    if (await _isDemoMode()) {
      await _ensureDemoDataLoaded();
      // Use local filter
      final lowerId = identityNumber.toLowerCase();
      final lowerCode = code.toLowerCase();
      bool exists = _demoCustomers.any((c) =>
          (lowerId.isNotEmpty &&
              (c.identityNumber?.toLowerCase() == lowerId ||
                  c.code?.toLowerCase() == lowerId)) ||
          (lowerCode.isNotEmpty && c.code?.toLowerCase() == lowerCode));
      return exists;
    }

    try {
      print(
          "🔎 Checking existence for CCCD: '$identityNumber', Code: '$code', Name: '$name'");
      if (identityNumber.isEmpty && code.isEmpty && name.isEmpty) return false;

      // 1. Search by CCCD (Primary - Fast/Direct)
      if (identityNumber.isNotEmpty) {
        final results =
            await getCustomers(searchText: identityNumber, pageSize: 20);

        bool exists = results.any((c) =>
            StringUtils.equalsIgnoreCase(c.identityNumber, identityNumber) ||
            StringUtils.equalsIgnoreCase(c.code, identityNumber) ||
            StringUtils.containsIgnoreCase(c.phone, identityNumber));

        if (exists) return true;
      }

      // 2. Search by Code
      if (code.isNotEmpty) {
        final results = await getCustomers(searchText: code, pageSize: 5);
        bool exists =
            results.any((c) => StringUtils.equalsIgnoreCase(c.code, code));
        if (exists) return true;
      }

      // 3. Fallback: Search by Name
      if (identityNumber.isNotEmpty && name.isNotEmpty) {
        final results = await getCustomers(searchText: name, pageSize: 50);
        for (var user in results) {
          if (StringUtils.equalsIgnoreCase(
              user.identityNumber, identityNumber)) {
            return true;
          }
        }
      }

      return false;
    } catch (e) {
      if (e.toString().contains("302") || e.toString().contains("401")) {
        // Fallback to local check
        await _ensureDemoDataLoaded();
        final lowerId = identityNumber.toLowerCase();
        final lowerCode = code.toLowerCase();
        return _demoCustomers.any((c) =>
            (lowerId.isNotEmpty &&
                (c.identityNumber?.toLowerCase() == lowerId ||
                    c.code?.toLowerCase() == lowerId)) ||
            (lowerCode.isNotEmpty && c.code?.toLowerCase() == lowerCode));
      }
      return false; // return false on error to not block
    }
  }

  @override
  Future<List<CustomerGroup>> getCustomerGroups() async {
    // [DEMO MODE]
    if (await _isDemoMode()) {
      return [CustomerGroup(id: "0", name: "Chi nhánh Demo")];
    }

    try {
      final raw = await remoteDataSource.fetchCustomerGroups();
      return raw
          .map((e) => CustomerGroup(
              id: e['Id']?.toString() ?? '',
              name: e['LocationCode']?.toString() ?? ''))
          .toList();
    } catch (e) {
      if (e.toString().contains("302") || e.toString().contains("401")) {
        return [CustomerGroup(id: "0", name: "Chi nhánh Demo")];
      }
      rethrow;
    }
  }

  @override
  Future<void> deleteCustomer(String id) async {
    if (await _isDemoMode()) {
      await _localDelete(id);
      return;
    }

    try {
      await remoteDataSource.deleteCustomer(id);
    } catch (e) {
      if (e.toString().contains("302") || e.toString().contains("401")) {
        await _localDelete(id);
      } else {
        rethrow;
      }
    }
  }
}
