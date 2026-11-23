import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:caresoft_customer_voice/caresoft_customer_voice.dart';
import 'package:customer_voice_demo/main.dart';
import 'package:customer_voice_demo/home_model.dart';

import 'support.dart';

DemoConfig config() => DemoConfig({
  'backendUrl': 'https://voice.example.com',
  'bootstrapUrl': 'https://app.example.com/api/voice/bootstrap',
  'accountId': '42',
  'appId': 'example-app',
  'businessNumber': '18001234',
});

class RejectedLoginTransport extends DemoTransport {
  @override
  Future<Object?> execute(String method, Map<String, Object?> args) async {
    if (method == 'prepareLogin') {
      throw PlatformException(
        code: 'APP_NOT_FOUND',
        message: 'private response must stay hidden',
      );
    }
    return super.execute(method, args);
  }
}

class EventTransport extends DemoTransport {
  final notifications = StreamController<Object?>.broadcast(sync: true);
  @override
  Stream<Object?> get events => notifications.stream;
}

void main() {
  testWidgets('login transition is not a failure; real errors remain visible', (
    tester,
  ) async {
    final t = EventTransport()
      ..state = stateMap(loggedIn: true, ready: true, receive: true);
    await tester.pumpWidget(
      VoiceDemoApp(config: config(), voice: CustomerVoiceClient(t)),
    );
    await tester.pumpAndSettle();
    t.notifications.add({'type': 'error', 'code': 'LOGIN_PENDING'});
    await tester.pumpAndSettle();
    expect(find.textContaining('LOGIN_PENDING'), findsNothing);
    expect(find.text('Sẵn sàng gọi CSKH'), findsOneWidget);
    t.notifications.add({'type': 'error', 'code': 'SESSION_REVOKED'});
    await tester.pumpAndSettle();
    expect(find.textContaining('SESSION_REVOKED'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await t.notifications.close();
    await t.changes.close();
  });
  testWidgets(
    'connect uses host ticket callback, no login form or automatic call',
    (tester) async {
      final t = DemoTransport();
      var requested = 0;
      await tester.pumpWidget(
        VoiceDemoApp(
          config: config(),
          voice: CustomerVoiceClient(t),
          requestTicket: (p) async {
            requested++;
            expect(p.platform, 'android');
            return 't' * 43;
          },
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsNothing);
      await tester.tap(find.text('Kết nối Voice'));
      await tester.pumpAndSettle();
      expect(requested, 1);
      expect(t.operations, contains('loginWithTicket'));
      expect(t.operations, isNot(contains('call')));
      expect(find.text('Ngắt Voice'), findsOneWidget);
      await tester.tap(find.text('Ngắt Voice'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Ngắt Voice').last);
      await tester.pumpAndSettle();
      expect(t.operations, contains('logout'));
      expect(find.text('Kết nối Voice'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await t.changes.close();
    },
  );
  testWidgets('missing host callback keeps connect disabled', (tester) async {
    final t = DemoTransport();
    await tester.pumpWidget(
      VoiceDemoApp(config: config(), voice: CustomerVoiceClient(t)),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextButton>(find.widgetWithText(TextButton, 'Kết nối Voice'))
          .onPressed,
      isNull,
    );
    expect(find.byType(TextField), findsNothing);
    expect(t.operations, isNot(contains('prepareLogin')));
    await tester.pumpWidget(const SizedBox());
    await t.changes.close();
  });
  testWidgets('connection failure exposes only safe native code', (
    tester,
  ) async {
    final t = RejectedLoginTransport();
    await tester.pumpWidget(
      VoiceDemoApp(
        config: config(),
        voice: CustomerVoiceClient(t),
        requestTicket: (_) async => 't' * 43,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kết nối Voice'));
    await tester.pumpAndSettle();
    expect(find.textContaining('APP_NOT_FOUND'), findsOneWidget);
    expect(find.textContaining('private response'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await t.changes.close();
  });
  testWidgets('unmounted screen discards late host ticket before exchange', (
    tester,
  ) async {
    final t = DemoTransport();
    final response = Completer<String>();
    await tester.pumpWidget(
      VoiceDemoApp(
        config: config(),
        voice: CustomerVoiceClient(t),
        requestTicket: (_) => response.future,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kết nối Voice'));
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    response.complete('t' * 43);
    await tester.pumpAndSettle();
    expect(t.operations, isNot(contains('loginWithTicket')));
    await t.changes.close();
  });
  testWidgets('empty public configuration shows setup without a dialer', (
    tester,
  ) async {
    final t = DemoTransport();
    await tester.pumpWidget(
      VoiceDemoApp(config: DemoConfig({}), voice: CustomerVoiceClient(t)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Cần cấu hình ứng dụng'), findsOneWidget);
    expect(find.text('Gọi CSKH'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await t.changes.close();
  });
  testWidgets(
    'return button opens existing call without creating or answering',
    (tester) async {
      final t = DemoTransport()
        ..state = stateMap(loggedIn: true, presentable: true);
      await tester.pumpWidget(
        VoiceDemoApp(config: config(), voice: CustomerVoiceClient(t)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('return-call')));
      await tester.pumpAndSettle();
      expect(t.operations, contains('showCall'));
      expect(t.operations, isNot(contains('call')));
      expect(t.operations, isNot(contains('answer')));
      await tester.pumpWidget(const SizedBox());
      await t.changes.close();
    },
  );
}
