# Masterpro Ghi Đơn

## Tổng quan
- Tên dự án: `masterpro_ghidon`
- Mục đích: Ứng dụng quản lý bán hàng/ghi đơn (Flutter) với nhiều module: auth, cart, products, users, orders, customers.
- Ngôn ngữ: Dart (Flutter)

## Cấu trúc chính
- `lib/` : mã nguồn chính
  - `features/` : các module theo tính năng (auth, cart, products, orders, customers, users,...)
  - `core/` : cấu hình chung, theme, network, usecases
  - `injection_container.dart` : cấu hình DI (get_it)
  - `main.dart` : entrypoint
- `assets/` : hình ảnh và icon
- `android/`, `ios/`, `windows/`, `linux/`, `macos/`, `web/` : platform folders

## Yêu cầu môi trường
- Flutter SDK tương thích: theo `pubspec.yaml` SDK `>=3.3.3 <4.0.0` (khuyên dùng Flutter stable tương ứng)
- Platform SDKs: Android SDK (minSdk >= 21 theo `pubspec.yaml` launcher config)

## Cài đặt nhanh
1. Cài Flutter theo phiên bản phù hợp. Kiểm tra:

```bash
flutter --version
```

2. Cài dependencies:

```bash
flutter pub get
```

3. Nếu dùng code-gen (freezed/json_serializable):

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

4. Chạy ứng dụng (Android):

```bash
flutter run -d android
```

Hoặc build release:

```bash
flutter build apk --release
```

## Các lệnh kiểm tra / debug
- Phân tích tĩnh:

```bash
flutter analyze
```

- Kiểm tra lỗi dependency:

```bash
flutter pub outdated
```

## Vấn đề đã phát hiện và cách xử lý (chi tiết)
1) Hàm không sử dụng (warning/compile error):
- File: `lib/features/cart/presentation/pages/checkout_page.dart`
- Vấn đề: Có khai báo `void _placeOrder(BuildContext context, double finalTotal)` nhưng không được tham chiếu nên Dart analyzer báo "The declaration '_placeOrder' isn't referenced.".
- Cách xử lý:
  - Nếu chức năng xác nhận đặt hàng vẫn cần, thay thế chỗ gọi ` _processOrder(context, total)` bằng gọi `_placeOrder(context, total)` hoặc ngược lại; giữ một hàm duy nhất để tránh duplicate logic.
  - Nếu `_placeOrder` không còn dùng, xóa hàm để loại bỏ cảnh báo.

2) Chú ý parse số từ JSON
- Trong nhiều model thấy pattern `(json['X'] ?? 0).toDouble()`.
- Vấn đề: nếu `json['X']` có thể là `String` (ví dụ "12.34") hoặc `null`, `(json['X'] ?? 0).toDouble()` có thể ném lỗi nếu giá trị là `String` (vì `String` không có `toDouble()`), nên dùng an toàn:

Ví dụ an toàn:

```dart
final price = (json['Price'] is num)
    ? (json['Price'] as num).toDouble()
    : double.tryParse(json['Price']?.toString() ?? '0') ?? 0.0;
```

3) Xử lý trạng thái đăng nhập trong `main.dart`
- `main.dart` gọi `final isLoggedIn = authService.isLoggedIn();` — nếu `isLoggedIn()` là bất đồng bộ (async) cần đảm bảo await trước khi quyết định `home`. Hiện code dùng không-async, nếu `isLoggedIn()` sync thì ok.
  - Nếu `isLoggedIn()` trả về `Future<bool>`, thay đổi để chờ `await` (ví dụ bằng `FutureBuilder` hoặc kiểm tra trước khi `runApp`).

4) Codegen và generated files
- Nếu gặp lỗi missing generated files (ví dụ `*.g.dart`, `*.freezed.dart`), chạy:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

5) Lỗi runtime / network
- Các lỗi gọi API come from domain/data layer; khi gặp lỗi API, kiểm tra: base URL, headers (token), và format dữ liệu. Dùng logging (ví dụ `dio` interceptors) để debug request/response.

## Quy ước & lưu ý phát triển
- Sử dụng DI (`injection_container.dart`) để đăng ký service/Blocs.
- Đảm bảo gọi `dispose()` cho `TextEditingController` (đã có trong `CheckoutPage`).
- Kiểm tra `mounted` trước khi thao tác UI trong các callback async (đã xử lý trong một số chỗ).

## Thực hiện các thay đổi đề xuất (tóm tắt)
1. Loại bỏ hoặc hợp nhất `_placeOrder` và `_processOrder` để xóa warning analyzer.
2. Fix parse number từ JSON bằng cách kiểm tra `is num` trước khi gọi `toDouble()` hoặc dùng `double.tryParse`.
3. Chạy `flutter pub get`, `flutter analyze`, `flutter test` (nếu có tests) trước khi build release.

## Muốn tôi làm tiếp? (gợi ý)
- Tôi có thể sửa trực tiếp file `checkout_page.dart` để xóa hàm `_placeOrder` không dùng hoặc hợp nhất logic (cần bạn xác nhận). 
- Hoặc tôi có thể kiểm tra các model JSON và sửa tất cả chỗ dùng `(json[...] ?? 0).toDouble()` thành pattern an toàn.

---
Nếu bạn muốn, tôi sẽ áp patch sửa nhanh `checkout_page.dart` (xóa `_placeOrder`) và sửa vài model mẫu để xử lý parse số an toàn. Bạn muốn tôi bắt đầu với việc nào?
# masterpro_ghidon

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
