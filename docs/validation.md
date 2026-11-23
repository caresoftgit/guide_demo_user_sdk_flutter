# Phạm vi và tiêu chí nghiệm thu Flutter 0.5.0

SDK/native core/UI 0.5.0; Flutter 3.50.1/Dart 3.14.0; Android API 26+, compileSdk 37, NDK 28.1.13356709, Gradle 9.5/AGP 9.3.1 với OpenJDK 25 cho build tools (source target 17); iOS 15.1+, Xcode 26.4/CocoaPods.

Người tích hợp đã xác nhận chạy thử demo Flutter trên Android A23 và iOS. Xác nhận này không thay kết quả riêng cho từng tình huống push, nền, cold start, khóa màn hình, Bluetooth, chuyển mạng và audio hai chiều trong [checklist](testing.md). Mỗi ứng dụng cần nghiệm thu lại với package/Bundle ID, signing, push, HTTP client và môi trường của chính mình.

Ghi phiên bản ứng dụng/SDK, OS/thiết bị, môi trường và kết quả trong báo cáo riêng của doanh nghiệp. Không đưa định danh khách hàng thật, credential, URL nội bộ hoặc log có token vào tài liệu public.

| Nhóm | Điều kiện đạt |
|---|---|
| Cài đặt | Checksum package đúng; Android/iOS build được với artifact native đi kèm |
| Cấu hình | Account/App/package/Bundle ID/push environment khớp; không có secret server trong app |
| Xác thực | Bootstrap qua phiên ứng dụng; user_id lấy ở server; ticket một lần và PKCE kiểm tra đầy đủ |
| HTTP client | TLS hợp lệ; không redirect/retry POST; deadline và giới hạn đọc 16 KiB trước buffer |
| Phiên | Restore/refresh/expiry đúng; Dart chỉ thấy metadata; chuyển tài khoản được tuần tự hóa |
| Logout | Dọn local; host logout chặn bootstrap; outbox bền vững retry/poll tới cleanup done |
| Gọi | Audio hai chiều, điều khiển, chống tạo trùng, trở lại call và kết thúc UI đúng |
| Push | Nhận/hủy foreground/background/khóa/cold start trên thiết bị thật |
| Mạng | UNKNOWN khi chưa xác minh; phục hồi hoặc kết thúc native đúng deadline |
| Riêng tư | Không lộ credential hoặc định danh nội bộ trong source/log/báo cáo |

Simulator/emulator và unit/build test không chứng minh push thực tế hoặc chất lượng âm thanh. `canReceive` chỉ phản ánh điều kiện sẵn sàng; Android Force stop có thể chặn FCM tới lần mở app tiếp theo. Delivery dùng CocoaPods; các cảnh báo về Swift Package Manager/Flutter tương lai không phải cam kết tương thích những toolchain đó.

Thực hiện [kiểm thử](testing.md), kiểm tra [API Dart](api.md) và [hợp đồng backend](host-bootstrap.md) trước phát hành. Android release template dùng debug signing để test local; iOS unsigned build chưa phải bản distribution.
