import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:caresoft_customer_voice/caresoft_customer_voice.dart';
import 'package:customer_voice_demo/main.dart';
import 'package:customer_voice_demo/home_model.dart';

import 'support.dart';

void main() {
  testWidgets('empty public configuration shows setup and no dialer', (
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
  testWidgets('return button opens existing call without create or answer', (
    tester,
  ) async {
    final t = DemoTransport()
      ..state = stateMap(loggedIn: true, presentable: true);
    await tester.pumpWidget(
      VoiceDemoApp(
        config: DemoConfig({
          'backendUrl': 'https://voice.example.com',
          'accountId': '42',
          'appId': 'example-app',
          'businessNumber': '18001234',
        }),
        voice: CustomerVoiceClient(t),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('return-call')));
    await tester.pumpAndSettle();
    expect(t.operations, contains('showCall'));
    expect(t.operations, isNot(contains('call')));
    expect(t.operations, isNot(contains('answer')));
    await tester.pumpWidget(const SizedBox());
    await t.changes.close();
  });
  testWidgets('dismissed login never keeps previous token', (tester) async {
    final t = DemoTransport();
    await tester.pumpWidget(
      VoiceDemoApp(
        config: DemoConfig({
          'backendUrl': 'https://voice.example.com',
          'accountId': '42',
          'appId': 'example-app',
          'businessNumber': '18001234',
        }),
        voice: CustomerVoiceClient(t),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đăng nhập'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('login-token')),
      'ephemeral-example',
    );
    await tester.tap(find.text('Hủy'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đăng nhập'));
    await tester.pumpAndSettle();
    final field = tester.widget<TextField>(
      find.byKey(const Key('login-token')),
    );
    expect(field.controller!.text, isEmpty);
    await tester.tap(find.text('Hủy'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
    await t.changes.close();
  });
}
