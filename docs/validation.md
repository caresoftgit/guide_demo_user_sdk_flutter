# Kiểm chứng bộ Flutter 0.1.0

Kiểm chứng ngày 20/11/2026. Flutter 3.50.1 / Dart 3.14.0, JDK 17, Xcode 26.4, CocoaPods 1.16.2. Shared native Android core/UI 0.4.2 và iOS 0.1.2, 330 file có SHA-256 trùng bộ native đã kiểm chứng.

| Hạng mục | Kết quả |
|---|---|
| SDK Dart | 10 tests đạt: forwarding, lỗi an toàn, snapshot/revision, detach/reattach, không replay, quyền thông báo |
| Demo Dart/widget | 11 tests đạt: readiness/Home, call hiện tại, create mơ hồ, đồng bộ, form token và lỗi đăng nhập chỉ hiển thị mã an toàn |
| Android Kotlin | 9 tests đạt: push rotation/session/retry/opt-out, quyền bị ngắt, callback cũ, Activity detach |
| Native bridge Android API 35 | 2 tests đạt trên emulator trước khi chuyển sang máy thật: snapshot/observer và lỗi bootstrap/envelope |
| Native bridge iOS 18.3 | 2 tests đạt trên Simulator: snapshot/observer và lỗi bootstrap/envelope |
| Keychain iOS host | 1 XCTest ghi–đọc mục thử riêng đạt trên Simulator với Signing Team/Bundle ID hợp lệ; không xóa phiên SDK |
| Static analysis | SDK và demo không có vấn đề |
| Android | Debug và release R8/resource shrinking build đạt; bản ARM64 release cài/mở trên Samsung A23 Android 14 |
| iOS | Build Simulator debug và device release không ký đạt; Home/form login mở trên Simulator. Kiểm tra thủ công khôi phục cửa sổ khi dùng lại Bundle ID từ host không có storyboard đạt |
| Gói bàn giao | Cài từ archive có checksum, kiểm tra 330 native hashes, resources/privacy/licenses và archive lồng nhau |
| Quét thông tin | Source/demo/archive và lịch sử commit local không chứa các giá trị test nội bộ đã biết hoặc credential/key riêng |

A23 dùng bản cấu hình test riêng ngoài repo bàn giao. Đã kiểm tra cài/mở giao diện và form đăng nhập; chưa kết luận nghiệm thu gọi hai chiều, APNs/FCM, khóa màn hình, audio hoặc Wi-Fi/di động cho Flutter. Làm [checklist](testing.md) trên Android/iPhone thật với cấu hình của đơn vị tích hợp.

Bản build dùng NDK 28.1.13356709 như native hiện có. Flutter integration_test phát cảnh báo NDK 28.2.13676358; các bản build/test nêu trên vẫn đạt. Host nâng NDK cần kiểm thử lại. Flutter cũng cảnh báo tương lai yêu cầu Android built-in Kotlin và iOS Swift Package Manager; bản này đã kiểm chứng trên toolchain ghim với Kotlin Gradle Plugin/CocoaPods, chưa tuyên bố hỗ trợ toolchain tương lai.
