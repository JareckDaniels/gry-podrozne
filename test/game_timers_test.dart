import '../lib/game_timers.dart';

void check(bool value, String label) {
  if (!value) throw StateError(label);
}

Future<void> wait(int ms) => Future<void>.delayed(Duration(milliseconds: ms));
Future<void> main() async {
  final clock = GameTimers();
  var called = 0;
  clock.once(const Duration(milliseconds: 40), () => called++);
  clock.pause();
  final stopped = clock.elapsed;
  await wait(90);
  check(called == 0 && clock.elapsed == stopped,
      'Pauza zatrzymuje zegar i callback');
  clock.resume();
  await wait(100);
  check(called == 1, 'Wznowienie wykonuje callback raz');
  clock.periodic(const Duration(milliseconds: 10), (timer) {
    called++;
    if (timer.tick == 2) timer.cancel();
  });
  await wait(80);
  check(called == 3, 'Timer okresowy można zatrzymać wewnątrz callbacku');
  clock.pause();
  clock.once(const Duration(milliseconds: 10), () => called++);
  await wait(30);
  check(called == 3, 'Nowy timer również respektuje pauzę');
  clock.cancelAll();
  clock.resume();
  await wait(30);
  check(called == 3, 'Restart usuwa stare opóźnione wywołania');
  clock.dispose();
  print('Zegar: pauza, wznowienie, cykle i anulowanie — OK.');
}
