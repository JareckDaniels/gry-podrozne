import 'dart:math';

// Stały krok symulacji: ten sam ruch na ekranach 30, 60 i 120 Hz.
abstract class ArcadeEngine {
  double width = 400, height = 600, time = 0;
  bool over = false;
  double _accumulator = 0;
  void resize(double w, double h) {
    width = w;
    height = h;
  }

  void resetClock() {
    time = 0;
    _accumulator = 0;
    over = false;
  }

  void update(double elapsed) {
    if (over || !elapsed.isFinite || elapsed <= 0) return;
    _accumulator += min(elapsed, 0.05);
    while (_accumulator >= 1 / 120 && !over) {
      time += 1 / 120;
      step(1 / 120);
      _accumulator -= 1 / 120;
    }
  }

  void step(double dt);
  int get score;
}

class RunnerObstacle {
  double x;
  final double width, bottom, height;
  final bool flying;
  RunnerObstacle(this.x, this.width, this.bottom, this.height,
      {this.flying = false});
}

class RunnerEngine extends ArcadeEngine {
  final Random random;
  final List<RunnerObstacle> obstacles = [];
  double y = 0, vy = 0, distance = 0, spawnIn = 1.6;
  double jumpBuffer = 0;
  bool held = false;
  RunnerEngine({Random? random}) : random = random ?? Random();
  double get playerX => width * 0.18;
  double get speed => min(430.0, 235 + time * 2.2);
  static const playerHeight = 44.0;
  static const gravity = 1450.0;
  static const impulse = 590.0;
  @override
  int get score => (distance / 12).floor();
  void reset() {
    resetClock();
    obstacles.clear();
    y = 0;
    vy = 0;
    distance = 0;
    spawnIn = 1.6;
    jumpBuffer = 0;
    held = false;
  }

  void press() {
    if (!over) {
      held = true;
      jumpBuffer = 0.12;
    }
  }

  void release() {
    held = false;
  }

  @override
  void resize(double w, double h) {
    final oldX = playerX;
    super.resize(w, h);
    for (final obstacle in obstacles) {
      obstacle.x += playerX - oldX;
    }
  }

  @override
  void step(double dt) {
    if (jumpBuffer > 0 && y <= 0) {
      vy = impulse;
      jumpBuffer = 0;
    }
    jumpBuffer = max(0.0, jumpBuffer - dt);
    // Krótkie dotknięcie = niski skok; przytrzymanie = pełny łuk.
    final acceleration = gravity * (!held && vy > 0 ? 1.75 : 1.0);
    y += vy * dt - acceleration * dt * dt / 2;
    vy -= acceleration * dt;
    if (y <= 0) {
      y = 0;
      vy = 0;
    }
    distance += speed * dt;
    for (final obstacle in obstacles) {
      obstacle.x -= speed * dt;
    }
    obstacles.removeWhere((o) => o.x + o.width < -30);
    spawnIn -= dt;
    if (spawnIn <= 0) {
      final flying = score > 250 && random.nextDouble() < 0.22;
      final spawnX = obstacles.isEmpty
          ? width + 35
          : max(width + 35, obstacles.last.x + speed * 1.35);
      obstacles.add(RunnerObstacle(
          spawnX,
          flying ? 42 : 24 + random.nextDouble() * 14,
          flying ? 62 : 0,
          flying ? 24 : 34 + random.nextDouble() * 25,
          flying: flying));
      // Co najmniej pełny skok i czas na ponowne dotknięcie ekranu.
      spawnIn = 1.35 + random.nextDouble() * 0.65;
    }
    for (final o in obstacles) {
      if (playerX + 12 > o.x + 2 &&
          playerX - 12 < o.x + o.width - 2 &&
          y + playerHeight - 3 > o.bottom &&
          y + 3 < o.bottom + o.height) {
        over = true;
        break;
      }
    }
  }
}

class BalloonGate {
  double y;
  final double gap, gapWidth;
  BalloonGate(this.y, this.gap, this.gapWidth);
}

class BalloonCoin {
  double x, y;
  BalloonCoin(this.x, this.y);
}

class BalloonEngine extends ArcadeEngine {
  final Random random;
  final List<BalloonGate> gates = [];
  final List<BalloonCoin> coins = [];
  double x = 200, target = 200, vx = 0, travelled = 0;
  double spawnIn = 0.4, lastGap = 200;
  int collected = 0;
  BalloonEngine({Random? random}) : random = random ?? Random();
  double get balloonY => height * 0.68;
  double get speed => min(190.0, 95 + time * 1.1);
  static const radius = 19.0;
  @override
  int get score => collected;
  void reset() {
    resetClock();
    gates.clear();
    coins.clear();
    x = width / 2;
    target = x;
    vx = 0;
    travelled = 0;
    spawnIn = 0.4;
    collected = 0;
    lastGap = x;
  }

  void drag(double delta) {
    target = (target + delta).clamp(24.0, width - 24).toDouble();
  }

  @override
  void resize(double w, double h) {
    // Obrót zatrzymuje grę w ekranie. Przeszkody pozostają w tym samym
    // czasie dojścia do gracza; przejścia zachowują względne położenie.
    final ratio = w / width;
    final oldY = balloonY;
    final oldGates = List<BalloonGate>.of(gates);
    super.resize(w, h);
    gates.clear();
    for (final g in oldGates) {
      final gapWidth = min(w - 48, g.gapWidth);
      final center = (g.gap * ratio)
          .clamp(gapWidth / 2 + 12, w - gapWidth / 2 - 12)
          .toDouble();
      gates.add(BalloonGate(g.y + balloonY - oldY, center, gapWidth));
    }
    for (final c in coins) {
      c.x *= ratio;
      c.y += balloonY - oldY;
    }
    x = (x * ratio).clamp(24.0, w - 24).toDouble();
    target = x;
    lastGap = (lastGap * ratio).clamp(80.0, w - 80).toDouble();
    vx = 0;
  }

  @override
  void step(double dt) {
    // Tłumiony ruch do pozycji palca, bez teleportowania przez przeszkody.
    final desired = ((target - x) * 15).clamp(-520.0, 520.0);
    vx += (desired - vx) * (1 - exp(-22 * dt));
    x = (x + vx * dt).clamp(24.0, width - 24).toDouble();
    travelled += speed * dt;
    for (final gate in gates) {
      gate.y += speed * dt;
    }
    for (final coin in coins) {
      coin.y += speed * dt;
    }
    gates.removeWhere((g) => g.y > height + 40);
    coins.removeWhere((c) => c.y > height + 40);
    spawnIn -= dt;
    if (spawnIn <= 0) {
      final gapWidth = max(112.0, 158 - time * 0.25);
      final margin = gapWidth / 2 + 16;
      // Każda fala ma gwarantowaną szczelinę. Kolejna nie skacze
      // losowo na przeciwległy koniec szerokiego ekranu.
      lastGap = (lastGap + (random.nextDouble() * 2 - 1) * 145)
          .clamp(margin, width - margin)
          .toDouble();
      gates.add(BalloonGate(-22, lastGap, gapWidth));
      for (var i = 0; i < 3; i++) {
        coins.add(BalloonCoin(lastGap, -22 - i * 28));
      }
      spawnIn = 1.75 + random.nextDouble() * 0.35;
    }
    coins.removeWhere((c) {
      final dx = c.x - x, dy = c.y - balloonY;
      if (dx * dx + dy * dy < 28 * 28) {
        collected++;
        return true;
      }
      return false;
    });
    for (final gate in gates) {
      // Czasza i kosz są sprawdzane osobno; ozdobne linki nie karzą gracza.
      final left = gate.gap - gate.gapWidth / 2;
      final right = gate.gap + gate.gapWidth / 2;
      if (_circleRect(x, balloonY, 18, 0, gate.y - 8, left, 16) ||
          _circleRect(x, balloonY, 18, right, gate.y - 8, width - right, 16) ||
          ((balloonY + 32 > gate.y - 8 && balloonY + 22 < gate.y + 8) &&
              (x - 7 < left || x + 7 > right))) {
        over = true;
        break;
      }
    }
  }

  bool _circleRect(double cx, double cy, double r, double rx, double ry,
      double rw, double rh) {
    final dx = cx - cx.clamp(rx, rx + rw);
    final dy = cy - cy.clamp(ry, ry + rh);
    return dx * dx + dy * dy < r * r;
  }
}
