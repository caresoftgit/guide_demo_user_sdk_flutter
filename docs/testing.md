# Checklist nghiệm thu Flutter 0.5.0

Dùng cấu hình gateway/App/push/đầu số/signing và HTTP client của đơn vị tích hợp. Các hàng dưới đây là **tình huống cần kiểm thử**, không phải tuyên bố mọi tình huống đã đạt. Đối chiếu [hợp đồng host](host-bootstrap.md) và [phạm vi kiểm chứng](validation.md).

| Tình huống | Kết quả mong đợi |
|---|---|
| Chưa cấu hình/chưa callback | Home hướng dẫn cấu hình, Kết nối Voice bị khóa, không crash |
| Phiên ứng dụng → bootstrap | Transport tự gắn phiên hợp lệ; user_id lấy ở server; payload chỉ có bảy trường preparation |
| Không có phiên ứng dụng | HTTP 401 thành HOST_LOGIN_REQUIRED; quay về đăng nhập ứng dụng hiện có |
| Response lỗi | Helper từ chối attempt sai, ticket sai, expiry thiếu timezone/sai định dạng, URL đổi, body quá 16 KiB; không lộ raw body |
| Redirect/retry/deadline | HTTP client cấm redirect và retry POST, giới hạn đọc trước buffer và hủy I/O đúng deadline |
| Kết nối/restore | Hiện đúng khách hàng/readiness; mở lại app khôi phục native session |
| Ngắt Voice | Dọn phiên/preparation/call local, vẫn giữ đăng nhập ứng dụng |
| Logout ứng dụng | Cả SDK và app logout đều được gọi dù một bên lỗi; không bootstrap sau host logout |
| Chuyển tài khoản/race | Kết nối/ngắt/chuyển tài khoản được tuần tự hóa; response cũ không lưu phiên cho tài khoản mới |
| HOST-revoke offline | Outbox bền vững retry cùng UUID/payload; poll cleanup pending đến hoàn tất, kể cả server restart |
| Ticket hết hạn/đã dùng | Gateway từ chối exchange; tạo preparation/ticket mới, không retry ticket cũ |
| Refresh/expiry | SDK tự refresh; mất response retry cùng UUID trong cửa sổ; quá hạn cần bootstrap mới |
| Gọi CSKH | Đúng đầu số host; bấm liên tục không tạo call lặp |
| Request mất response | Khóa tạo mới đến khi synchronize thành công, không replay |
| Cuộc gọi vào | Foreground/background/cold start có UI SDK; không chờ Dart |
| Khóa máy | Notification/CallKit, trả lời/từ chối; không bypass PIN |
| Rời màn hình call | Âm thanh tiếp tục; Quay lại cuộc gọi mở đúng call, không tạo/answer lại |
| Kết thúc local/remote | Đóng UI/notification về Home, không mở lại call đã dừng |
| Micro/audio hai chiều | Tắt/bật nhiều lần, kiểm tra uplink/downlink liên tục |
| Audio routes | Loa thoại/ngoài/Bluetooth, chỉ báo theo route thực tế |
| DTMF | IVR nhận đúng digit |
| Wi-Fi ↔ di động | Hiện reconnect, khôi phục cùng call và mute |
| Mất media liên tục >30s | Dừng local, đóng UI, NETWORK_RECOVERY_TIMEOUT |
| Agent hủy/thiết bị khác trả lời | Thiết bị còn lại dừng ringing theo server/push |
| Hot restart/widget dispose | Không logout/hangup native; subscribe lại nhận snapshot hiện tại |
| Push token rotation | Đăng ký đúng session; response cũ không ghi đè phiên mới |
| Quyền bị từ chối/Activity đổi | Không treo Future, UI nêu điều kiện chưa sẵn sàng |
| Offline logout/hangup | Dừng local dù server chưa phản hồi; không tự replay mutation |

`canReceive` không bảo đảm push đã được provider chuyển. Android Force stop có thể chặn FCM đến khi mở lại app. APNs production cần iPhone ký production; sandbox cần cấu hình/profile phù hợp. Simulator/emulator kiểm tra bridge/UI và build, không thay thiết bị thật cho push nền, khóa máy hoặc chất lượng âm thanh.

Ghi OS, model, SDK version, thời điểm, mã lỗi và bước tái hiện trong báo cáo riêng. Nếu cần callId để điều tra, gửi qua kênh hỗ trợ được kiểm soát. Không đưa account/session/push token, ticket, verifier, private key, media credential hoặc URL nội bộ vào log công khai.
