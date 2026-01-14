# MasterPro AI Scan ID

**Giải pháp nhận diện và trích xuất thông tin CCCD gắn chip tự động bằng công nghệ AI.**

Ứng dụng di động được xây dựng trên nền tảng **Flutter**, sử dụng kiến trúc **Clean Architecture** và **BLoC Pattern** để đảm bảo hiệu suất cao, dễ dàng mở rộng và bảo trì.

---

## 🚀 Tính Năng Chính

### 1. 🔍 AI Scan ID (Quét CCCD)
- **Tự động nhận diện**: Sử dụng **Google ML Kit** để quét và nhận diện thẻ CCCD/CMND.
- **Trích xuất thông tin**: Tự động đọc và điền các trường thông tin (Số CCCD, Họ tên, Ngày sinh, Quê quán,...) với độ chính xác cao.
- **Nhận diện khuôn mặt**: Tách và lưu trữ ảnh chân dung từ thẻ CCCD.
- **Quét mã QR**: Hỗ trợ quét mã QR trên thẻ CCCD để lấy thông tin mã hóa.

### 2. 👥 Quản Lý Khách Hàng (Customers)
- **Hồ sơ chi tiết**: Lưu trữ đầy đủ thông tin khách hàng kèm ảnh CCCD và ảnh chân dung.
- **Tìm kiếm & Lọc**: Tra cứu khách hàng nhanh chóng theo tên, số điện thoại hoặc số CCCD.
- **Phân loại**: Quản lý khách hàng theo nhóm hoặc trạng thái (Tiềm năng, VIP...).

### 3. 🔐 Bảo Mật & Xác Thực (Auth)
- **Đăng nhập an toàn**: Hệ thống xác thực người dùng chặt chẽ.
- **Phân quyền**: Quản lý quyền truy cập dữ liệu (User/Admin).

### 4. 📶 Hoạt Động Offline (Offline-First)
- **Lưu trữ cục bộ**: Sử dụng **SQLite** để lưu dữ liệu, cho phép ứng dụng hoạt động mượt mà ngay cả khi không có mạng.
- **Đồng bộ hóa**: Cơ chế đồng bộ dữ liệu thông minh khi có kết nối trở lại.

---

## 🛠 Tech Stack

### Core
- **Framework**: Flutter (Dart)
- **Architecture**: Clean Architecture (Feature-first).
- **State Management**: flutter_bloc.
- **Dependency Injection**: get_it, injectable.

### AI & Media
- **AI Engine**: Google ML Kit (Text Recognition, Face Detection, Barcode Scanning).
- **Camera**: camera package (Custom viewfinder).

### Data Layer
- **Local DB**: sqflite.
- **Preferences**: shared_preferences.
- **Networking**: dio (với Interceptors & Error Handling).

### Utilities
- **Code Gen**: freezed, json_serializable, build_runner.
- **Responsive**: responsive_framework.

---

## 📂 Cấu Trúc Source Code

Dự án được tổ chức theo module tính năng (Feature-based), giúp code rõ ràng và dễ quản lý:

```text
lib/
├── core/                   # Kernel của ứng dụng
│   ├── config/             # Environment, Themes, Constants
│   ├── error/              # Failure, Exception classes
│   └── utils/              # Helper functions (ImageUtils, Validators...)
│
├── features/               # Các module chức năng
│   ├── auth/               # Login, Register, Session
│   ├── customers/          # Danh sách, Chi tiết khách hàng
│   ├── scan/               # Camera, Image Processing, ML Kit Logic
│   └── users/              # Quản lý người dùng hệ thống
│   │   ├── data/           # Remote/Local DataSource, Repository Impl
│   │   ├── domain/         # Entities, Repository Interface, UseCases
│   │   └── presentation/   # BLoC/Cubit, Pages, Widgets
│
├── injection_container.dart # Setup DI (Service Locator)
└── main.dart               # Entry Point
```

---

## ⚙️ Hướng Dẫn Cài Đặt (Setup Guide)

### Yêu cầu
- Flutter SDK: `3.3.3` - `4.0.0`
- Android Studio / VS Code.

### Các bước thực hiện

1.  **Clone dự án:**
    ```bash
    git clone <git_repo_url>
    cd masterpro-AI-Scan-ID
    ```

2.  **Cài đặt thư viện:**
    ```bash
    flutter pub get
    ```

3.  **Generate Code (Quan trọng):**
    Dự án dùng `freezed` và `json_serializable`, cần chạy lệnh này để sinh code model:
    ```bash
    flutter pub run build_runner build --delete-conflicting-outputs
    ```

4.  **Chạy ứng dụng:**
    ```bash
    flutter run
    ```
    *Lưu ý: Để test tính năng Scan, bắt buộc phải chạy trên thiết bị thật (Android/iOS).*

---

## 🐛 Troubleshooting (Gỡ Lỗi Thường Gặp)

### 1. Lỗi Build Runner không sinh file
*   **Nguyên nhân**: Xung đột file cũ hoặc cache.
*   **Khắc phục**:
    ```bash
    flutter clean
    flutter pub get
    flutter pub run build_runner build --delete-conflicting-outputs
    ```

### 2. Camera không hoạt động / Màn hình đen
*   **Nguyên nhân**: Chưa cấp quyền Camera.
*   **Khắc phục**: Vào Cài đặt thiết bị -> Ứng dụng -> MasterPro -> Quyền -> Bật Camera. Hoặc kiểm tra `AndroidManifest.xml` / `Info.plist`.

### 3. Lỗi dependencies version
*   **Khắc phục**: Kiểm tra file `pubspec.yaml`, đảm bảo các phiên bản tương thích với Flutter SDK hiện tại. Dùng `flutter pub outdated` để kiểm tra.

---
**Maintained by AnHong-Dev**
