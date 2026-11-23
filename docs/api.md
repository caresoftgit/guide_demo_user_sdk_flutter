# API Flutter Customer Voice 0.5.0

`import 'package:caresoft_customer_voice/caresoft_customer_voice.dart';`
Dùng `CustomerVoice.instance`. Native bootstrap trước Dart; `initialize(VoiceConfig)` chỉ xác nhận cấu hình trùng với native.

- Phiên: `prepareLogin()`, `loginWithTicket(attemptId, ticket)`, `logout()`, `checkReadiness()`, `resume()`, `getState()`, `synchronize()`.
- Gọi: `call(businessNumber)`, `answer(callId)`, `reject(callId)`, `hangup(callId)`, `showCall(callId)`.
- Audio: `setMuted(callId, bool)`, `getAvailableAudioRoutes(callId)`, `selectAudioRoute(callId, routeId)`, `sendDtmf(callId, digit)`.
- Push: `updatePushToken(token)`, `unregisterPushToken()`. Thường để bootstrap native quản lý.
- Quyền: `requestMicrophonePermission()`, `requestNotificationPermission()`, `canShowIncomingScreen()`, `requestIncomingScreenPermission()`.

Tất cả thao tác trả Future. `states` là Stream<VoiceState> có snapshot hiện tại và revision loại state cũ; `events` là Stream<VoiceEvent> tức thời, không replay. Hủy StreamSubscription hoặc `dispose()` chỉ dọn observer Dart, không kết thúc native session/cuộc gọi. Có thể subscribe lại sau dispose.

ID truyền chuỗi; các thời gian public là DateTime parse từ ISO8601; `CallSnapshot.version` giữ chuỗi. Đầu số 1–32 chữ số, có thể có `+` đầu. Host tự cấu hình đầu số được cấp; không có getDestinations, không truyền SIP URI/prefix routing.

VoiceState gồm `revision`, `sessionState` (`loggedOut`, `authenticated`, `loginRequired`), `readiness`, `calls`, `audioStates`, `connectionStates`. Collections chỉ đọc; không chứa token/payload push/media credential. Readiness phân biệt `isLoggedIn`, `canCall`, `canReceive`, `reasons`; `UNKNOWN` không đồng nghĩa logout. `canReceive` không bảo đảm push thực tế đã đến.

Chỉ `calls[].presentable` cho phép mở lại call. UI native tự đóng khi call kết thúc. CONNECTING/CONNECTED/RECONNECTING trong connectionStates; giữ mute khi phục hồi. Sau 30 giây mất media liên tục, native dừng local với NETWORK_RECOVERY_TIMEOUT. Không retry `call()` tự động; khi mất response khóa tạo mới đến khi `await synchronize()` thành công.

Bắt `CustomerVoiceException`, đọc `code` và `status` (0 khi không có HTTP status). Không dùng message gốc của network. LOGIN_REQUIRED/UNAUTHORIZED cần xin ticket mới qua phiên ứng dụng hợp lệ; HOST_LOGIN_REQUIRED từ helper demo yêu cầu luồng đăng nhập ứng dụng hiện có; NATIVE_MODULE_NOT_LINKED cần build native/Pods; NATIVE_BOOTSTRAP_REQUIRED/CONFIGURATION_MISMATCH cần sửa bootstrap; ACTIVITY_REQUIRED/HOST_VIEW_REQUIRED cần host UI sẵn sàng. LOGOUT_REVOKE_UNCONFIRMED vẫn giữ trạng thái local đã logout. ROUTE_UNAVAILABLE cần đọc lại danh sách route. INVALID_NATIVE_RESPONSE là payload bridge không đúng contract. Không replay mutation khi lỗi.

`requestNotificationPermission` xin POST_NOTIFICATIONS Android 13+ hoặc quyền thông báo thường iOS; quyền này không thay quyền/đăng ký PushKit/CallKit. Android full-screen đặc biệt do canShowIncomingScreen/requestIncomingScreenPermission; iOS không có quyền full-screen tương đương. Token APNs thường forward riêng từ AppDelegate.

## Callback bootstrap của demo

`VoiceDemoApp(config: DemoConfig(...), requestTicket: callback)` nhận callback tùy chọn có kiểu `Future<String> Function(LoginPreparation)`; không callback thì Kết nối Voice bị khóa. Đây là giao diện demo, không phải API SDK. Callback nhận bảy trường preparation công khai, trả ticket một lần; không nhận hoặc trả token phiên Voice.

Helper `HostBackend(bootstrapUrl, transport: transport).requestTicket` trong `lib/host_backend.dart` gọi endpoint HTTPS đầy đủ qua HTTP client đã xác thực của ứng dụng. `HostTransport` nhận `(Uri endpoint, Map<String, String> headers, String body)`, trả `Future<HostResponse>` với `statusCode`, URL cuối `url` và `body`. Transport tự gắn phiên ứng dụng và áp TLS/không redirect/không retry POST/deadline/giới hạn đọc; helper không quản lý xác thực doanh nghiệp. Xem [payload và các giới hạn](host-bootstrap.md).

Nút Ngắt Voice gọi SDK `logout()`; logout ứng dụng phải luôn thực hiện cả SDK và logout doanh nghiệp, kể cả một bước lỗi, cùng cơ chế HOST-revoke bền vững ở backend.
