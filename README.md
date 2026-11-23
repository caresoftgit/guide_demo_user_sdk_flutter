# Customer Voice — Flutter demo và tích hợp

SDK/demo **0.5.0** cho Android/iOS, dùng native core/UI và phiên Voice protocol 2. Ứng dụng đăng nhập doanh nghiệp theo hệ thống đang có; backend lấy `user_id` Caresoft từ principal đã xác thực và cấp ticket PKCE. Demo nhận callback xin ticket qua HTTP client đã xác thực, không thu username/password/API token và không kèm backend đăng nhập doanh nghiệp.

- [Chạy demo](docs/demo.md): cài gói, cấu hình công khai, Android/iOS và inject callback.
- [Tích hợp từng bước](docs/integration.md): native bootstrap, push, readiness, UI nghe/gọi.
- [Payload và quản lý phiên](docs/host-bootstrap.md): sơ đồ, request/response, bảo mật, TTL/refresh/logout và outbox.
- [API Dart](docs/api.md), [kiểm thử thiết bị](docs/testing.md) và [tiêu chí nghiệm thu](docs/validation.md).
- [Source SDK Flutter](https://github.com/caresoftgit/user_voice_sdk_flutter).

```sh
git clone https://github.com/caresoftgit/guide_demo_user_sdk_flutter.git
cd guide_demo_user_sdk_flutter
shasum -a 256 -c packages/SHA256SUMS
python3 scripts/install_sdk.py
cp config/voice.example.json config/voice.local.json
```

Điền cấu hình ứng dụng, chạy `python3 scripts/configure.py`, `flutter pub get`, rồi làm theo [hướng dẫn demo](docs/demo.md) để inject `requestTicket` và build native. Mặc định `main()` chưa inject callback nên nút **Kết nối Voice** bị khóa. Đây là điểm tích hợp HTTP client của khách hàng; điền URL bootstrap chưa đủ để kết nối.

Toolchain: Flutter **3.50.1 / Dart 3.14.0**, Android API 26+, compileSdk 37, NDK 28.1.13356709, Gradle 9.5/AGP 9.3.1 và **OpenJDK 25** để chạy build tools; Java/Kotlin source target vẫn là 17. iOS cần 15.1+, Xcode 26.4 và CocoaPods. Gói SDK trong `packages/` đã có artifact Android/iOS, resource, privacy manifest, license và checksum; không cần clone source native.

Cấu hình mẫu dùng địa chỉ ví dụ và package/Bundle ID `com.example.customervoicedemo`. Cấu hình riêng đặt trong `config/voice.local.json` bị Git bỏ qua; chỉ chứa URL/ID/đầu số và Firebase client config công khai. Credential tích hợp, Customer REST token và private key push chỉ ở server. Không commit cấu hình triển khai hoặc dữ liệu tài khoản thật.

Home dùng Flutter; cuộc gọi, Telecom/CallKit và media dùng UI native SDK. Chỉ hỗ trợ Android/iOS, không Flutter Web/desktop. Demo không có dialer, trạng thái agent hoặc API lấy danh sách đầu số; ứng dụng giữ đầu số đã được cấp. Bản phát hành cần signing và cấu hình push của chính ứng dụng.
