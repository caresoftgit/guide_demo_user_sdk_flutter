import 'package:caresoft_customer_voice/caresoft_customer_voice.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final voice = CustomerVoice.instance;
  testWidgets(
    'native snapshot and observer reattach preserve logged-out state',
    (tester) async {
      final initial = await voice.getState();
      expect(initial.sessionState.status, 'loggedOut');
      expect(initial.readiness.canCall, false);
      expect(initial.readiness.canReceive, false);
      expect(initial.calls, isEmpty);
      final subscription = voice.states.listen((_) {});
      await subscription.cancel();
      final reattached = await voice.states.first;
      expect(reattached.sessionState.status, 'loggedOut');
      expect(reattached.revision, greaterThan(initial.revision));
      await voice.dispose();
      expect((await voice.getState()).sessionState.status, 'loggedOut');
    },
  );
  testWidgets('unconfigured native bootstrap returns safe typed error', (
    tester,
  ) async {
    await expectLater(
      voice.initialize(
        const VoiceConfig(
          backendUrl: 'https://voice.example.com',
          accountId: 'example',
          appId: 'example',
        ),
      ),
      throwsA(
        isA<CustomerVoiceException>().having(
          (e) => e.code,
          'code',
          'NATIVE_BOOTSTRAP_REQUIRED',
        ),
      ),
    );
    try {
      await const MethodChannel('caresoft.customer_voice/methods')
          .invokeMethod<void>('execute', {'method': 'initialize'});
      fail('invalid envelope must fail');
    } on PlatformException catch (error) {
      expect(error.code, 'INVALID_ARGUMENT');
      expect(error.message, 'INVALID_ARGUMENT');
    }
  });
}
