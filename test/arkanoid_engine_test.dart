// dart test/arkanoid_engine_test.dart
import 'dart:math';
import '../lib/games/arkanoid_engine.dart';

void check(bool condition, String message) {
  if (!condition) throw StateError(message);
}

ArkanoidEngine gameWithBall(double x, double y, double vx, double vy) {
  final game = ArkanoidEngine(random: Random(7));
  game.bricks = [ArkanoidBrick(10, 40, 30, 19, 1, 0)];
  game.balls
    ..clear()
    ..add(ArkanoidBall(x, y, vx, vy));
  game.phase = ArkanoidPhase.playing;
  return game;
}

void main() {
  final signatures = <String>{};
  for (var level = 1; level <= 30; level++) {
    final bricks = ArkanoidLevels.build(level);
    check(bricks.isNotEmpty, 'Poziom $level musi mieć klocki');
    check(
        bricks.every((b) =>
            b.x >= 0 &&
            b.x + b.width <= 360 &&
            b.y >= 0 &&
            b.y + b.height < 360 &&
            b.hits >= 1 &&
            b.hits <= 3),
        'Poprawne wymiary poziomu $level');
    signatures.add(bricks.map((b) => '${b.x},${b.y},${b.hits}').join(';'));
  }
  check(signatures.length == 30, '30 różnych plansz');

  var game = gameWithBall(6, 300, -230, 0);
  game.update(0.02);
  check(game.balls.single.vx > 0, 'Lewa ściana');
  game = gameWithBall(354, 300, 230, 0);
  game.update(0.02);
  check(game.balls.single.vx < 0, 'Prawa ściana');
  game = gameWithBall(180, 6, 0, -230);
  game.update(0.02);
  check(game.balls.single.vy > 0, 'Sufit');

  game = gameWithBall(180, 500, 0, 230);
  game.update(0.03);
  check(game.balls.single.vy < 0 && game.lives == 3, 'Odbicie od platformy');
  game = gameWithBall(210, 500, 0, 230);
  game.update(0.03);
  check(game.balls.single.vx > 100 && game.balls.single.vy < 0,
      'Celowanie końcem platformy');

  game = gameWithBall(25, 65, 0, -230);
  game.bricks.single.hits = 2;
  game.update(0.02);
  check(
      game.bricks.single.hits == 1 &&
          game.score == 10 &&
          game.balls.single.vy > 0,
      'Mocny klocek traci jeden punkt wytrzymałości');
  game.balls.single
    ..x = 25
    ..y = 65
    ..vx = 0
    ..vy = -230;
  game.update(0.02);
  check(game.phase == ArkanoidPhase.cleared && game.score == 135,
      'Zniszczenie ostatniego klocka, premia i koniec poziomu');
  game.nextLevel();
  check(
      game.level == 2 &&
          game.score == 135 &&
          game.lives == 3 &&
          game.phase == ArkanoidPhase.ready,
      'Następny poziom zachowuje wynik i życia');

  game = gameWithBall(100, 567, 0, 230);
  game.balls.add(ArkanoidBall(180, 400, 0, -230));
  game.update(0.01);
  check(game.lives == 3 && game.balls.length == 1,
      'Pozostała piłka chroni życie');
  game.balls.single.y = 567;
  game.update(0.01);
  check(
      game.lives == 2 &&
          game.phase == ArkanoidPhase.ready &&
          game.bricks.length == 1,
      'Ostatnia piłka zabiera jedno życie i zachowuje klocki');
  game.lives = 1;
  game.launch();
  game.balls.single.y = 570;
  game.update(0.01);
  check(game.phase == ArkanoidPhase.gameOver && game.lives == 0, 'Koniec żyć');

  game = gameWithBall(180, 400, 0, -230);
  game.applyBonus(ArkanoidBonus.doubleBalls);
  check(game.balls.length == 2, 'Dwie piłki');
  game.applyBonus(ArkanoidBonus.tripleBalls);
  check(game.balls.length == 6, 'Potrojenie wszystkich piłek');
  for (var i = 0; i < 4; i++) {
    game.applyBonus(ArkanoidBonus.tripleBalls);
  }
  check(game.balls.length == 24, 'Limit multiball');
  check(
      game.balls.every(
          (b) => (sqrt(b.vx * b.vx + b.vy * b.vy) - game.speed).abs() < 0.001),
      'Bonus zachowuje prędkość');
  game.applyBonus(ArkanoidBonus.widePaddle);
  check(
      game.paddleWidth == 152 && game.wideSeconds == 20, 'Poszerzenie na 20 s');
  game.movePaddle(-100);
  check(game.paddleX == 76, 'Szeroka platforma mieści się na planszy');
  game.wideSeconds = 0.01;
  game.update(0.02);
  check(game.paddleWidth == 76, 'Bonus szerokości wygasa');
  game.applyBonus(ArkanoidBonus.extraLife);
  check(game.lives == 4, 'Dodatkowe życie');

  game = gameWithBall(180, 400, 0, -230);
  game.drops.add(ArkanoidDrop(180, 497, ArkanoidBonus.extraLife));
  game.update(0.03);
  check(game.lives == 4 && game.drops.isEmpty, 'Złapanie bonusu');
  game.drops.add(ArkanoidDrop(20, 497, ArkanoidBonus.extraLife));
  game.update(0.03);
  check(game.lives == 4, 'Bonus poza platformą nie działa');

  game = gameWithBall(25, 65, 0, -230);
  game.level = 30;
  game.update(0.02);
  check(game.phase == ArkanoidPhase.completed, 'Ukończenie 30. poziomu');
  game.start(atLevel: 17);
  check(
      game.level == 17 &&
          game.score == 0 &&
          game.lives == 3 &&
          game.wideSeconds == 0 &&
          game.drops.isEmpty,
      'Nowy start zeruje poprzednią grę');

  // Symulacja dłuższej gry z automatyczną platformą ujawnia NaN,
  // modyfikację kolekcji podczas iteracji i błędy w zmianach stanu.
  for (var level = 1; level <= 30; level++) {
    game.start(atLevel: level);
    game.launch();
    for (var frame = 0; frame < 1800; frame++) {
      if (game.phase != ArkanoidPhase.playing) break;
      game.movePaddle(game.balls.first.x);
      game.update(1 / 60);
      check(
          game.balls.every((b) =>
              b.x.isFinite && b.y.isFinite && b.vx.isFinite && b.vy.isFinite),
          'Skończone współrzędne poziom $level');
      check(game.lives >= 0 && game.balls.length <= 24, 'Poprawny stan gry');
    }
  }
  print('Arkanoid: 30 plansz, kolizje, bonusy, życia i symulacje — OK.');
}
