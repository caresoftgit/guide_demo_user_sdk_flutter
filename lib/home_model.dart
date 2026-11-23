import 'package:caresoft_customer_voice/caresoft_customer_voice.dart';

class DemoConfig {
  DemoConfig(this.values);
  final Map<String, dynamic> values;
  String get businessNumber => values['businessNumber'] as String? ?? '';
  String get bootstrapUrl => values['bootstrapUrl'] as String? ?? '';
  VoiceConfig get sdk => VoiceConfig(
    backendUrl: values['backendUrl'] as String? ?? '',
    accountId: values['accountId'] as String? ?? '',
    appId: values['appId'] as String? ?? '',
    supportName: values['supportName'] as String? ?? 'Chăm sóc khách hàng',
    pushEnvironment: values['pushEnvironment'] as String? ?? 'production',
  );
  bool get configured =>
      sdk.backendUrl.startsWith('https://') &&
      bootstrapUrl.startsWith('https://') &&
      sdk.accountId.isNotEmpty &&
      sdk.appId.isNotEmpty &&
      RegExp(r'^\+?[0-9]{1,32}$').hasMatch(businessNumber);
}

class HomeModel {
  HomeModel(this.state, {required this.busy, required this.configured});
  final VoiceState? state;
  final bool busy, configured;
  bool get loggedIn => state?.sessionState.status == 'authenticated';
  String? get activeCallId {
    final calls = state?.calls.where((c) => c.presentable);
    return calls == null || calls.isEmpty ? null : calls.last.callId;
  }

  bool get canCall =>
      configured &&
      !busy &&
      activeCallId == null &&
      (state?.readiness.canCall ?? false);
  bool get canReceive => state?.readiness.canReceive ?? false;
  bool get showReadinessHint =>
      loggedIn &&
      (state?.readiness.reasons.any((r) => r != 'CALL_IN_PROGRESS') ?? false);
  String get status => !configured
      ? 'Cần cấu hình ứng dụng'
      : state?.connectionStates.values.contains('RECONNECTING') == true
      ? 'Đang kết nối lại…'
      : activeCallId != null
      ? 'Đang trong cuộc gọi'
      : !loggedIn
      ? 'Chưa kết nối Voice'
      : state?.readiness.canCall == true
      ? 'Sẵn sàng gọi CSKH'
      : 'Đang kiểm tra kết nối';
}
