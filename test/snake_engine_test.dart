// Uruchomienie bez dodatkowych pakietów: dart test/snake_engine_test.dart
import 'dart:math';
import '../lib/games/snake_engine.dart';

void check(bool condition, String message) {
  if (!condition) throw StateError(message);
}

void main() {
  final game = SnakeEngine(random: Random(42));
  game.food = const Point(8, 12);
  game.step();
  check(game.score == 1 && game.body.length == 4, 'Jedzenie wydłuża węża');
  check(!game.body.contains(game.food), 'Jedzenie poza ciałem');
  game.turn(SnakeDirection.left);
  game.step();
  check(game.direction == SnakeDirection.right, 'Blokada zawracania');
  game.turn(SnakeDirection.up);
  game.turn(SnakeDirection.left);
  game.step();
  check(game.direction == SnakeDirection.up, 'Pierwszy szybki skręt');
  game.step();
  check(game.direction == SnakeDirection.left, 'Drugi szybki skręt');

  for (final direction in SnakeDirection.values) {
    game.reset();
    game.direction = direction;
    final edge = [const Point(5, 0), const Point(19, 5),
      const Point(5, 23), const Point(0, 5)][direction.index];
    game.body = [edge];
    game.step();
    check(game.over, 'Kolizja ze ścianą: $direction');
  }

  game.reset();
  game.body = [const Point(2, 2), const Point(2, 3), const Point(3, 3),
    const Point(3, 2), const Point(4, 2)];
  game.step();
  check(game.over, 'Kolizja z własnym ciałem');

  game.reset();
  game.body = [const Point(2, 2), const Point(2, 3),
    const Point(3, 3), const Point(3, 2)];
  game.food = const Point(10, 10);
  game.step();
  check(!game.over && game.body.first == const Point(3, 2),
    'Dozwolone wejście na opuszczane pole ogona');

  game.reset();
  game.body = [const Point(0, 0)];
  for (var y = 0; y < SnakeEngine.rows; y++) {
    for (var x = 0; x < SnakeEngine.columns; x++) {
      if (y == 0 && x < 2) continue;
      game.body.add(Point(x, y));
    }
  }
  game.food = const Point(1, 0);
  game.step();
  check(game.won && game.over && game.food == null, 'Zapełnienie planszy');
  game.reset();
  check(!game.over && !game.won && game.score == 0 && game.body.length == 3,
    'Restart resetuje stan');
  print('Snake: wszystkie testy logiki zakończone poprawnie.');
}
