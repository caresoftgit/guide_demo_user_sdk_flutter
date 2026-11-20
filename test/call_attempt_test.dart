import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:customer_voice_demo/call_attempt.dart';

void main() {
  test('rapid taps create once', () async {
    final done = Completer<void>();
    var count = 0;
    final a = CallAttempt(
      create: () async {
        count++;
        await done.future;
      },
      synchronize: () async {},
      changed: (_) {},
      initiallyBlocked: false,
    );
    final pending = a.call();
    await a.call();
    expect(count, 1);
    done.complete();
    await pending;
  });
  test('ambiguous create and failed sync keep new calls blocked', () async {
    var creates = 0;
    final a = CallAttempt(
      create: () async {
        creates++;
        throw StateError('timeout');
      },
      synchronize: () async {
        throw StateError('offline');
      },
      changed: (_) {},
      initiallyBlocked: false,
    );
    await expectLater(a.call(), throwsStateError);
    expect(a.blocked, true);
    await a.call();
    expect(creates, 1);
  });
  test('explicit sync unblocks only after native response', () async {
    final done = Completer<void>();
    final a = CallAttempt(
      create: () async {},
      synchronize: () => done.future,
      changed: (_) {},
      initiallyBlocked: true,
    );
    final pending = a.synchronize();
    expect(a.blocked, true);
    done.complete();
    await pending;
    expect(a.blocked, false);
  });
}
