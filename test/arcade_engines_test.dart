import 'dart:math';
import '../lib/games/arcade_engines.dart';

void check(bool condition, String message) {
  if (!condition) throw StateError(message);
}

void main() {
  double jumpPeak(bool hold) {
    final g = RunnerEngine()..reset();
    g.spawnIn = 100;
    g.press();
    g.update(1 / 120);
    if (!hold) g.release();
    var peak = 0.0;
    for (var i = 0; i < 130; i++) {
      g.update(1 / 120);
      peak = max(peak, g.y);
    }
    check(g.y == 0, 'Lądowanie na ziemi');
    return peak;
  }

  final low = jumpPeak(false), high = jumpPeak(true);
  check(low > 60 && high > low + 30 && high < 130, 'Dwie wysokości skoku');
  final a = RunnerEngine(random: Random(8))..reset();
  final b = RunnerEngine(random: Random(8))..reset();
  a.spawnIn = b.spawnIn = 100;
  a.press();
  b.press();
  for (var i = 0; i < 30; i++) {
    a.update(1 / 60);
  }
  for (var i = 0; i < 60; i++) {
    b.update(1 / 120);
  }
  check((a.y - b.y).abs() < 0.001 && (a.distance - b.distance).abs() < 0.001,
      'Niezależność od liczby klatek');
  a.time = 1000;
  check(a.speed == 430, 'Limit prędkości Biegacza');
  a.reset();
  a.spawnIn = 100;
  a.obstacles.add(RunnerObstacle(a.playerX, 30, 0, 40));
  a.update(1 / 60);
  check(a.over, 'Kolizja z przeszkodą naziemną');
  a.reset();
  a.spawnIn = 100;
  a.obstacles.add(RunnerObstacle(a.playerX, 36, 62, 36, flying: true));
  a.update(1 / 60);
  check(!a.over, 'Można przebiec pod shurikenem');
  a.y = 50;
  a.vy = 0;
  a.update(1 / 60);
  check(a.over, 'Skok w shurikena kończy grę');
  a.reset();
  a.spawnIn = 100;
  a.y = 1;
  a.vy = -100;
  a.press();
  a.update(1 / 30);
  check(a.y > 0 && a.vy > 0, 'Bufor skoku tuż przed lądowaniem');

  final balloon = BalloonEngine(random: Random(5))..reset();
  balloon.spawnIn = 100;
  balloon.drag(1000);
  balloon.update(1 / 60);
  check(balloon.x > 200 && balloon.x < 220, 'Balon płynnie podąża za palcem');
  for (var i = 0; i < 100; i++) {
    balloon.update(1 / 60);
  }
  check(balloon.x <= 376, 'Balon nie opuszcza ekranu');
  balloon.reset();
  balloon.spawnIn = 100;
  balloon.gates.add(BalloonGate(balloon.balloonY, 200, 130));
  balloon.update(1 / 60);
  check(!balloon.over, 'Przejście jest bezpieczne');
  balloon.x = balloon.target = 60;
  balloon.update(1 / 60);
  check(balloon.over, 'Bariera zatrzymuje balon');
  balloon.reset();
  balloon.spawnIn = 100;
  balloon.coins.add(BalloonCoin(balloon.x, balloon.balloonY));
  balloon.update(1 / 60);
  check(balloon.score == 1 && balloon.coins.isEmpty, 'Kółko liczone jeden raz');
  balloon.time = 1000;
  check(balloon.speed == 190, 'Limit prędkości Balonu');
  balloon.reset();
  for (var i = 0; i < 3000; i++) {
    // Test generatora i korytarzy, bez kolizji gracza.
    balloon.gates.clear();
    balloon.coins.clear();
    balloon.update(1 / 60);
    for (final g in balloon.gates) {
      check(
          g.gapWidth >= 96 &&
              g.gap - g.gapWidth / 2 >= 16 &&
              g.gap + g.gapWidth / 2 <= balloon.width - 16,
          'Bezpieczna szerokość szczeliny');
    }
  }
  balloon.resize(900, 420);
  check(balloon.x.isFinite && balloon.x >= 24 && balloon.x <= 876,
      'Obrót zachowuje poprawną pozycję');
  balloon.reset();
  balloon.spawnIn = 100;
  balloon.update(30);
  check(balloon.travelled < 6, 'Przycięcie nie przeskakuje przeszkód');
  print(
      'Balon i Biegacz: skoki, kolizje, płynny ruch, generator, obrót i limity — OK.');
}
