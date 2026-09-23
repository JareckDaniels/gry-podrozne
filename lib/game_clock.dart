import 'dart:async';
import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'game_timers.dart';

class GameClock extends ChangeNotifier with WidgetsBindingObserver {
  final GameTimers _timers = GameTimers();
  GameClock() {
    WidgetsBinding.instance.addObserver(this);
  }
  bool get paused => _timers.paused;
  Duration get elapsed => _timers.elapsed;
  Timer once(Duration duration, void Function() callback) =>
      _timers.once(duration, callback);
  Timer periodic(Duration duration, void Function(Timer) callback) =>
      _timers.periodic(duration, callback);
  void cancelAll() => _timers.cancelAll();
  void pause() {
    if (!paused) {
      _timers.pause();
      notifyListeners();
    }
  }

  void resume() {
    if (paused) {
      _timers.resume();
      notifyListeners();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) pause();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timers.dispose();
    super.dispose();
  }
}

class GamePauseButton extends StatelessWidget {
  final GameClock clock;
  const GamePauseButton({super.key, required this.clock});
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: clock,
      builder: (context, _) => IconButton(
          tooltip: clock.paused ? 'Wznów' : 'Pauza',
          onPressed: clock.paused ? clock.resume : clock.pause,
          icon: Icon(
              clock.paused ? Icons.play_arrow_rounded : Icons.pause_rounded)));
}

class GamePauseLayer extends StatelessWidget {
  final GameClock clock;
  final Widget child;
  const GamePauseLayer({super.key, required this.clock, required this.child});
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: clock,
      child: child,
      builder: (context, child) => Stack(fit: StackFit.expand, children: [
            IgnorePointer(ignoring: clock.paused, child: child),
            if (clock.paused)
              ColoredBox(
                  color: AppColors.tlo.withOpacity(0.88),
                  child: Center(
                      child: Container(
                          margin: const EdgeInsets.all(24),
                          padding: const EdgeInsets.all(28),
                          decoration: AppTheme.panel(),
                          child:
                              Column(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.pause_circle_outline,
                                size: 44, color: AppColors.fiolet),
                            const SizedBox(height: 12),
                            const Text('Pauza',
                                style: TextStyle(
                                    fontSize: 26, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 20),
                            ElevatedButton(
                                onPressed: clock.resume,
                                child: const Text('Wznów')),
                          ])))),
          ]));
}
