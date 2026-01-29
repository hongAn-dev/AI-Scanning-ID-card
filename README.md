# MasterPro AI Scan ID

MasterPro AI Scan ID is a powerful Flutter application designed for high-performance identity document scanning and management. It leverages Google ML Kit for advanced OCR (Optical Character Recognition) and face detection, providing a seamless solution for processing Vietnamese Citizen Identity Cards (CCCD) and Passports.

## 🚀 Key Features

*   **Smart Document Scanning:**
    *   **OCR Technology:** Accurately extracts text from CCCD and Passports using Google ML Kit.
    *   **Region-Specific Parsing:** Tailored logic for Vietnamese identity documents.
    *   **Barcode & QR Scanning:** Instantly reads embedded data from document QR codes.
*   **Face Detection:** Detects faces within documents for identity verification logic.
*   **Customer Management:** Efficiently manage customer records with local database storage.
*   **Responsive Design:** Optimized experience across Mobile, Tablet, and Desktop devices using `responsive_framework`.
*   **Offline Capability:** Fully functional offline mode with SQLite local storage.
*   **Secure Authentication:** Robust login flow and session management.

## 🛠 Technology Stack

This project is built using **Flutter** and follows **Clean Architecture** principles to ensure scalability and maintainability.

*   **Framework:** [Flutter](https://flutter.dev/) (SDK >=3.3.3 <4.0.0)
*   **Language:** Dart
*   **State Management:** [Flutter Bloc](https://pub.dev/packages/flutter_bloc) & Cubit
*   **AI/ML:**
    *   [google_mlkit_text_recognition](https://pub.dev/packages/google_mlkit_text_recognition)
    *   [google_mlkit_face_detection](https://pub.dev/packages/google_mlkit_face_detection)
    *   [google_mlkit_barcode_scanning](https://pub.dev/packages/google_mlkit_barcode_scanning)
*   **Networking:** [Dio](https://pub.dev/packages/dio) with [Internet Connection Checker](https://pub.dev/packages/internet_connection_checker)
*   **Local Database:** [SQLite](https://pub.dev/packages/sqflite)
*   **Service Locator:** [GetIt](https://pub.dev/packages/get_it)
*   **JSON Handling:** [Json Serializable](https://pub.dev/packages/json_serializable) & [Freezed](https://pub.dev/packages/freezed)

## 📂 Project Structure

The project follows a feature-first Clean Architecture approach:

```
lib/
├── core/           # Core utilities, theme, and shared components
├── features/       # Feature-based modules (Auth, Scan, Customers, etc.)
│   ├── data/       # Data storage, API calls, and repositories
│   ├── domain/     # Entities and use cases (Business Logic)
│   └── presentation/ # UI, Blocs/Cubits, and Widgets
├── utils/          # Helper classes
├── injection_container.dart # Dependency Injection setup
└── main.dart       # Application entry point
```

## 🏗 Installation & Setup

### Prerequisites
*   Flutter SDK installed (Version compatible with `environment: sdk: '>=3.3.3 <4.0.0'`)
*   Android Studio / VS Code with Flutter extensions
*   Android SDK / iOS Xcode (for mobile development)

### Getting Started

1.  **Clone the repository:**
    ```bash
    git clone <repository-url>
    cd masterpro-ai-scan-id
    ```

2.  **Install dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Run Code Generation (if needed):**
    If you make changes to models using Freezed or JSON Serializable:
    ```bash
    dart run build_runner build --delete-conflicting-outputs
    ```

4.  **Run the Application:**
    ```bash
    flutter run
    ```
    *   **Release Build (Android):**
        ```bash
        ./build_apk.sh
        # or
        ./build_appbundle.sh
        ```

## 📱 Supported Platforms

*   **Android:** API Level 21+
*   **iOS:** iOS 11.0+
*   **Windows & macOS:** (Desktop support via responsive design)

---
Developed for **MasterPro** - Advanced AI Solutions.