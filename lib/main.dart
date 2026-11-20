import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:caresoft_customer_voice/caresoft_customer_voice.dart';

import 'home_model.dart';
import 'call_attempt.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = DemoConfig(
    jsonDecode(await rootBundle.loadString('lib/voice_config.json'))
        as Map<String, dynamic>,
  );
  runApp(VoiceDemoApp(config: config));
}

class VoiceDemoApp extends StatelessWidget {
  const VoiceDemoApp({super.key, required this.config, this.voice});
  final DemoConfig config;
  final CustomerVoiceClient? voice;
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Customer Voice',
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff1473c9)),
      scaffoldBackgroundColor: const Color(0xfff5f8fc),
      useMaterial3: true,
    ),
    home: VoiceHome(config: config, voice: voice ?? CustomerVoice.instance),
  );
}

class VoiceHome extends StatefulWidget {
  const VoiceHome({super.key, required this.config, required this.voice});
  final DemoConfig config;
  final CustomerVoiceClient voice;
  @override
  State<VoiceHome> createState() => _VoiceHomeState();
}

class _VoiceHomeState extends State<VoiceHome> with WidgetsBindingObserver {
  VoiceState? _state;
  bool _busy = false, _blocked = true, _fullScreen = true;
  String _error = '';
  StreamSubscription<VoiceState>? _states;
  StreamSubscription<VoiceEvent>? _events;
  late final CallAttempt _attempt;
  CustomerVoiceClient get voice => widget.voice;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _attempt = CallAttempt(
      create: () async {
        await voice.call(widget.config.businessNumber);
      },
      synchronize: () async {
        _accept(await voice.synchronize());
      },
      changed: (blocked) {
        if (mounted) setState(() => _blocked = blocked);
      },
    );
    _states = voice.states.listen(_accept, onError: _showError);
    _events = voice.events.listen((e) {
      if (e.type == 'error') {
        _showError(CustomerVoiceException(e.code ?? 'VOICE_OPERATION_FAILED'));
      }
    }, onError: _showError);
    if (widget.config.configured) unawaited(_start());
  }

  void _accept(VoiceState state) {
    if (mounted && (_state == null || state.revision > _state!.revision)) {
      setState(() => _state = state);
    }
  }

  void _showError(Object error) {
    if (!mounted) return;
    final code = error is CustomerVoiceException
        ? error.code
        : 'VOICE_OPERATION_FAILED';
    setState(
      () => _error = switch (code) {
        'LOGIN_REQUIRED' => 'Bạn cần đăng nhập để sử dụng.',
        'UNAUTHORIZED' => 'Thông tin đăng nhập không hợp lệ.',
        'NETWORK_RECOVERY_TIMEOUT' =>
          'Cuộc gọi đã kết thúc vì không khôi phục được kết nối.',
        'MICROPHONE_PERMISSION_REQUIRED' => 'Bạn cần cấp quyền micro.',
        'NATIVE_BOOTSTRAP_REQUIRED' || 'CONFIGURATION_MISMATCH' =>
          'Cấu hình native chưa sẵn sàng. Hãy kiểm tra cấu hình và build lại.',
        'LOGOUT_REVOKE_UNCONFIRMED' =>
          'Đã đăng xuất trên máy. Server chưa xác nhận thu hồi phiên.',
        _ => 'Không thực hiện được. Kiểm tra kết nối và thử lại.',
      },
    );
  }

  Future<void> _start() async {
    try {
      await voice.initialize(widget.config.sdk);
      await _attempt.synchronize();
      await _screenPermission();
    } on CustomerVoiceException catch (e) {
      if (e.code != 'LOGIN_REQUIRED') _showError(e);
    }
  }

  Future<void> _screenPermission() async {
    final allowed = await voice.canShowIncomingScreen();
    if (mounted) setState(() => _fullScreen = allowed);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && widget.config.configured) {
      unawaited(voice.resume().catchError(_showError));
      unawaited(_screenPermission().catchError(_showError));
    }
  }

  Future<void> _action(Future<void> Function() work) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = '';
    });
    try {
      await work();
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _permissions() => _action(() async {
    await voice.requestMicrophonePermission();
    await voice.requestNotificationPermission();
    await voice.resume();
    await voice.checkReadiness();
  });
  Future<void> _login() async {
    final credentials = await showDialog<(String, String)>(
      context: context,
      builder: (_) => const _LoginDialog(),
    );
    if (credentials != null && mounted) {
      await _action(() async {
        await voice.login(credentials.$1, credentials.$2);
        await _attempt.synchronize();
      });
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text(
          'Kết thúc phiên và các cuộc gọi trên thiết bị này?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) await _action(() => voice.logout());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_states?.cancel());
    unawaited(_events?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final model = HomeModel(
      _state,
      busy: _busy || _blocked,
      configured: widget.config.configured,
    );
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  const Text(
                    'caresoft',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: Color(0xff1473c9),
                    ),
                  ),
                  const Text(
                    'Kết nối để phục vụ tốt hơn',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: Colors.blueGrey),
                  ),
                  const SizedBox(height: 38),
                  const Text(
                    'Trung tâm hỗ trợ',
                    style: TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff172b46),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Trao đổi trực tiếp với bộ phận chăm sóc khách hàng.',
                    style: TextStyle(fontSize: 15, color: Colors.blueGrey),
                  ),
                  const SizedBox(height: 20),
                  Card(
                    elevation: 0,
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(21),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.circle,
                                size: 10,
                                color: model.canCall
                                    ? Colors.green
                                    : Colors.orange,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  model.status,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (model.loggedIn)
                            Text(
                              'Khách hàng: ${_state!.sessionState.session!.userId}',
                            ),
                          Text(
                            model.activeCallId != null
                                ? 'Cuộc gọi vẫn tiếp tục khi bạn rời màn hình gọi'
                                : model.canReceive
                                ? 'Đã sẵn sàng nhận cuộc gọi'
                                : 'Chưa sẵn sàng nhận cuộc gọi',
                            style: const TextStyle(color: Colors.blueGrey),
                          ),
                          if (model.showReadinessHint)
                            const Text(
                              'Kiểm tra quyền micro, thông báo và kết nối để sẵn sàng.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.blueGrey,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  FilledButton(
                    key: Key(
                      model.activeCallId == null
                          ? 'call-support'
                          : 'return-call',
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.all(26),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    onPressed: model.activeCallId != null
                        ? (_busy
                              ? null
                              : () => _action(
                                  () => voice.showCall(model.activeCallId!),
                                ))
                        : model.canCall
                        ? () => _action(() => _attempt.call())
                        : null,
                    child: Column(
                      children: [
                        const Icon(Icons.call, size: 36),
                        const SizedBox(height: 8),
                        Text(
                          model.activeCallId != null
                              ? 'Quay lại cuộc gọi'
                              : 'Gọi CSKH',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          model.activeCallId != null
                              ? 'Mở màn hình cuộc gọi đang diễn ra'
                              : 'Chúng tôi luôn sẵn sàng lắng nghe',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  if (!widget.config.configured)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'Điền cấu hình của ứng dụng theo README, chạy configure rồi build lại demo.',
                        style: TextStyle(color: Colors.blueGrey),
                      ),
                    ),
                  if (_blocked && !_busy && model.loggedIn)
                    TextButton(
                      onPressed: () => _action(() => _attempt.synchronize()),
                      child: const Text('Đồng bộ cuộc gọi trước khi gọi tiếp'),
                    ),
                  if (_error.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        _error,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  if (_busy) const Center(child: CircularProgressIndicator()),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _busy || !widget.config.configured
                        ? null
                        : model.loggedIn
                        ? _logout
                        : _login,
                    child: Text(model.loggedIn ? 'Đăng xuất' : 'Đăng nhập'),
                  ),
                  if (widget.config.configured)
                    TextButton(
                      onPressed: _busy ? null : _permissions,
                      child: const Text('Cấp quyền micro và thông báo'),
                    ),
                  if (!_fullScreen && widget.config.configured)
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => _action(
                              () => voice.requestIncomingScreenPermission(),
                            ),
                      child: const Text('Cho phép cuộc gọi trên màn hình khóa'),
                    ),
                  const SizedBox(height: 18),
                  const Text(
                    'Customer Voice · Flutter · 0.1.0',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.blueGrey),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginDialog extends StatefulWidget {
  const _LoginDialog();
  @override
  State<_LoginDialog> createState() => _LoginDialogState();
}

class _LoginDialogState extends State<_LoginDialog> {
  final user = TextEditingController();
  final token = TextEditingController();
  @override
  void dispose() {
    user.clear();
    token.clear();
    user.dispose();
    token.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    scrollable: true,
    title: const Text('Đăng nhập khách hàng'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Thông tin được ứng dụng cấp để sử dụng Voice SDK.'),
        const SizedBox(height: 16),
        TextField(
          key: const Key('login-user'),
          controller: user,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'User ID'),
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('login-token'),
          controller: token,
          obscureText: true,
          autocorrect: false,
          enableSuggestions: false,
          decoration: const InputDecoration(labelText: 'API token'),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () {
          token.clear();
          Navigator.pop(context);
        },
        child: const Text('Hủy'),
      ),
      TextButton(
        onPressed: () {
          if (user.text.isNotEmpty && token.text.isNotEmpty) {
            final value = (user.text, token.text);
            token.clear();
            Navigator.pop(context, value);
          }
        },
        child: const Text('Đăng nhập'),
      ),
    ],
  );
}
