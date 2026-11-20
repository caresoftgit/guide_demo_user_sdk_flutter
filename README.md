# Customer Voice — Flutter demo và tích hợp

SDK/demo **0.1.0** cho khách hàng gọi CSKH và nhận cuộc gọi trên Android/iOS. Giao diện Home Flutter; màn hình nghe/gọi, Telecom/CallKit và media do SDK native cung cấp.

1. Đọc [hướng dẫn tích hợp](docs/integration.md), tạo App Caresoft và cấu hình push cho đúng package/Bundle ID.
2. Cài Flutter **3.50.1 / Dart 3.14.0**, JDK 17 và Android toolchain hoặc Xcode 26.4/CocoaPods.
3. Chạy `python3 scripts/install_sdk.py` để kiểm tra checksum và cài gói SDK vào `vendor/`. Không cần clone source SDK native.
4. Chép `config/voice.example.json` thành `config/voice.local.json`, điền cấu hình ứng dụng. Không thêm API token account vào file.
5. Chạy `python3 scripts/configure.py`, `flutter pub get`, rồi làm theo [chạy demo](docs/demo.md).
6. Cấp quyền, nhập User ID/API token trong form đăng nhập của demo và thực hiện [checklist nghiệm thu](docs/testing.md).

Gói SDK dùng shared native Android core/UI 0.4.2 và iOS 0.1.2. Đầu số do ứng dụng tự cấu hình sau khi được cấp; không có getDestinations. Demo không có dialer hoặc trạng thái agent.

Bộ bàn giao chỉ chứa cấu hình mẫu. Không có server/IP, đầu số, user/account test, token, Firebase project, Apple Team, thông tin ký hoặc đường dẫn máy build nội bộ. Account token chỉ nhập lúc login; private key push chỉ cấu hình trên server Caresoft. Không đưa các file local/generated vào Git.

- [Tích hợp từng bước](docs/integration.md)
- [API Dart](docs/api.md)
- [Chạy demo Android/iOS](docs/demo.md)
- [Nghiệm thu thiết bị](docs/testing.md)
- [Kiểm chứng và giới hạn](docs/validation.md)

Chỉ hỗ trợ Android/iOS, không Flutter Web/desktop. Bản này dùng CocoaPods cho iOS; Flutter có thông báo về Swift Package Manager trong các phiên bản tương lai. Không tự publish pub.dev hoặc upload TestFlight.
