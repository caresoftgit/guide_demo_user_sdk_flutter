# Chạy demo Flutter Android/iOS

Đọc [hợp đồng bootstrap](host-bootstrap.md) trước khi tích hợp. Ứng dụng giữ luồng đăng nhập doanh nghiệp hiện có và inject callback xin ticket; demo không tạo hoặc quản lý phiên doanh nghiệp.

## 1. Cài gói và cấu hình

```sh
shasum -a 256 -c packages/SHA256SUMS
python3 scripts/install_sdk.py
cp config/voice.example.json config/voice.local.json
```

Sửa file local bằng thông tin ứng dụng:

| Field | Nội dung |
|---|---|
| backendUrl | HTTPS gateway gốc, không thêm `/api/v1/voice` |
| bootstrapUrl | Endpoint HTTPS đầy đủ của backend doanh nghiệp, ví dụ `https://app.example.com/api/voice/bootstrap` |
| accountId | Account ID, truyền chuỗi |
| appId | Caresoft App ID; khác Firebase App ID và Apple Bundle ID |
| businessNumber | Đầu số CSKH được cấp sau định tuyến |
| supportName | Tên hiển thị trên màn hình gọi |
| pushEnvironment | `production` hoặc `sandbox` khớp signing/APNs server; Android preparation dùng `default` |
| firebase.appId / apiKey / projectId / senderId | Firebase client options Android đúng package cuối cùng |

Không điền credential tích hợp, Customer REST token hoặc private key push. Demo dùng FirebaseOptions, không cần chép google-services.json. iOS không dùng phần Firebase. `bootstrapUrl` không phải URL gateway và không phải URL gốc để demo tự thêm endpoint.

```sh
python3 scripts/configure.py
flutter pub get
flutter test
flutter analyze
```

Configure tạo ba file bị Git bỏ qua: `lib/voice_config.json`, `android/app/src/main/assets/voice_config.json`, `ios/Runner/voice_config.json`. Sau khi đổi cấu hình phải configure và build lại native; hot reload chưa đủ. Không commit các file local/generated hoặc đường dẫn toolchain.

## 2. Nối HTTP client của ứng dụng

Mặc định `main()` chỉ dựng `VoiceDemoApp(config: config)`, vì vậy nút **Kết nối Voice** bị khóa. Khi ứng dụng đã có phiên doanh nghiệp, inject callback:

```dart
import 'package:flutter/widgets.dart';
import 'package:customer_voice_demo/main.dart';
import 'package:customer_voice_demo/home_model.dart';
import 'package:customer_voice_demo/host_backend.dart';

// Adapter do doanh nghiệp cung cấp cho HTTP client đã xác thực.
final HostTransport transport = authenticatedApplicationTransport;
final config = DemoConfig(publicConfiguration);
final backend = HostBackend(config.bootstrapUrl, transport: transport);
runApp(VoiceDemoApp(config: config, requestTicket: backend.requestTicket));
```

`authenticatedApplicationTransport` và `publicConfiguration` là điểm nối do ứng dụng cung cấp. Transport tự gắn bearer/cookie phiên ứng dụng, giữ nguyên URL/body, dùng HTTPS/TLS, không follow redirect, không tự retry POST, áp deadline 5 giây và giới hạn đọc response 16 KiB trước khi buffer. Xem chữ ký và các kiểm tra bổ sung của helper trong [host-bootstrap.md](host-bootstrap.md). Không gắn credential Caresoft vào transport.

Callback có kiểu `Future<String> Function(LoginPreparation)`; có thể cung cấp callback của ứng dụng thay helper mẫu, miễn tuân thủ hợp đồng bootstrap. Demo chỉ gọi `prepareLogin()` → callback → `loginWithTicket()`.

## 3. Android

1. Cài Flutter 3.50.1/Dart 3.14.0, **OpenJDK 25**, Android SDK/Build Tools 37, NDK 28.1.13356709 và platform-tools. Demo minSdk 26, Gradle 9.5/AGP 9.3.1; Java/Kotlin source target 17 không có nghĩa dùng JDK 17 để chạy build tools.
2. Đặt `JAVA_HOME` và Flutter JDK về OpenJDK 25; kiểm tra `java -version` và `flutter doctor -v`. Đặt `ANDROID_HOME` hoặc `android/local.properties` phù hợp máy build.
3. Đổi applicationId trong `android/app/build.gradle.kts` sang package khớp Firebase và App Caresoft. Namespace Kotlin có thể giữ nguyên cho demo.
4. Kết nối thiết bị, bật USB debugging; hoặc mở emulator. Chạy `flutter devices`, rồi `flutter run -d <DEVICE_ID>`.
5. Cấp quyền micro/thông báo; Android 14+ cho phép full-screen incoming khi ứng dụng hướng dẫn.

```sh
flutter build apk --release
```

APK ở `build/app/outputs/flutter-apk/app-release.apk`. Release bật R8/resource shrinking nhưng dùng debug signing của template để test local. Production phải có signing riêng.

## 4. iOS

1. Cài Xcode 26.4 và CocoaPods; kiểm tra `flutter doctor`. Deployment target iOS 15.1+.
2. Chạy `flutter pub get`, sau đó chạy `pod install` trong thư mục `ios`; mở `Runner.xcworkspace`.
3. Chọn scheme Runner, Signing Team/Bundle ID của ứng dụng và simulator hoặc iPhone; chạy từ Xcode hoặc `flutter run -d <DEVICE_ID>`. Simulator cũng cần app identity entitlement để dùng Keychain; không dùng bản `--no-codesign` để nghiệm thu đăng nhập.
4. Với iPhone, bật Push Notifications và Background Modes Audio/VoIP/Remote notifications, khớp Bundle ID/App Caresoft và provisioning.
5. Development: `pushEnvironment=sandbox`, configure lại, đặt Xcode `VOICE_APNS_ENVIRONMENT=development`; server phải có APNs sandbox tương ứng. TestFlight/distribution dùng production trong config, entitlement và server.
6. Đổi AppIcon/logo và tên hiển thị theo ứng dụng; giữ microphone/camera purpose strings cần thiết trong Info.plist. Mẫu không kèm Team/profile của đơn vị tích hợp.

```sh
flutter build ios --simulator --debug
flutter build ios --release --no-codesign
```

Lệnh thứ hai chỉ kiểm tra build device unsigned; chưa tạo distribution hoặc upload TestFlight. Demo dùng CocoaPods và tắt Swift Package Manager trong pubspec; thông báo về Flutter tương lai không phải cam kết hỗ trợ toolchain đó.

## 5. Thử từ ứng dụng

1. Đăng nhập ứng dụng theo cơ chế doanh nghiệp hiện có, rồi mở màn hình đã inject callback. Chưa có callback thì Kết nối Voice bị khóa.
2. Bấm **Kết nối Voice**; không có form mật khẩu, ID khách hàng hoặc account token.
3. Cấp quyền; kiểm tra `canCall` và `canReceive` riêng biệt. Bấm Gọi CSKH để mở UI native.
4. Thử mic/loa/DTMF, về Home rồi Quay lại cuộc gọi; gác máy đóng UI về Home.
5. **Ngắt Voice** dọn phiên SDK, vẫn giữ đăng nhập ứng dụng. Đăng xuất ứng dụng phải gọi cả SDK logout lẫn logout doanh nghiệp hiện có, kể cả khi một bên lỗi.
6. Làm [checklist thiết bị](testing.md) với signing, push và HTTP client thật của ứng dụng.

## Khắc phục nhanh

- Thiếu package path: chạy `install_sdk.py` trước `pub get`.
- Checksum sai: lấy lại archive và SHA256SUMS cùng bản; không bỏ qua xác minh.
- Kết nối Voice bị khóa: kiểm tra cấu hình và callback `requestTicket`; URL đơn lẻ không tạo phiên ứng dụng.
- `HOST_LOGIN_REQUIRED`: phiên ứng dụng không hợp lệ; quay về luồng xác thực doanh nghiệp hiện có.
- `NATIVE_MODULE_NOT_LINKED`: cài Pods/autolinking, build native lại.
- `SESSION_STORAGE_UNAVAILABLE`: kiểm tra Team/Bundle ID/entitlement app identity/Keychain, build lại với signing bật; không thay bằng lưu token vào preferences.
- `NATIVE_BOOTSTRAP_REQUIRED`/`CONFIGURATION_MISMATCH`: kiểm tra Application/AppDelegate, configure và build lại.
- Push chưa tới: kiểm tra package/Bundle, environment, Firebase/APNs credential server và quyền OS.
- Request gọi timeout: chờ `synchronize()` thành công trước khi gọi tiếp; không gọi lại tự động.
