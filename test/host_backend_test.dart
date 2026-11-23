import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:caresoft_customer_voice/caresoft_customer_voice.dart';
import 'package:customer_voice_demo/host_backend.dart';

final preparation = LoginPreparation.fromMap({
  'attemptId': '550e8400-e29b-41d4-a716-446655440000',
  'installationId': '550e8400-e29b-41d4-a716-446655440001',
  'platform': 'android',
  'applicationId': 'com.example.customerapp',
  'pushEnvironment': 'default',
  'codeChallenge': 'a' * 43,
  'codeChallengeMethod': 'S256',
});
final endpoint = Uri.parse('https://app.example.com/api/voice/bootstrap');
Map<String, Object?> ticket() => {
  'attempt_id': preparation.attemptId,
  'login_ticket': 't' * 43,
  'expires_at': '2030-01-01T00:00:00Z',
};
Matcher code(String value) =>
    isA<CustomerVoiceException>().having((e) => e.code, 'code', value);
void main() {
  test(
    'uses application transport and sends only public PKCE metadata',
    () async {
      final backend = HostBackend(
        endpoint.toString(),
        transport: (url, headers, body) async {
          expect(url, endpoint);
          expect(headers['Cache-Control'], 'no-store');
          expect(jsonDecode(body), {
            'attempt_id': preparation.attemptId,
            'installation_id': preparation.installationId,
            'os': 'android',
            'application_id': 'com.example.customerapp',
            'push_environment': 'default',
            'code_challenge': 'a' * 43,
            'code_challenge_method': 'S256',
          });
          expect(headers.containsKey('Authorization'), false);
          return HostResponse(
            statusCode: 200,
            url: url,
            body: jsonEncode(ticket()),
          );
        },
      );
      expect(await backend.requestTicket(preparation), 't' * 43);
    },
  );
  test('invalid endpoint never reaches application transport', () async {
    for (final url in [
      'http://app.example.com/bootstrap',
      'https://user:secret@app.example.com/bootstrap',
      'https://app.example.com/bootstrap?token=secret',
      'https://app.example.com/bootstrap#fragment',
    ]) {
      var sent = false;
      final host = HostBackend(
        url,
        transport: (url, headers, body) async {
          sent = true;
          return HostResponse(
            statusCode: 200,
            url: url,
            body: jsonEncode(ticket()),
          );
        },
      );
      await expectLater(
        host.requestTicket(preparation),
        throwsA(code('HTTPS_HOST_REQUIRED')),
      );
      expect(sent, false);
    }
  });
  test('401 asks host to use its existing login; errors never expose response bodies', () async {
    for (final status in [401, 403, 500]) {
      final host = HostBackend(
        endpoint.toString(),
        transport: (url, headers, body) async => HostResponse(
          statusCode: status,
          url: url,
          body: 'private server response',
        ),
      );
      await expectLater(
        host.requestTicket(preparation),
        throwsA(
          code(
            status == 401 ? 'HOST_LOGIN_REQUIRED' : 'BOOTSTRAP_REQUEST_FAILED',
          ),
        ),
      );
    }
  });
  test(
    'rejects redirected, oversized, malformed and mismatched bootstrap replies',
    () async {
      final replies = [
        HostResponse(
          statusCode: 200,
          url: Uri.parse('https://other.example.com/bootstrap'),
          body: jsonEncode(ticket()),
        ),
        HostResponse(statusCode: 200, url: endpoint, body: 'x' * 16385),
        HostResponse(
          statusCode: 200,
          url: endpoint,
          body: jsonEncode({'payload': 'ộ' * 6000}),
        ),
        HostResponse(statusCode: 200, url: endpoint, body: 'not json'),
        HostResponse(statusCode: 200, url: endpoint, body: '[]'),
        HostResponse(
          statusCode: 200,
          url: endpoint,
          body: jsonEncode({...ticket(), 'attempt_id': 'another-attempt'}),
        ),
        HostResponse(
          statusCode: 200,
          url: endpoint,
          body: jsonEncode({...ticket(), 'login_ticket': 'invalid'}),
        ),
        HostResponse(
          statusCode: 200,
          url: endpoint,
          body: jsonEncode({...ticket(), 'expires_at': 'tomorrow'}),
        ),
        HostResponse(
          statusCode: 200,
          url: endpoint,
          body: jsonEncode({...ticket(), 'expires_at': '2030-01-01T00:00:00'}),
        ),
      ];
      for (final reply in replies) {
        final host = HostBackend(
          endpoint.toString(),
          transport: (url, headers, body) async => reply,
        );
        await expectLater(
          host.requestTicket(preparation),
          throwsA(isA<CustomerVoiceException>()),
        );
      }
    },
  );
  test(
    'late network failure is reduced to a safe code without replay',
    () async {
      var count = 0;
      final host = HostBackend(
        endpoint.toString(),
        transport: (url, headers, body) async {
          count++;
          throw StateError('private connection details');
        },
      );
      await expectLater(
        host.requestTicket(preparation),
        throwsA(code('BOOTSTRAP_REQUEST_FAILED')),
      );
      expect(count, 1);
    },
  );
}
