# Phạm vi kiểm chứng Flutter 0.5.0

SDK/native core/UI 0.5.0; Flutter 3.50.1, Dart 3.14.0, Android JDK 17/API 26+, iOS 15.1+/Xcode 26.4.

- SDK: 15 Dart tests, analyze sạch; archive verify đạt 330 checksum native cùng kiểm tra privacy/resources/licenses.
- Demo: 15 unit/widget tests; analyze sạch; Android debug APK và iOS simulator Debug build thành công.
- Đã biên dịch thật Kotlin và Swift bridge với binary 0.5.0. Enterprise login → ticket PKCE → SDK; không còn form user_id/API token.
- Chưa nghiệm thu phiên bản này trên thiết bị thật: gọi hai chiều, push, nền, khóa màn hình, đổi mạng và chất lượng âm thanh cần test riêng từng platform. Xem [hợp đồng host](host-bootstrap.md) và [checklist](testing.md).
- Delivery dùng CocoaPods; Flutter cảnh báo hỗ trợ SPM tương lai. Android build có cảnh báo integration_test cần NDK mới hơn, build hiện tại đạt với NDK đã ghim.

## Hồ sơ lịch sử trước migration

Thông tin bên dưới là kết quả bản cũ, **không phải bằng chứng nghiệm thu 0.5.0**.

# Phạm vi kiểm chứng Flutter 0.1.0

## Nền tảng và phiên bản

| Thành phần | Phiên bản |
|---|---|
| Flutter / Dart | 3.50.1 / 3.14.0 |
| Android | API 26+, compileSdk 37, JDK 17 |
| Android core / UI | 0.4.2 / 0.4.2 |
| iOS | 15.1+, Xcode 26.4, CocoaPods 1.16.2 |
| iOS core / UI | 0.1.2 |

Plugin hỗ trợ Android và iOS. Chưa hỗ trợ Flutter Web/desktop hoặc cam kết tương thích mọi phiên bản Flutter.

## Kiểm tra kỹ thuật

- SDK Dart: 10 tests về forwarding, lỗi an toàn, snapshot/revision, detach/reattach, không replay và quyền thông báo.
- Demo Dart/widget: 11 tests về readiness, cuộc gọi hiện tại, request gọi mất response, đồng bộ và form đăng nhập không lưu token.
- Bridge Kotlin: 9 tests về push rotation/session/retry/opt-out, quyền bị ngắt và Activity detach.
- Native bridge Android/iOS: 4 integration tests về snapshot/observer và lỗi bootstrap/envelope.
- iOS Keychain: kiểm tra ghi–đọc mục thử với app identity/signing hợp lệ; không xóa phiên SDK.
- Static analysis SDK/demo; build Android debug/release R8 và iOS Simulator/device.
- Archive cài đặt có checksum và 330 SHA-256 native; giữ resources, privacy manifest và third-party licenses.

Bản demo iOS đã được người dùng xác nhận test thành công. Xác nhận này không thay kết quả riêng cho từng tình huống trong [checklist nghiệm thu](testing.md). Đơn vị tích hợp cần kiểm tra lại gọi hai chiều, push, khóa màn hình, mic/audio route và đổi mạng với package/Bundle ID, signing, cấu hình push và môi trường của mình.

## Giới hạn cần lưu ý

- Simulator phù hợp kiểm tra bridge/UI/đăng nhập; không thay iPhone thật cho APNs, CallKit khi khóa máy và chất lượng âm thanh.
- `canReceive` phản ánh điều kiện sẵn sàng, không bảo đảm push đã được provider chuyển tới thiết bị.
- Android force-stop có thể chặn FCM cho đến khi mở lại ứng dụng.
- Demo ghim NDK 28.1.13356709. Plugin `integration_test` có cảnh báo NDK mới hơn; các build đã kiểm chứng vẫn đạt. Khi đổi NDK/toolchain, kiểm thử lại.
- Bản này dùng Kotlin Gradle Plugin và CocoaPods. Các cảnh báo về Android built-in Kotlin/Swift Package Manager trong Flutter tương lai chưa phải cam kết hỗ trợ các toolchain đó.
