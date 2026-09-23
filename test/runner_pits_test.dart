import 'dart:math';
import '../lib/games/arcade_engines.dart';

void check(bool value, String message) {
  if (!value) throw StateError(message);
}

void main() {
  for (final width in [400.0, 900.0]) {
    for (final pitWidth in [85.0, 115.0, 150.0]) {
      final game = RunnerEngine()
        ..resize(width, 420)
        ..reset();
      game.time = 1000;
      game.spawnIn = 100;
      game.obstacles
          .add(RunnerObstacle(game.playerX + 75, pitWidth, 0, 0, pit: true));
      game.press();
      for (var i = 0; i < 150; i++) {
        game.update(1 / 120);
      }
      check(!game.over && !game.falling && game.y == 0,
          'Pełny skok pokonuje dziurę $pitWidth przy maksymalnej prędkości');
      game.reset();
      game.spawnIn = 100;
      game.obstacles
          .add(RunnerObstacle(game.playerX - 10, pitWidth, 0, 0, pit: true));
      game.update(1 / 120);
      check(game.falling, 'Wejście w dziurę powoduje spadanie');
      game.press();
      for (var i = 0; i < 100; i++) {
        game.update(1 / 120);
      }
      check(game.over, 'Nie da się wyskoczyć po utracie podłoża');
      game.reset();
      check(!game.falling && game.y == 0, 'Restart po upadku');
    }
  }
  for (var seed = 0; seed < 30; seed++) {
    final game = RunnerEngine(random: Random(seed))..reset();
    game.distance = 999 * 12;
    game.spawnIn = 0;
    game.update(1 / 120);
    check(!game.obstacles.single.pit, 'Brak dziur przed 1000 m');
    game.obstacles.clear();
    game.distance = 1000 * 12;
    game.spawnIn = 0;
    game.update(1 / 120);
    check(game.obstacles.single.pit, 'Pierwsza dziura po 1000 m');
    game.spawnIn = 0;
    game.update(1 / 120);
    check(
        game.obstacles.last.x -
                game.obstacles.first.x -
                game.obstacles.first.width >=
            game.speed * 1.34,
        'Odstęp za dziurą pozwala wylądować przed kolejną przeszkodą');
  }
  print(
      'Biegacz: progi dystansu, skok nad wyrwami, upadek, restart i odstępy — OK.');
}
