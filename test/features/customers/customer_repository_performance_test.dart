import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:masterpro_ai_scan_id/core/network/dio_client.dart';
import 'package:masterpro_ai_scan_id/features/customers/data/datasources/customer_local_data_source.dart';
import 'package:masterpro_ai_scan_id/features/customers/data/datasources/customer_remote_data_source.dart';
import 'package:masterpro_ai_scan_id/features/customers/data/repositories/customer_repository_impl.dart';

// 1. Mock DioClient using 'implements' to avoid executing the real constructor
class MockDioClient implements DioClient {
  @override
  Future<Response> get(String path,
      {Map<String, dynamic>? queryParameters, Options? options}) {
    throw UnimplementedError();
  }

  @override
  Future<Response> post(String path,
      {data, Map<String, dynamic>? queryParameters, Options? options}) {
    throw UnimplementedError();
  }

  @override
  Future<Response> put(String path,
      {data, Map<String, dynamic>? queryParameters, Options? options}) {
    throw UnimplementedError();
  }

  @override
  Future<Response> delete(String path,
      {data, Map<String, dynamic>? queryParameters, Options? options}) {
    throw UnimplementedError();
  }
}

// 2. Mock RemoteDataSource
class MockCustomerRemoteDataSource extends CustomerRemoteDataSourceImpl {
  MockCustomerRemoteDataSource() : super(dioClient: MockDioClient());

  @override
  Future<List<Map<String, dynamic>>> fetchCustomers({
    int pageIndex = 0,
    int pageSize = 20,
    String searchText = "",
    String locationId = "",
  }) async {
    // Generate a large list of customers to simulate heavy load
    // Generating 5000 items
    return List.generate(5000, (index) {
      return {
        "Id": "CUS_$index",
        "CustomerCode": "CODE_$index",
        "Name": "Customer $index",
        "Tel": "0900000$index",
        "Address": "Address $index",
        "BirthDay": "1990-01-01T00:00:00",
        "Avatar":
            "", // Empty to skip base64 decode for now (focus on JSON mapping)
        "Description":
            "Quét từ CCCD: 12345$index ||JSON:{\"sex\":\"Nam\", \"id\":\"12345$index\", \"home\":\"Hanoi\"}",
        "GroupId": "G1",
      };
    });
  }
}

// 3. Mock LocalDataSource
class MockCustomerLocalDataSource extends CustomerLocalDataSourceImpl {
  MockCustomerLocalDataSource() : super();
}

void main() {
  late CustomerRepositoryImpl repository;
  late MockCustomerRemoteDataSource mockRemote;
  late MockCustomerLocalDataSource mockLocal;

  setUp(() async {
    // Ensure SharedPreferences doesn't default to Demo Mode
    SharedPreferences.setMockInitialValues({
      "is_demo": false,
      "access_token": "valid_token", // To bypass token check
      "location_id": "LOC_1"
    });

    mockRemote = MockCustomerRemoteDataSource();
    mockLocal = MockCustomerLocalDataSource();
    repository = CustomerRepositoryImpl(
      remoteDataSource: mockRemote,
      localDataSource: mockLocal,
    );
  });

  test('Benchmark: getCustomers mapping performance (5000 items)', () async {
    print("Starting benchmark for getCustomers with 5000 items...");
    final stopwatch = Stopwatch()..start();

    final results = await repository.getCustomers(pageIndex: 0, pageSize: 5000);

    stopwatch.stop();
    print("✅ Benchmark complete.");
    print("Time taken: ${stopwatch.elapsedMilliseconds} ms");
    print("Total mapped items: ${results.length}");

    // Assertions to ensure logic is correct
    expect(results.length, 5000);
    expect(results.first.name, "Customer 4999"); // Logic has .reversed
    expect(results.first.identityNumber, "123454999"); // Check parsing

    // Performance Threshold Assestion
    // Warn if it takes more than 500ms (1000 items usually take < 30ms on mobile, but 5000 with JSON inside might be slower)
    if (stopwatch.elapsedMilliseconds > 500) {
      print("⚠️ WARNING: Mapping is slow > 500ms");
    } else {
      print("🚀 Performance is acceptable (< 500ms)");
    }
  });
}
