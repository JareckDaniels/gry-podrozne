import 'dart:async';

class GameTimers {
  final Stopwatch _watch = Stopwatch()..start();
  final Set<_GameTimer> _timers = {};
  bool paused = false;
  Duration get elapsed => _watch.elapsed;
  Timer once(Duration duration, void Function() callback) =>
      _create(duration, (_) => callback(), false);
  Timer periodic(Duration duration, void Function(Timer) callback) =>
      _create(duration, callback, true);
  Timer _create(Duration duration, void Function(Timer) callback, bool repeat) {
    final timer = _GameTimer(this, duration, callback, repeat);
    _timers.add(timer);
    if (!paused) timer.resume();
    return timer;
  }

  void cancelAll() {
    for (final timer in _timers.toList()) {
      timer.cancel();
    }
  }

  void pause() {
    if (paused) return;
    paused = true;
    _watch.stop();
    for (final timer in _timers) {
      timer.pause();
    }
  }

  void resume() {
    if (!paused) return;
    paused = false;
    _watch.start();
    for (final timer in _timers.toList()) {
      timer.resume();
    }
  }

  void dispose() {
    cancelAll();
    _watch.stop();
  }
}

class _GameTimer implements Timer {
  final GameTimers clock;
  final Duration duration;
  final void Function(Timer) callback;
  final bool repeat;
  Timer? _timer;
  final Stopwatch _watch = Stopwatch();
  Duration remaining;
  bool _active = true;
  int _tick = 0;
  _GameTimer(this.clock, this.duration, this.callback, this.repeat)
      : remaining = duration;
  @override
  bool get isActive => _active;
  @override
  int get tick => _tick;
  void pause() {
    if (!_active || _timer == null) return;
    _timer?.cancel();
    _timer = null;
    _watch.stop();
    remaining -= _watch.elapsed;
    if (remaining.isNegative) remaining = Duration.zero;
  }

  void resume() {
    if (!_active || _timer != null) return;
    _watch
      ..reset()
      ..start();
    _timer = Timer(remaining, () {
      _timer = null;
      _watch.stop();
      _tick++;
      if (!repeat) {
        _active = false;
        clock._timers.remove(this);
      }
      remaining = duration;
      callback(this);
      if (repeat && _active && !clock.paused) resume();
    });
  }

  @override
  void cancel() {
    _active = false;
    _timer?.cancel();
    _timer = null;
    _watch.stop();
    clock._timers.remove(this);
  }
}
