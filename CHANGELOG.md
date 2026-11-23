# Changelog

## 0.5.0

- Tích hợp SDK/native core/UI 0.5.0 và phiên Voice protocol 2: prepareLogin → ticket PKCE từ backend doanh nghiệp → loginWithTicket.
- Demo nhận `requestTicket` từ ứng dụng đã xác thực; không thu username/password, user_id hoặc API token và không kèm backend đăng nhập doanh nghiệp.
- Helper `HostBackend` nhận transport của HTTP client ứng dụng, ánh xạ payload và kiểm tra response; cấu hình `bootstrapUrl` là endpoint HTTPS đầy đủ.
- Kết nối Voice/Ngắt Voice chỉ quản lý phiên SDK; hướng dẫn logout ứng dụng, chuyển tài khoản và outbox HOST-revoke bền vững ở backend.
- Hướng dẫn bootstrap native trước Dart, FCM/APNs/CallKit, readiness, UI gọi, refresh/expiry, bảo mật và nghiệm thu Android/iOS.
- Gói SDK có checksum và native artifact; mẫu cấu hình dùng thông tin trung tính, không kèm thông tin triển khai riêng.
- Toolchain demo: Flutter 3.50.1/Dart 3.14, compileSdk 37, NDK 28.1, Gradle 9.5/AGP 9.3.1 với OpenJDK 25; iOS 15.1+, Xcode 26.4/CocoaPods.

## 0.1.0

- Demo khách hàng Android/iOS với UI gọi native, readiness, push và hướng dẫn tích hợp.
