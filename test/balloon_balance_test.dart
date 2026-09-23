import 'dart:math';
import '../lib/games/arcade_engines.dart';

void check(bool ok, String message) {
  if (!ok) throw StateError(message);
}

void main() {
  for (final size in [
    const Point(400.0, 760.0),
    const Point(900.0, 420.0),
    const Point(487.3, 650.0)
  ]) {
    for (var seed = 0; seed < 24; seed++) {
      for (final spot in [0.2, 0.5, 0.8]) {
        final idle = BalloonEngine(random: Random(seed))
          ..resize(size.x, size.y)
          ..reset();
        idle.x = idle.target = size.x * spot;
        for (var frame = 0; frame < 90 * 120 && !idle.over; frame++) {
          idle.update(1 / 120);
        }
        check(idle.over,
            'Stanie w miejscu nie może przechodzić kolejnych fal: $seed/$size/$spot');
      }
      final game = BalloonEngine(random: Random(seed))
        ..resize(size.x, size.y)
        ..reset();
      BalloonWave? previous, following;
      var reaction = 0.0, generated = 0;
      var lastDirection = 0.0, continuedDirection = 0, rocks = 0;
      for (var frame = 0; frame < 150 * 120; frame++) {
        final upcoming =
            game.waves.where((g) => g.y <= game.balloonY + g.halfHeight + 33);
        final next = upcoming.isEmpty ? null : upcoming.first;
        if (next != following) {
          following = next;
          reaction = 0.16;
        }
        reaction -= 1 / 120;
        if (following != null && reaction <= 0)
          game.drag(following.safeX - game.target);
        game.update(1 / 120);
        check(!game.over,
            'Trasa musi być osiągalna przy płynnym sterowaniu: $seed/$size/${game.time}');
        if (game.waves.isNotEmpty && game.waves.last != previous) {
          final gate = game.waves.last;
          check(gate.obstacles.length >= 2, 'Kilka oddzielnych przeszkód');
          check(
              gate.obstacles.every((o) =>
                  o.width <= 60 && o.x >= 0 && o.x + o.width <= game.width),
              'Krótkie przeszkody');
          rocks += gate.obstacles.where((o) => o.rock).length;
          if (previous != null) {
            final direction = (gate.safeX - previous.safeX).sign;
            if (direction != 0 && direction == lastDirection)
              continuedDirection++;
            if (direction != 0) lastDirection = direction;
            check((gate.safeX - previous.safeX).abs() <= 180 + 1e-8,
                'Osiągalna droga pomiędzy falami');
          }
          previous = gate;
          generated++;
        }
      }
      check(rocks > 0 && continuedDirection > 0,
          'Skały i zmiany trasy inne niż naprzemienne lewo–prawo');
      check(generated > 45, 'Sprawdzono również późniejsze, trudniejsze fale');
    }
  }
  final wind = BalloonEngine();
  wind.time = 19;
  check(wind.gustWarning && wind.gust == 0, 'Zapowiedź podmuchu');
  wind.time = 21;
  check(wind.gust == 1 && wind.speed > 180, 'Przyspieszenie podczas podmuchu');
  wind.time = 26;
  check(wind.gust == 0, 'Podmuch przemija');
  print(
      'Balans Balonu: 216 prób bez ruchu kończy grę; 72 aktywne symulacje po 150 s przechodzą trasę.');
}
