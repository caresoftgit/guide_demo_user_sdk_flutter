# Checklist nghiệm thu Flutter

Luồng xác thực hiện tại: [phiên doanh nghiệp → ticket PKCE → SDK](host-bootstrap.md).

Dùng cấu hình gateway/App/push/đầu số/signing riêng. Không có tài khoản hoặc routing dùng sẵn trong bộ demo.

| Tình huống | Kết quả mong đợi |
|---|---|
| Chưa cấu hình | Home hướng dẫn cấu hình, khóa gọi/login, không crash |
| Login/restore | Hiện đúng khách hàng/readiness; mở lại app khôi phục native session |
| Logout/login khác | Dọn local/call khách cũ; form mới không giữ mật khẩu |
| Gọi CSKH | Đúng đầu số host; bấm liên tục không tạo call lặp |
| Request mất response | Khóa tạo mới đến khi synchronize thành công, không replay |
| Cuộc gọi vào | Foreground/background/cold start có UI SDK; không chờ Dart |
| Khóa máy | Notification/CallKit, trả lời/từ chối, không bypass PIN |
| Rời màn hình call | Âm thanh vẫn tiếp tục; Quay lại cuộc gọi mở đúng call, không tạo/answer |
| Kết thúc local/remote | Đóng UI/notification về Home, không mở lại call đã dừng |
| Micro | Tắt/bật nhiều lần, agent nghe lại được sau bật |
| Audio routes | Loa thoại/ngoài/Bluetooth, chỉ báo theo route thực tế |
| Audio hai chiều | Nói liên tục, kiểm tra uplink không giật/mất tiếng |
| DTMF | IVR nhận đúng digit |
| Wi-Fi ↔ di động | Hiện reconnect, khôi phục cùng call và mute |
| Mất media liên tục >30s | Dừng local, đóng UI, lỗi NETWORK_RECOVERY_TIMEOUT |
| Agent hủy / thiết bị khác trả lời | Thiết bị còn lại dừng ringing theo server/push |
| Hot restart / widget dispose | Không logout/hangup native; subscribe lại nhận snapshot hiện tại |
| Push token rotation | Đăng ký đúng session; response cũ không ghi đè phiên mới |
| Quyền bị từ chối/Activity đổi | Không treo Future, UI nêu điều kiện chưa sẵn sàng |
| Offline logout/hangup | Dừng local dù server chưa phản hồi; không tự replay |

canReceive không bảo đảm push đã được provider chuyển. Android force-stop có thể chặn FCM đến khi mở lại app. APNs production cần iPhone ký production; sandbox cần cấu hình/profile phù hợp. Simulator/emulator dùng kiểm thử bridge/UI/fixture, không xác nhận cuộc gọi thực tế hoặc chất lượng âm thanh.

Thu thập OS, model, SDK version, thời điểm, callId, mã lỗi và bước tái hiện. Không đưa account/session/push token, private key hoặc media credential vào log công khai. Xem [kết quả kiểm chứng](validation.md).
