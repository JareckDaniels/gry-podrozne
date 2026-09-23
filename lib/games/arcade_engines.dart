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
  final bool flying, pit;
  RunnerObstacle(this.x, this.width, this.bottom, this.height,
      {this.flying = false, this.pit = false});
}

class RunnerEngine extends ArcadeEngine {
  final Random random;
  final List<RunnerObstacle> obstacles = [];
  double y = 0, vy = 0, distance = 0, spawnIn = 1.6;
  double jumpBuffer = 0;
  bool held = false, falling = false;
  bool _introducedPit = false;
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
    falling = false;
    _introducedPit = false;
  }

  void press() {
    if (!over && !falling) {
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
    if (jumpBuffer > 0 && y <= 0 && !falling) {
      vy = impulse;
      jumpBuffer = 0;
    }
    jumpBuffer = max(0.0, jumpBuffer - dt);
    // Krótkie dotknięcie = niski skok; przytrzymanie = pełny łuk.
    final acceleration = gravity * (!held && vy > 0 ? 1.75 : 1.0);
    y += vy * dt - acceleration * dt * dt / 2;
    vy -= acceleration * dt;
    if (y <= 0 && !falling) {
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
      final pit =
          score >= 1000 && (!_introducedPit || random.nextDouble() < 0.28);
      if (pit) _introducedPit = true;
      final flying = !pit && score > 250 && random.nextDouble() < 0.22;
      final spawnX = obstacles.isEmpty
          ? width + 35
          : max(width + 35,
              obstacles.last.x + obstacles.last.width + speed * 1.35);
      obstacles.add(RunnerObstacle(
          spawnX,
          pit
              ? (score >= 2000 ? 120 : 85) + random.nextDouble() * 30
              : flying
                  ? 36
                  : 24 + random.nextDouble() * 14,
          flying ? 62 : 0,
          flying ? 36 : 34 + random.nextDouble() * 25,
          flying: flying,
          pit: pit));
      // Co najmniej pełny skok i czas na ponowne dotknięcie ekranu.
      spawnIn = 1.35 + random.nextDouble() * 0.65;
    }
    if (falling) {
      if (y < -90) over = true;
      return;
    }
    for (final o in obstacles) {
      if (o.pit) {
        if (playerX > o.x + 4 && playerX < o.x + o.width - 4 && y <= 0) {
          falling = true;
          held = false;
          jumpBuffer = 0;
          break;
        }
        continue;
      }
      if (o.flying) {
        // Okrąg obejmuje obracające się ostrza; bez niewidzialnych narożników.
        final cx = o.x + o.width / 2, cy = o.bottom + o.height / 2;
        final dx = cx - cx.clamp(playerX - 12, playerX + 12);
        final dy = cy - cy.clamp(y + 3, y + playerHeight - 3);
        final r = min(o.width, o.height) / 2 - 1;
        if (dx * dx + dy * dy < r * r) {
          over = true;
          break;
        }
        continue;
      }
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

// Fala zawiera oddzielne platformy lub spadające skały, z wieloma drogami.
class BalloonObstacle {
  final double x, width;
  final bool rock;
  BalloonObstacle(this.x, this.width, {this.rock = false});
  double get height => rock ? width : 16;
}

class BalloonWave {
  double y;
  final double safeX;
  final List<BalloonObstacle> obstacles;
  BalloonWave(this.y, this.safeX, this.obstacles);
  double get halfHeight => obstacles.fold(8.0, (v, o) => max(v, o.height / 2));
}

class BalloonCoin {
  double x, y;
  BalloonCoin(this.x, this.y);
}

class BalloonEngine extends ArcadeEngine {
  final Random random;
  final List<BalloonWave> waves = [];
  final List<BalloonCoin> coins = [];
  double x = 200, target = 200, vx = 0, travelled = 0;
  double spawnIn = 0.4, lastSafeX = 200;
  double _nextWaveAt = 0;
  int _waveNumber = 0;
  int collected = 0;
  BalloonEngine({Random? random}) : random = random ?? Random();
  double get balloonY => height * 0.68;
  // Co 20 sekund pięciosekundowy podmuch, łagodnie narastający i wygasający.
  double get gust {
    if (time < 20) return 0;
    final phase = time % 20;
    return phase < 5 ? min(1.0, min(phase, 5 - phase)) : 0;
  }

  bool get gustWarning => time % 20 >= 18;
  double get speed => min(185.0, 125 + time * 0.9) + gust * 45;
  static const radius = 19.0;
  @override
  int get score => collected;
  void reset() {
    resetClock();
    waves.clear();
    coins.clear();
    x = width / 2;
    target = x;
    vx = 0;
    travelled = 0;
    spawnIn = 0.4;
    collected = 0;
    lastSafeX = x;
    _nextWaveAt = 0;
    _waveNumber = 0;
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
    final oldWaves = List<BalloonWave>.of(waves);
    super.resize(w, h);
    waves.clear();
    for (final wave in oldWaves) {
      waves.add(BalloonWave(
          wave.y + balloonY - oldY,
          wave.safeX * ratio,
          wave.obstacles
              .map((o) => BalloonObstacle(
                  o.x * ratio, o.width * min(1.0, ratio),
                  rock: o.rock))
              .toList()));
    }
    for (final c in coins) {
      c.x *= ratio;
      c.y += balloonY - oldY;
    }
    x = (x * ratio).clamp(24.0, w - 24).toDouble();
    target = x;
    lastSafeX *= ratio;
    vx = 0;
  }

  @override
  void step(double dt) {
    // Tłumiony ruch do pozycji palca, bez teleportowania przez przeszkody.
    final desired = ((target - x) * 15).clamp(-520.0, 520.0);
    vx += (desired - vx) * (1 - exp(-22 * dt));
    x = (x + vx * dt).clamp(24.0, width - 24).toDouble();
    travelled += speed * dt;
    for (final wave in waves) {
      wave.y += speed * dt;
    }
    for (final coin in coins) {
      coin.y += speed * dt;
    }
    waves.removeWhere((g) => g.y > height + 60);
    coins.removeWhere((c) => c.y > height + 40);
    spawnIn -= dt;
    if (spawnIn <= 0 && travelled >= _nextWaveAt) {
      final lanes = max(5, (width / 80).floor());
      final spacing = width / lanes;
      final currentLane = (x / spacing).floor().clamp(0, lanes - 1);
      final candidates = <int>[];
      for (var lane = 0; lane < lanes; lane++) {
        final center = (lane + 0.5) * spacing;
        if ((center - lastSafeX).abs() <= 180 && lane != currentLane) {
          candidates.add(lane);
        }
      }
      final safeLane = candidates[random.nextInt(candidates.length)];
      lastSafeX = (safeLane + 0.5) * spacing;
      final occupied = List<int>.generate(lanes, (i) => i)
        ..remove(safeLane)
        ..shuffle(random);
      // Zagrożenie w obecnym torze zapobiega biernemu przelatywaniu.
      occupied.remove(currentLane);
      occupied.insert(0, currentLane);
      final count = min(lanes - 2, 2 + random.nextInt(max(1, lanes - 3)));
      final obstacles = <BalloonObstacle>[];
      for (final lane in occupied.take(count)) {
        final rock = _waveNumber >= 3 && random.nextDouble() < 0.38;
        final obstacleWidth =
            rock ? 38 + random.nextDouble() * 8 : 45 + random.nextDouble() * 15;
        obstacles.add(BalloonObstacle(
            (lane + 0.5) * spacing - obstacleWidth / 2, obstacleWidth,
            rock: rock));
      }
      waves.add(BalloonWave(-30, lastSafeX, obstacles));
      for (var i = 0; i < 3; i++) {
        coins.add(BalloonCoin(lastSafeX, -30 - i * 28));
      }
      _waveNumber++;
      // Odstęp w przestrzeni pozostaje bezpieczny także podczas podmuchu.
      _nextWaveAt = travelled + 300 + random.nextDouble() * 40;
    }
    coins.removeWhere((c) {
      final dx = c.x - x, dy = c.y - balloonY;
      if (dx * dx + dy * dy < 28 * 28) {
        collected++;
        return true;
      }
      return false;
    });
    for (final wave in waves) {
      for (final obstacle in wave.obstacles) {
        final left = obstacle.x, right = left + obstacle.width;
        final top = wave.y - obstacle.height / 2;
        final bottom = wave.y + obstacle.height / 2;
        final hit = obstacle.rock
            ? pow(x - (left + obstacle.width / 2), 2) +
                        pow(balloonY - wave.y, 2) <
                    pow(18 + obstacle.width / 2, 2) ||
                _circleRect(left + obstacle.width / 2, wave.y,
                    obstacle.width / 2, x - 7, balloonY + 22, 14, 10)
            : _circleRect(x, balloonY, 18, left, top, obstacle.width,
                    obstacle.height) ||
                (balloonY + 32 > top &&
                    balloonY + 22 < bottom &&
                    x + 7 > left &&
                    x - 7 < right);
        if (hit) {
          over = true;
          return;
        }
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
