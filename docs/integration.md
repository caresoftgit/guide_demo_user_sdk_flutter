# Tích hợp Customer Voice vào Flutter

## 1. Chuẩn bị thông tin

| Thông tin | Lấy ở đâu / sử dụng |
|---|---|
| Gateway HTTPS URL | Caresoft cấp; dùng URL gốc, không thêm `/api/v1/voice` |
| Account ID | Caresoft cấp; truyền chuỗi |
| Caresoft App ID | Tạo ở bước 2; khác Firebase App ID và Apple Bundle ID |
| User ID | Khách hàng đã được ứng dụng xác thực; chuỗi số 1–4294967295 |
| Account API token | Caresoft cấp an toàn; chỉ truyền khi login, không đóng vào ứng dụng |
| Đầu số CSKH | Caresoft cấp sau khi định tuyến; ứng dụng tự cấu hình và truyền vào call |
| Package/Bundle ID, Firebase hoặc Apple signing | Đơn vị tích hợp quản lý; khớp cấu hình push server |

SDK không xác thực thay ứng dụng. Token account xác thực tích hợp account, không chứng minh danh tính User ID; chỉ cấp thông tin login sau luồng xác thực khách hàng của host, thống nhất cách cấp production với Caresoft. Không lưu token trong source, preferences, config, analytics hoặc log. Không truyền SIP URI/prefix hoặc IP tổng đài từ mobile.

Phiên bản đã kiểm chứng: Flutter 3.50.1 / Dart 3.14.0; Android API 26+, compileSdk 37, JDK 17; iOS 15.1+, Xcode 26.4, CocoaPods. Demo ghim NDK 28.1.13356709. Chưa tuyên bố tương thích mọi Flutter version; Web/desktop không thuộc plugin này.

## 2. Tạo App Caresoft và cấu hình push

1. Đăng nhập trang quản trị Caresoft đúng môi trường.
2. Vào **Admin Settings → Cơ bản → Voice SDK**; nếu chưa thấy, nhờ quản trị viên cấp quyền.
3. Tạo App, nhập tên, bật **Hoạt động**, lưu rồi sao chép **App ID** do Caresoft sinh.
4. Android: thêm cấu hình **Android/FCM** đúng package cuối cùng. Firebase Console → Project settings → Service accounts → Generate new private key. Nhập JSON service-account đầy đủ vào cấu hình **server Caresoft**; không đưa file này vào app.
5. iOS: thêm **iOS/APNs VoIP**, điền Bundle ID, Apple Team ID, Key ID và APNs environment. Tạo/chọn APNs key trong Apple Developer → Certificates, Identifiers & Profiles → Keys; nhập nội dung PEM đầy đủ của `.p8` vào cấu hình **server Caresoft**.
6. Lưu và bật cấu hình push. Có thể dùng chung App ID Caresoft cho Android/iOS; mỗi platform/package/environment có cấu hình riêng. Mobile không truyền `push_config_id` và không nhận private key.
7. APNs production dành cho TestFlight/distribution; development/sandbox phải khớp profile development. VoIP topic là `<bundle-id>.voip`, notification thường là `<bundle-id>` để cập nhật/hủy call. Nếu giao diện thiếu trường, nhờ quản trị bổ sung phía server.

## 3. Thêm package Flutter

Lấy archive `caresoft_customer_voice-0.1.0.tar.gz` trong bộ demo, kiểm tra SHA256SUMS, giải nén vào `vendor/` bằng `python3 scripts/install_sdk.py`. Trong dự án host, dùng cùng cấu trúc hoặc điều chỉnh path:

```yaml
dependencies:
  caresoft_customer_voice:
    path: vendor/caresoft_customer_voice-0.1.0
flutter:
  config:
    enable-swift-package-manager: false
```

Chạy `flutter pub get`. Archive có đủ bridge và artifacts native; không thêm LiveKit/WebRTC/CallKeep khác cho cùng chức năng. Source repo chưa chạy prepare-native không phải package hoàn chỉnh để cài trực tiếp.

Android: khai báo repository trong `android/build.gradle.kts` hoặc nơi host quản lý repositories tập trung:

```kotlin
allprojects {
    repositories {
        google()
        mavenCentral()
        maven { url = uri(rootProject.file("../vendor/caresoft_customer_voice-0.1.0/android/maven")) }
        maven { url = uri("https://jitpack.io") }
    }
}
```

Đặt minSdk 26+, compileSdk 37; giữ Java/Kotlin toolchain phù hợp host. Demo dùng AGP/Gradle theo template Flutter đã ghim. Không thêm bản native SDK khác với manifest. iOS chạy `cd ios && pod install`, mở `Runner.xcworkspace`; không chỉ mở xcodeproj.

## 4. Bootstrap Android trước Dart

Trong `Application.onCreate()` trên main thread:

```kotlin
import vn.caresoft.customervoice.flutter.VoiceBootstrap
VoiceBootstrap.initialize(this, gatewayUrl, accountId, caresoftAppId, "Chăm sóc khách hàng")
```

Khai báo Application này trong AndroidManifest. Bootstrap chỉ có config không bí mật; không có account token. Trong FirebaseMessagingService **hiện có của host**:

```kotlin
override fun onMessageReceived(message: RemoteMessage) {
    if (!VoiceBootstrap.handleRemoteMessage(message.data)) {
        // Xử lý thông báo khác của ứng dụng.
    }
}
override fun onNewToken(token: String) {
    VoiceBootstrap.onNewPushToken(token)
}
```

Khi khởi tạo Firebase, lấy token hiện tại qua `FirebaseMessaging.getInstance().token`, forward vào `VoiceBootstrap.onNewPushToken`. Native tự đăng ký theo session sau login/restore, xử lý rotation và retry sau resume/control reconnect. Không chờ Dart isolate.

Chỉ một service FCM dispatch message; không thêm service thứ hai tranh message. Host giữ cấu hình Firebase client; demo dùng FirebaseOptions nên không cần Google Services plugin/JSON client. Firebase service-account/private key chỉ ở server. Cần INTERNET và POST_NOTIFICATIONS trong manifest host; core/UI tự merge quyền/media/notification service tương ứng. Xem `android/app/` để tham khảo.

## 5. Bootstrap iOS trước Dart

Trong `AppDelegate.application(_:didFinishLaunchingWithOptions:)`, trước `super`:

```swift
import caresoft_customer_voice
try VoiceBootstrap.initialize(
    backendURL: URL(string: gatewayUrl)!, accountID: accountId, appID: caresoftAppId,
    supportName: "Chăm sóc khách hàng", environment: .production
)
```

Giữ GeneratedPluginRegistrant theo template Flutter. SDK sở hữu PushKit registry mặc định. Nếu host đã có registry, dùng `managesPushKit:false`, import `CustomerVoice` và forward token/payload/completion vào core `updatePushToken`/`handleVoIPPush`; không tạo registry thứ hai hoặc đi qua Dart trước khi report CallKit. Hoàn tất completion đúng một lần.

Forward APNs thường từ AppDelegate:

```swift
override func application(_ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken token: Data) {
    VoiceBootstrap.didRegisterForRemoteNotifications(deviceToken: token)
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: token)
}
override func application(_ application: UIApplication,
    didReceiveRemoteNotification payload: [AnyHashable: Any],
    fetchCompletionHandler done: @escaping (UIBackgroundFetchResult) -> Void) {
    Task { @MainActor in
        if await VoiceBootstrap.handleRemoteNotification(payload) { done(.newData) }
        else { super.application(application, didReceiveRemoteNotification: payload,
                                 fetchCompletionHandler: done) }
    }
}
```

Khi root UIViewController sẵn sàng, gọi `VoiceBootstrap.attach(to: rootController)`. Khi scene/app active, gọi `VoiceBootstrap.resume()`. Demo triển khai ở SceneDelegate; app không dùng scenes đặt cùng bước vào lifecycle tương ứng. Đừng dùng Dart build() làm nơi khởi tạo CallKit/push.

Bật **Push Notifications** và **Background Modes → Audio, Voice over IP, Remote notifications**. Khai báo NSMicrophoneUsageDescription; giữ NSCameraUsageDescription như mẫu vì thư viện media tham chiếu API camera dù bản gọi thoại không truy cập camera. Không tự xin quyền camera. Cấu hình aps-environment và signing khớp môi trường server; xem demo Info.plist/entitlements, dùng Team/Bundle ID riêng. Simulator kiểm thử đăng nhập cũng cần signing/app identity đúng để ghi Keychain; `--no-codesign` chỉ dùng kiểm tra build, không thay bản chạy nghiệm thu.

## 6. Initialize và quan sát state Dart

```dart
import 'package:caresoft_customer_voice/caresoft_customer_voice.dart';
final voice = CustomerVoice.instance;
final subscription = voice.states.listen((state) {
  // sessionState, readiness, calls, audioStates, connectionStates.
}, onError: (Object error) {
  // CustomerVoiceException: xử lý code, không ghi credential vào log.
});
await voice.initialize(VoiceConfig(
  backendUrl: gatewayUrl, accountId: accountId, appId: caresoftAppId,
  pushEnvironment: 'production',
));
```

Config phải trùng native; initialize chỉ kiểm tra, không thay bootstrap. Subscribe nhận snapshot hiện tại và thay đổi mới, revision ngăn response cũ ghi đè state mới. Events chỉ tức thời; sau hot restart dựng UI từ state đầy đủ. `subscription.cancel()` và `dispose()` chỉ dọn observers Dart, không logout/hangup. Widget chỉ hủy subscriptions do mình tạo; không dispose singleton nếu nơi khác vẫn dùng.

## 7. Login, quyền, readiness

```dart
await voice.login(authenticatedCustomerId, accountApiToken);
await voice.requestMicrophonePermission(); // từ thao tác người dùng
await voice.requestNotificationPermission();
final ready = await voice.checkReadiness();
// ready.isLoggedIn / ready.canCall / ready.canReceive / ready.reasons
```

Native giữ session bằng Keychain/Keystore và tự restore; host không lưu account token để login lại khi offline. `UNKNOWN` là chưa xác minh được, không phải logout. canReceive còn phụ thuộc push/quyền; không chứng minh push thực tế đã tới.

Android 14+ kiểm tra `canShowIncomingScreen()` và mở `requestIncomingScreenPermission()` từ thao tác người dùng. Không bypass PIN hoặc hứa nhận FCM sau Force stop. iOS dùng CallKit; quyền notification thường khác với PushKit/CallKit. Permission yêu cầu Activity/UIView host sẵn sàng.

## 8. Gọi CSKH, nhận và quay lại call

```dart
if ((await voice.checkReadiness()).canCall) {
  await voice.call(assignedBusinessNumber);
}
// Khi Home có call còn presentable:
await voice.showCall(presentableCallId);
```

Đầu số là chuỗi 1–32 chữ số, có thể có `+` đầu; do host giữ sau khi được cấp. Không có getDestinations. Khóa nút khi tạo call; nếu request timeout/mất response, không retry. Giữ khóa đến khi `await voice.synchronize()` thành công. Attach/restart cũng chờ đồng bộ trước khi tạo mới. Demo có helper CallAttempt.

SDK tự mở UI native: trả lời/từ chối/gác, mic, audio route theo OS, DTMF. Incoming nền/khóa màn hình đi qua notification/CallKit trước Dart. Không auto-answer từ widget bind. Khi kết thúc local/remote, UI đóng về Home dù signaling chưa phản hồi. showCall chỉ mở call còn presentable; không tạo/answer lại call.

ConnectionStates phản ánh CONNECTING/CONNECTED/RECONNECTING. Khi đổi mạng giữ cùng call/mute; mất media liên tục 30 giây thì dừng local, đóng UI và phát NETWORK_RECOVERY_TIMEOUT. Không gọi lại call từ reconnect event. Chỉ mất control socket không nhất thiết dừng media còn tốt. ACTIVE theo trạng thái gateway hiện có; IVR/hàng đợi tự trả lời có thể là mốc ACTIVE trước agent.

## 9. Foreground và logout

Khi app trở lại resumed, gọi `voice.resume()`; không tự login hoặc tạo call. Khi logout:

```dart
await voice.logout();
```

Native dọn local trước khi revoke server. LOGOUT_REVOKE_UNCONFIRMED vẫn là local đã logout; không phục hồi phiên cũ. Theo dõi loggedOut/loginRequired để quay về luồng xác thực host. Form đăng nhập chỉ là tiện ích demo; production tích hợp trong login của ứng dụng.

## 10. Build và nghiệm thu

Làm theo [chạy demo](demo.md) và [checklist thiết bị](testing.md). Unit/build/simulator không thay nghiệm thu audio, APNs/FCM, khóa màn hình và chuyển Wi-Fi/di động trên thiết bị thật. Không tự upload TestFlight/pub.dev khi build local.
