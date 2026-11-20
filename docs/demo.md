# Chạy demo Flutter Android/iOS

## 1. Cài gói và cấu hình

Trong thư mục bộ demo:

```sh
python3 scripts/install_sdk.py
cp config/voice.example.json config/voice.local.json
```

Sửa file local bằng thông tin của ứng dụng:

| Field | Nội dung |
|---|---|
| backendUrl | HTTPS gateway gốc, không thêm `/api/v1/voice` |
| accountId | Account ID, chuỗi số |
| appId | App ID tạo trên Caresoft |
| businessNumber | Đầu số CSKH được cấp sau định tuyến |
| supportName | Tên hiển thị trên màn hình gọi |
| pushEnvironment | production hoặc sandbox theo signing/APNs server |
| firebase.appId / apiKey / projectId / senderId | Firebase **client** options Android đúng package cuối cùng |

Không điền token account hoặc private key push. Demo dùng FirebaseOptions; không cần chép google-services.json. iOS không dùng phần Firebase.

```sh
python3 scripts/configure.py
flutter pub get
flutter test
flutter analyze
```

Configure tạo ba file bị Git bỏ qua: `lib/voice_config.json`, `android/app/src/main/assets/voice_config.json`, `ios/Runner/voice_config.json`. Sau khi đổi cấu hình phải configure và build lại native, không chỉ hot reload.

## 2. Android

1. Cài JDK 17, Android SDK/Build Tools 37, NDK 28.1.13356709, platform-tools. Demo minSdk 26.
2. Đặt ANDROID_HOME hoặc android/local.properties phù hợp máy build. Không commit đường dẫn local.
3. Đổi applicationId trong android/app/build.gradle.kts sang package khớp Firebase và App Caresoft. Namespace Kotlin có thể giữ nguyên cho demo.
4. Kết nối thiết bị, bật USB debugging và chấp nhận quyền; hoặc mở emulator.
5. Chạy `flutter devices`, rồi `flutter run -d <DEVICE_ID>`.
6. Cấp quyền micro/thông báo; trên Android 14+ cho phép full-screen incoming khi ứng dụng hướng dẫn.

Build APK độc lập:

```sh
flutter build apk --release
```

File ở `build/app/outputs/flutter-apk/app-release.apk`. Release bật R8/resource shrinking, nhưng dùng debug signing của template để test local. Production phải có signing riêng; không phát hành bằng debug key.

## 3. iOS

1. Cài Xcode 26.4 và CocoaPods; kiểm tra `flutter doctor`.
2. Chạy `flutter pub get`, `cd ios && pod install`, mở Runner.xcworkspace.
3. Chọn scheme Runner và simulator rồi Run; hoặc `flutter run -d <SIMULATOR_ID>`.
4. Với iPhone: chọn Team và Bundle ID riêng, khớp App Caresoft; bật Push Notifications và Background Modes Audio/VoIP/Remote notifications.
5. Khi ký development: `pushEnvironment=sandbox`, configure lại, đặt Xcode `VOICE_APNS_ENVIRONMENT=development`; server phải có APNs sandbox tương ứng. TestFlight dùng production trong config và entitlement, profile distribution.
6. Đổi AppIcon/logo và tên hiển thị theo ứng dụng. Bộ mẫu không có Team/profile/Bundle test nội bộ. Giữ microphone/camera purpose strings cần thiết trong Info.plist.

```sh
flutter build ios --simulator --debug --no-codesign
flutter build ios --release --no-codesign
```

Lệnh thứ hai kiểm tra build device unsigned; chưa tạo bản distribution hoặc upload TestFlight. Flutter bản này dùng CocoaPods; Swift Package Manager đang tắt trong pubspec của demo để dùng plugin podspec. Tool có cảnh báo về yêu cầu SwiftPM ở Flutter tương lai; chưa tuyên bố hỗ trợ các bản đó.

## 4. Test từ ứng dụng

1. Home phải hiện đúng điều kiện cấu hình/đăng nhập/sẵn sàng.
2. Bấm Đăng nhập, nhập User ID đã xác thực và API token account được cấp; không có tài khoản mặc định.
3. Bấm cấp quyền. canCall và canReceive là hai trạng thái riêng.
4. Bấm Gọi CSKH; app gọi businessNumber đã cấu hình và mở màn hình SDK.
5. Thử mic/loa/DTMF, về Home rồi Quay lại cuộc gọi; khi gác máy UI đóng về Home.
6. Đăng xuất rồi đăng nhập lại; token cũ không được giữ trong form.
7. Làm [checklist thiết bị](testing.md) cho nhận cuộc gọi, khóa máy, audio và đổi mạng.

## Khắc phục nhanh

- Thiếu package path: chạy install_sdk.py trước pub get.
- Checksum sai: lấy lại đúng archive và SHA256SUMS cùng bản; không bỏ qua xác minh.
- NATIVE_MODULE_NOT_LINKED: cài Pods/autolinking, build native lại; hot reload chưa đủ.
- NATIVE_BOOTSTRAP_REQUIRED/CONFIGURATION_MISMATCH: kiểm tra Application/AppDelegate, configure và build lại.
- Push chưa tới: kiểm tra package/Bundle, environment, Firebase/APNs credentials **server** và quyền OS.
- Request gọi timeout: chờ synchronize thành công trước khi gọi tiếp; không gọi lại tự động.
