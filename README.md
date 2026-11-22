# Customer Voice — Flutter demo và tích hợp

Xem [luồng đăng nhập doanh nghiệp và ticket PKCE](docs/host-bootstrap.md) trước khi tích hợp.

SDK/demo **0.5.0** cho khách hàng gọi CSKH và nhận cuộc gọi trên Android/iOS. Giao diện Home Flutter; màn hình nghe/gọi, Telecom/CallKit và media do SDK native cung cấp.

```sh
git clone https://github.com/caresoftgit/guide_demo_user_sdk_flutter.git
cd guide_demo_user_sdk_flutter
```

1. Đọc [hướng dẫn tích hợp](docs/integration.md), tạo App Caresoft và cấu hình push cho đúng package/Bundle ID.
2. Cài Flutter **3.50.1 / Dart 3.14.0**, JDK 17 và Android toolchain hoặc Xcode 26.4/CocoaPods.
3. Chạy `python3 scripts/install_sdk.py` để kiểm tra checksum và cài gói SDK vào `vendor/`. Không cần clone source SDK native.
4. Chép `config/voice.example.json` thành `config/voice.local.json`, điền cấu hình ứng dụng. Không thêm API token account vào file.
5. Chạy `python3 scripts/configure.py`, `flutter pub get`, rồi làm theo [chạy demo](docs/demo.md).
6. Cấp quyền, nhập username/password doanh nghiệp trong form demo và thực hiện [checklist nghiệm thu](docs/testing.md).

Gói SDK dùng shared native Android core/UI 0.5.0 và iOS 0.5.0. Đầu số do ứng dụng tự cấu hình sau khi được cấp; không có getDestinations. Demo không có dialer hoặc trạng thái agent.

Bộ demo chỉ chứa cấu hình mẫu và package/Bundle ID `com.example.customervoicedemo`. Thay bằng thông tin ứng dụng của đơn vị tích hợp. Account token chỉ nhập lúc login; private key push chỉ cấu hình trên server Caresoft. Không đưa các file local/generated vào Git. Form đăng nhập là công cụ test; ứng dụng thực tế cấp phiên từ luồng xác thực của mình.

- [Tích hợp từng bước](docs/integration.md)
- [API Dart](docs/api.md)
- [Chạy demo Android/iOS](docs/demo.md)
- [Nghiệm thu thiết bị](docs/testing.md)
- [Kiểm chứng và giới hạn](docs/validation.md)
- [Source SDK Flutter](https://github.com/caresoftgit/user_voice_sdk_flutter)

Chỉ hỗ trợ Android/iOS, không Flutter Web/desktop. Bản này dùng CocoaPods cho iOS; Flutter có thông báo về Swift Package Manager trong các phiên bản tương lai. Bản build phát hành cần cấu hình signing và push riêng của ứng dụng.

Cấu hình thêm URL backend doanh nghiệp HTTPS (`enterpriseBackendUrl`; iOS: `VOICE_ENTERPRISE_BACKEND_URL`; Android: `demo_default_enterprise_backend`). Đăng nhập bằng tài khoản doanh nghiệp test, không nhập ID khách hàng hay API token. Xem `docs/host-bootstrap.md` và helper enterprise session trong source.
