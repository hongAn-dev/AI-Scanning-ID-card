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

  @override
  Future<void> addCustomer(Customer customer) async {
    // 1. Convert Avatar to Base64 if it exists locally
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
    String description = "Quét từ CCCD: ${customer.identityNumber ?? ''}";

    // Append JSON to description with a separator
    description += " ||JSON:$jsonExtra";

    // Get LocationId from prefs or use customer.locationId
    final prefs = await SharedPreferences.getInstance();
    final prefLocationId = prefs.getString('location_id') ?? "";
    final locationId =
        (customer.locationId != null && customer.locationId!.isNotEmpty)
            ? customer.locationId!
            : prefLocationId;

    final Map<String, dynamic> body = {
      "Id": "",
      "CustomerCode": customer.code ?? "",
      "CustomerName": customer.name,
      "BirthDay": (customer.dob != null && customer.dob!.year > 1753)
          ? customer.dob!.toIso8601String()
          : DateTime(1990, 1, 1).toIso8601String(), // Default safe date
      "GroupId": (customer.groupId == null ||
              customer.groupId!.isEmpty ||
              customer.groupId!.toLowerCase() == "null")
          ? (locationId.isNotEmpty ? locationId : null)
          : customer.groupId,
      "Address": customer.address ?? "",
      "Tel": customer.phone ?? "",
      "Email": "",
      "Description": description,
      "Avatar": avatarBase64,
      "TaxCode":
          customer.identityNumber ?? "", // Map CCCD to TaxCode for Search
      "Longitude": 0,
      "Latitude": 0,
      "Password": "123",
      "LocationId": locationId
    };

    // 3. Call Remote Data Source
    await remoteDataSource.addNewCustomer(body);
  }

  @override
  Future<List<Customer>> getCustomers(
      {int pageIndex = 0, int pageSize = 20, String searchText = ""}) async {
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
    // Reverse logic as requested by user
    print("Repository: Received ${raw.length} raw records. Mapping...");
    // Reverse logic as requested by user
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

    // Client-side filtering REMOVED. Backend now filters correctly with Status: true.
    // Trusting the API to return only customers for the specified LocationId.
    return rawMapped;
  }

  @override
  Future<void> updateCustomer(Customer customer) async {
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
    String description = "Quét từ CCCD: ${customer.identityNumber ?? ''}";
    description += " ||JSON:$jsonExtra";

    final prefs = await SharedPreferences.getInstance();
    final prefLocationId = prefs.getString('location_id') ?? "";
    final locationId =
        (customer.locationId != null && customer.locationId!.isNotEmpty)
            ? customer.locationId!
            : prefLocationId;

    // Fix FK Conflict:
    // If GroupId is null/empty, we MUST send null to avoid FK conflict with LS_ObjectGroups.
    // Sending "" or "0000..." causes FK error.
    String? finalGroupId = customer.groupId;
    if (finalGroupId == null ||
        finalGroupId.isEmpty ||
        finalGroupId.toLowerCase() == "null") {
      finalGroupId = (locationId.isNotEmpty ? locationId : null);
    }

    final Map<String, dynamic> body = {
      "Id": customer.id, // Mandatory for Update
      "CustomerCode": customer.code ?? "",
      "CustomerName": customer.name,
      "BirthDay": (customer.dob != null && customer.dob!.year > 1753)
          ? customer.dob!.toIso8601String()
          : DateTime(1990, 1, 1).toIso8601String(),
      "GroupId": finalGroupId,
      "Address": customer.address ?? "",
      "Tel": customer.phone ?? "",
      "Email": "",
      "Description": description,
      "Avatar": avatarBase64,
      "TaxCode": customer.identityNumber ?? "", // Map CCCD to TaxCode
      "Longitude": 0,
      "Latitude": 0,
      "Password": "123",
      "LocationId": locationId
    };

    // 3. Call Remote Data Source
    await remoteDataSource.updateCustomer(body);
  }

  @override
  Future<bool> checkCustomerExists(
      String identityNumber, String code, String name) async {
    print(
        "🔎 Checking existence for CCCD: '$identityNumber', Code: '$code', Name: '$name'");
    if (identityNumber.isEmpty && code.isEmpty && name.isEmpty) return false;

    // 1. Search by CCCD (Primary - Fast/Direct)
    if (identityNumber.isNotEmpty) {
      print(
          "   -> (1) Calling getCustomers with SearchText='$identityNumber'...");
      final results =
          await getCustomers(searchText: identityNumber, pageSize: 20);

      print("   -> Server returned ${results.length} result(s).");
      // Check rigorous match
      bool exists = results.any((c) =>
          StringUtils.equalsIgnoreCase(c.identityNumber, identityNumber) ||
          StringUtils.equalsIgnoreCase(c.code, identityNumber) ||
          StringUtils.containsIgnoreCase(c.phone, identityNumber));

      if (exists) {
        print("   ✅ Match FOUND by CCCD (Direct Search)!");
        return true;
      }
    }

    // 2. Search by Code
    if (code.isNotEmpty) {
      print("   -> (2) Calling getCustomers with SearchText='$code'...");
      final results = await getCustomers(searchText: code, pageSize: 5);
      bool exists =
          results.any((c) => StringUtils.equalsIgnoreCase(c.code, code));
      if (exists) {
        print("   ✅ Match FOUND by Code!");
        return true;
      }
    }

    // 3. Fallback: Search by Name (For Legacy Data where CCCD is in Description)
    // Only if CCCD is provided but not found directly
    if (identityNumber.isNotEmpty && name.isNotEmpty) {
      print(
          "   -> (3) Fallback: Searching by Name '$name' to check legacy Description...");
      // Search by Name
      final results = await getCustomers(searchText: name, pageSize: 50);
      print(
          "   -> Server returned ${results.length} result(s) for name '$name'.");

      for (var user in results) {
        // We already have c.identityNumber mapped from Description in getCustomers
        // So we just check that field again.
        if (StringUtils.equalsIgnoreCase(user.identityNumber, identityNumber)) {
          print("   ✅ Match FOUND in Legacy Data (via Name Search)!");
          print(
              "      - Existing User: ${user.name} | CCCD: ${user.identityNumber}");
          return true;
        }
      }
    }

    print("🏁 Check finished: No duplicates found.");
    return false;
  }

  @override
  Future<List<CustomerGroup>> getCustomerGroups() async {
    final raw = await remoteDataSource.fetchCustomerGroups();
    return raw
        .map((e) => CustomerGroup(
            id: e['Id']?.toString() ?? '',
            name: e['LocationCode']?.toString() ?? ''))
        .toList();
  }

  @override
  Future<void> deleteCustomer(String id) async {
    await remoteDataSource.deleteCustomer(id);
  }
}
