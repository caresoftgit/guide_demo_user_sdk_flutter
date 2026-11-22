import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:caresoft_customer_voice/caresoft_customer_voice.dart';
import 'package:customer_voice_demo/enterprise_session.dart';

final preparation = LoginPreparation.fromMap({
  'attemptId': '550e8400-e29b-41d4-a716-446655440000',
  'installationId': '550e8400-e29b-41d4-a716-446655440001',
  'platform': 'android',
  'applicationId': 'com.example.voice',
  'pushEnvironment': 'default',
  'codeChallenge': 'a' * 43,
  'codeChallengeMethod': 'S256',
});
void main() {
  test(
    'bootstrap sends public PKCE binding and never takes a customer ID',
    () async {
      final calls = <Map<String, Object?>>[];
      final tickets = <String>[];
      final session = EnterpriseSession(
        'https://host.example',
        prepare: () async => preparation,
        exchange: (a, t) async {
          tickets.add(t);
        },
        nativeLogout: () async {},
        transport: (route, body, bearer) async {
          calls.add({'route': route, 'body': body, 'bearer': bearer});
          return route.endsWith('/login')
              ? {'enterprise_access_token': 'host-token'}
              : {'attempt_id': preparation.attemptId, 'login_ticket': 't' * 43};
        },
      );
      await session.login('customer', 'password');
      expect(calls[1]['bearer'], 'host-token');
      expect(calls[1]['body'], {
        'attempt_id': preparation.attemptId,
        'installation_id': preparation.installationId,
        'os': 'android',
        'application_id': 'com.example.voice',
        'push_environment': 'default',
        'code_challenge': 'a' * 43,
        'code_challenge_method': 'S256',
      });
      expect(tickets, ['t' * 43]);
    },
  );
  test(
    'late enterprise response after logout cannot start native login',
    () async {
      final response = Completer<Map<String, dynamic>>();
      var prepared = false;
      final revoked = <String?>[];
      final session = EnterpriseSession(
        'https://host.example',
        prepare: () async {
          prepared = true;
          return preparation;
        },
        exchange: (a, t) async {},
        nativeLogout: () async {},
        transport: (route, body, bearer) async {
          if (route.endsWith('/login')) return response.future;
          revoked.add(bearer);
          return {};
        },
      );
      final pending = session.login('customer', 'password');
      final rejected = expectLater(
        pending,
        throwsA(
          isA<CustomerVoiceException>().having(
            (e) => e.code,
            'code',
            'LOGIN_ATTEMPT_SUPERSEDED',
          ),
        ),
      );
      await session.logout();
      response.complete({'enterprise_access_token': 'late-token'});
      await rejected;
      expect(prepared, false);
      expect(revoked, ['late-token']);
    },
  );
  test('native revoke failure still attempts host logout and offline host can retry', () async {
    var offline = false;
    final revoked = <String?>[];
    final session = EnterpriseSession(
      'https://host.example',
      prepare: () async => preparation,
      exchange: (a, t) async {},
      nativeLogout: () async {
        throw CustomerVoiceException('LOGOUT_REVOKE_UNCONFIRMED');
      },
      transport: (route, body, bearer) async {
        if (route.endsWith('/login')) {
          return {'enterprise_access_token': 'host-token'};
        }
        if (route.endsWith('/bootstrap')) {
          return {
            'attempt_id': preparation.attemptId,
            'login_ticket': 't' * 43,
          };
        }
        revoked.add(bearer);
        if (offline) throw Exception('private transport details');
        return {};
      },
    );
    await session.login('name', 'password');
    offline = true;
    await expectLater(
      session.logout(),
      throwsA(
        isA<CustomerVoiceException>().having(
          (e) => e.code,
          'code',
          'HOST_LOGOUT_PENDING',
        ),
      ),
    );
    expect(session.pendingLogout, true);
    offline = false;
    await session.retryLogout();
    expect(revoked, ['host-token', 'host-token']);
    expect(session.pendingLogout, false);
  });
  test('delayed logout never revokes the next enterprise login', () async {
    final gate = Completer<void>();
    final revoked = <String?>[];
    var count = 0;
    final host = EnterpriseSession(
      'https://host.example',
      prepare: () async => preparation,
      exchange: (a, t) async {},
      nativeLogout: () => gate.future,
      transport: (route, body, bearer) async {
        if (route.endsWith('/logout')) {
          revoked.add(bearer);
          return {};
        }
        if (route.endsWith('/login')) {
          return {'enterprise_access_token': 'host-${++count}'};
        }
        return {'attempt_id': preparation.attemptId, 'login_ticket': 't' * 43};
      },
    );
    await host.login('A', 'password');
    final logout = host.logout();
    await host.login('B', 'password');
    gate.complete();
    await logout;
    expect(revoked, ['host-1', 'host-1']);
    await host.retryLogout();
    expect(revoked.last, 'host-2');
  });
}
