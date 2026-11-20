import 'package:flutter_test/flutter_test.dart';
import 'package:caresoft_customer_voice/caresoft_customer_voice.dart';
import 'package:customer_voice_demo/home_model.dart';

import 'support.dart';

void main() {
  test('unconfigured blocks login and calling', () {
    final m = HomeModel(null, busy: false, configured: false);
    expect(m.canCall, false);
    expect(m.status, 'Cần cấu hình ứng dụng');
  });
  test('ready customer can call and receive independently', () {
    final m = HomeModel(
      VoiceState.fromMap(stateMap(loggedIn: true, ready: true)),
      busy: false,
      configured: true,
    );
    expect(m.loggedIn, true);
    expect(m.canCall, true);
    expect(m.canReceive, false);
  });
  test('presentable call opens return path rather than create', () {
    final m = HomeModel(
      VoiceState.fromMap(
        stateMap(
          loggedIn: true,
          ready: true,
          presentable: true,
          reasons: ['CALL_IN_PROGRESS'],
        ),
      ),
      busy: false,
      configured: true,
    );
    expect(m.activeCallId, 'call-example');
    expect(m.canCall, false);
    expect(m.showReadinessHint, false);
  });
  test('reconnect is visible independently of readiness', () {
    final m = HomeModel(
      VoiceState.fromMap(
        stateMap(loggedIn: true, presentable: true, reconnecting: true),
      ),
      busy: false,
      configured: true,
    );
    expect(m.status, 'Đang kết nối lại…');
  });
}
