import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:caresoft_customer_voice/caresoft_customer_voice.dart';

typedef EnterpriseTransport = Future<Map<String, dynamic>> Function(
  String route,
  Map<String, Object?> body,
  String? bearer,
);

/// Host-app example only. The enterprise bearer stays in memory.
/// The enterprise backend derives the Caresoft user ID from its own login.
class EnterpriseSession {
  EnterpriseSession(
    this.hostUrl, {
    required this.prepare,
    required this.exchange,
    required this.nativeLogout,
    this.transport,
  });
  final String hostUrl;
  final Future<LoginPreparation> Function() prepare;
  final Future<void> Function(String, String) exchange;
  final Future<void> Function() nativeLogout;
  final EnterpriseTransport? transport;
  String? _token;
  int _epoch = 0;
  bool _loggingIn = false;
  bool pendingLogout = false;
  Never _error(String code) => throw CustomerVoiceException(code);
  void _current(int version) {
    if (version != _epoch) _error('LOGIN_ATTEMPT_SUPERSEDED');
  }

  Future<Map<String, dynamic>> _request(
    String route,
    Map<String, Object?> body, [
    String? bearer,
  ]) async {
    final base = Uri.tryParse(hostUrl);
    if (base == null ||
        base.scheme != 'https' ||
        base.host.isEmpty ||
        base.userInfo.isNotEmpty ||
        base.hasQuery ||
        base.hasFragment) {
      _error('HTTPS_HOST_REQUIRED');
    }
    try {
      if (transport != null) {
        return await transport!(
          route,
          body,
          bearer,
        ).timeout(const Duration(seconds: 5));
      }
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 5);
      try {
        return await (() async {
          final request = await client.postUrl(
            Uri.parse('${hostUrl.replaceFirst(RegExp(r'/$'), '')}$route'),
          );
          request.followRedirects = false;
          request.headers.contentType = ContentType.json;
          if (bearer != null) {
            request.headers.set(
              HttpHeaders.authorizationHeader,
              'Bearer $bearer',
            );
          }
          request.write(jsonEncode(body));
          final response = await request.close();
          if (response.statusCode < 200 || response.statusCode >= 300) {
            _error('ENTERPRISE_REQUEST_FAILED');
          }
          final bytes = <int>[];
          await for (final chunk in response) {
            bytes.addAll(chunk);
            if (bytes.length > 16384) _error('INVALID_ENTERPRISE_RESPONSE');
          }
          if (route == '/api/auth/logout') return <String, dynamic>{};
          final value = jsonDecode(utf8.decode(bytes));
          if (value is! Map<String, dynamic>) {
            _error('INVALID_ENTERPRISE_RESPONSE');
          }
          return value;
        })().timeout(const Duration(seconds: 5));
      } finally {
        client.close(force: true);
      }
    } catch (_) {
      _error('ENTERPRISE_REQUEST_FAILED');
    }
  }

  Future<void> retryLogout() => _revoke(_token);
  Future<void> _revoke(String? bearer) async {
    if (bearer == null) return;
    if (_token == bearer) pendingLogout = true;
    try {
      await _request('/api/auth/logout', {}, bearer);
      if (_token == bearer) {
        _token = null;
        pendingLogout = false;
      }
    } catch (_) {
      _error('HOST_LOGOUT_PENDING');
    }
  }

  Future<void> login(String username, String password) async {
    if (_loggingIn) _error('LOGIN_IN_PROGRESS');
    _loggingIn = true;
    final version = ++_epoch;
    try {
      if (_token != null) await retryLogout();
      _current(version);
      final auth = await _request('/api/auth/login', {
        'username': username,
        'password': password,
      });
      final bearer = auth['enterprise_access_token'];
      if (bearer is! String || bearer.isEmpty) {
        _error('INVALID_ENTERPRISE_RESPONSE');
      }
      _token = bearer;
      if (version != _epoch) {
        try {
          await retryLogout();
        } catch (_) {}
        _current(version);
      }
      final prep = await prepare();
      _current(version);
      final ticket = await _request('/api/voice/bootstrap', {
        'attempt_id': prep.attemptId,
        'installation_id': prep.installationId,
        'os': prep.platform,
        'application_id': prep.applicationId,
        'push_environment': prep.pushEnvironment,
        'code_challenge': prep.codeChallenge,
        'code_challenge_method': prep.codeChallengeMethod,
      }, _token);
      _current(version);
      if (ticket['attempt_id'] != prep.attemptId ||
          ticket['login_ticket'] is! String) {
        _error('INVALID_ENTERPRISE_RESPONSE');
      }
      await exchange(prep.attemptId, ticket['login_ticket'] as String);
      _current(version);
    } finally {
      _loggingIn = false;
    }
  }

  Future<void> logout() async {
    final captured = _token;
    ++_epoch;
    Object? nativeFailure;
    try {
      await nativeLogout();
    } catch (e) {
      nativeFailure = e;
    }
    await _revoke(captured);
    if (nativeFailure != null) throw nativeFailure;
  }
}
