import 'dart:async';

import 'package:caresoft_customer_voice/caresoft_customer_voice.dart';

Map<String, Object?> stateMap({
  bool loggedIn = false,
  bool ready = false,
  bool receive = false,
  bool presentable = false,
  bool reconnecting = false,
  List<String> reasons = const [],
}) => {
  'revision': 1,
  'sessionState': loggedIn
      ? {
          'status': 'authenticated',
          'session': {
            'userId': '42',
            'sessionId': 'session-example',
            'expiresAt': '2030-01-01T00:00:00Z',
          },
        }
      : {'status': 'loggedOut'},
  'readiness': {
    'sessionStatus': loggedIn ? 'VALID' : 'LOGGED_OUT',
    'isLoggedIn': loggedIn,
    'canCall': ready,
    'canReceive': receive,
    'userId': loggedIn ? '42' : null,
    'reasons': reasons,
    'checkedAt': null,
    'controlConnected': loggedIn,
  },
  'calls': presentable
      ? [
          {
            'callId': 'call-example',
            'direction': 'OUTBOUND',
            'state': 'ACTIVE',
            'version': '1',
            'isOwner': true,
            'presentable': true,
          },
        ]
      : [],
  'audioStates': {},
  'connectionStates': reconnecting ? {'call-example': 'RECONNECTING'} : {},
};

class DemoTransport implements VoiceTransport {
  Map<String, Object?> state = stateMap();
  final changes = StreamController<Object?>.broadcast(sync: true);
  final operations = <String>[];
  @override
  Stream<Object?> get states => changes.stream;
  @override
  Stream<Object?> get events => const Stream.empty();
  @override
  Future<Object?> execute(String method, Map<String, Object?> args) async {
    operations.add(method);
    if (method == 'getState' || method == 'synchronize') return state;
    if (method == 'canShowIncomingScreen') return true;
    return null;
  }
}
