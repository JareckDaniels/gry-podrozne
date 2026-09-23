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
        for (var frame = 0; frame < 20 * 120 && !idle.over; frame++) {
          idle.update(1 / 120);
        }
        check(idle.over,
            'Stanie w miejscu nie może przechodzić kolejnych fal: $seed/$size/$spot');
      }
      final game = BalloonEngine(random: Random(seed))
        ..resize(size.x, size.y)
        ..reset();
      BalloonGate? previous, following;
      var reaction = 0.0, generated = 0;
      for (var frame = 0; frame < 150 * 120; frame++) {
        final upcoming = game.gates.where((g) => g.y <= game.balloonY + 41);
        final next = upcoming.isEmpty ? null : upcoming.first;
        if (next != following) {
          following = next;
          reaction = 0.16;
        }
        reaction -= 1 / 120;
        if (following != null && reaction <= 0)
          game.drag(following.gap - game.target);
        game.update(1 / 120);
        check(!game.over,
            'Trasa musi być osiągalna przy płynnym sterowaniu: $seed/$size/${game.time}');
        if (game.gates.isNotEmpty && game.gates.last != previous) {
          final gate = game.gates.last;
          check(gate.gapWidth >= 96 && gate.gapWidth <= 140,
              'Szerokość przejścia');
          check(
              gate.gap - gate.gapWidth / 2 >= 16 - 1e-8 &&
                  gate.gap + gate.gapWidth / 2 <= game.width - 16 + 1e-8,
              'Marginesy');
          if (previous != null) {
            final difference = (gate.gap - previous.gap).abs();
            check(difference > (gate.gapWidth + previous.gapWidth) / 2 - 36,
                'Kolejne bezpieczne obszary nie nakładają się');
            check(difference <= 220 + 1e-8, 'Przejście nie skacze zbyt daleko');
          }
          previous = gate;
          generated++;
        }
      }
      check(generated > 70, 'Sprawdzono również późniejsze, trudniejsze fale');
    }
  }
  print(
      'Balans Balonu: 216 prób bez ruchu kończy grę; 72 aktywne symulacje po 150 s przechodzą trasę.');
}
