import 'dart:async';
import 'dart:convert';

import 'package:caresoft_customer_voice/caresoft_customer_voice.dart';

/// Supplied by the application after its existing authentication flow.
typedef RequestTicket = Future<String> Function(LoginPreparation preparation);

/// The application's client owns authentication, cancellation, redirect policy
/// and response limits before buffering. Never log authentication bodies.
typedef HostTransport = Future<HostResponse> Function(
  Uri endpoint,
  Map<String, String> headers,
  String body,
);

class HostResponse {
  const HostResponse({
    required this.statusCode,
    required this.url,
    required this.body,
  });
  final int statusCode;
  final Uri url;
  final String body;
}

/// Demo adapter for an already authenticated application HTTP client.
class HostBackend {
  HostBackend(this.bootstrapUrl, {required this.transport});
  final String bootstrapUrl;
  final HostTransport transport;

  Future<String> requestTicket(LoginPreparation p) async {
    final endpoint = Uri.tryParse(bootstrapUrl);
    if (endpoint == null ||
        endpoint.scheme != 'https' ||
        endpoint.host.isEmpty ||
        endpoint.userInfo.isNotEmpty ||
        endpoint.hasQuery ||
        endpoint.hasFragment) {
      throw CustomerVoiceException('HTTPS_HOST_REQUIRED');
    }
    final payload = {
      'attempt_id': p.attemptId,
      'installation_id': p.installationId,
      'os': p.platform,
      'application_id': p.applicationId,
      'push_environment': p.pushEnvironment,
      'code_challenge': p.codeChallenge,
      'code_challenge_method': p.codeChallengeMethod,
    };
    try {
      return await (() async {
        final response = await transport(endpoint, const {
          'Content-Type': 'application/json',
          'Cache-Control': 'no-store',
        }, jsonEncode(payload));
        if (response.url != endpoint) {
          throw CustomerVoiceException('BOOTSTRAP_REQUEST_FAILED');
        }
        if (response.statusCode == 401) {
          throw CustomerVoiceException('HOST_LOGIN_REQUIRED');
        }
        if (response.statusCode < 200 || response.statusCode >= 300) {
          throw CustomerVoiceException('BOOTSTRAP_REQUEST_FAILED');
        }
        if (utf8.encode(response.body).length > 16384) {
          throw CustomerVoiceException('INVALID_BOOTSTRAP_RESPONSE');
        }
        dynamic ticket;
        try {
          ticket = jsonDecode(response.body);
        } catch (_) {
          throw CustomerVoiceException('INVALID_BOOTSTRAP_RESPONSE');
        }
        final expiry = ticket is Map ? ticket['expires_at'] : null;
        if (ticket is! Map ||
            ticket['attempt_id'] != p.attemptId ||
            ticket['login_ticket'] is! String ||
            !RegExp(r'^[A-Za-z0-9_-]{43}$')
                .hasMatch(ticket['login_ticket'] as String) ||
            expiry is! String ||
            !RegExp(
              r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d{1,9})?(?:Z|[+-]\d{2}:\d{2})$',
            ).hasMatch(expiry) ||
            DateTime.tryParse(expiry) == null) {
          throw CustomerVoiceException('INVALID_BOOTSTRAP_RESPONSE');
        }
        return ticket['login_ticket'] as String;
      })().timeout(const Duration(seconds: 5));
    } on CustomerVoiceException {
      rethrow;
    } catch (_) {
      throw CustomerVoiceException('BOOTSTRAP_REQUEST_FAILED');
    }
  }
}
