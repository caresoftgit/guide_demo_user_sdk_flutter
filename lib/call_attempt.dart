// Named callbacks keep the public constructor separate from private fields.
// ignore_for_file: prefer_initializing_formals
class CallAttempt {
  CallAttempt({
    required Future<void> Function() create,
    required Future<void> Function() synchronize,
    required void Function(bool) changed,
    bool initiallyBlocked = true,
  }) : _create = create,
       _synchronize = synchronize,
       _changed = changed,
       blocked = initiallyBlocked;
  final Future<void> Function() _create, _synchronize;
  final void Function(bool) _changed;
  bool blocked;
  bool _creating = false;
  void _set(bool value) {
    blocked = value;
    _changed(value);
  }

  Future<void> synchronize() async {
    await _synchronize();
    if (!_creating) _set(false);
  }

  Future<void> call() async {
    if (blocked || _creating) return;
    _creating = true;
    _set(true);
    try {
      await _create();
      _set(false);
    } catch (error) {
      try {
        await _synchronize();
        _set(false);
      } catch (_) {
        /* Explicit successful synchronization is required before another call. */
      }
      rethrow;
    } finally {
      _creating = false;
    }
  }
}
