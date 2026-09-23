import 'dart:math';

enum ArkanoidPhase { ready, playing, cleared, gameOver, completed }

enum ArkanoidBonus { addOneBall, addTwoBalls, widePaddle, extraLife }

class ArkanoidBrick {
  final double x, y, width, height;
  int hits;
  final int color;
  ArkanoidBrick(this.x, this.y, this.width, this.height, this.hits, this.color);
}

class ArkanoidBall {
  double x, y, vx, vy;
  ArkanoidBall(this.x, this.y, this.vx, this.vy);
}

class ArkanoidDrop {
  final double x;
  double y;
  final ArkanoidBonus kind;
  ArkanoidDrop(this.x, this.y, this.kind);
}

class ArkanoidLevels {
  static const count = 30;
  static const _names = [
    'Mur',
    'Piramida',
    'Diament',
    'Szachownica',
    'Brama',
    'Fala',
    'Skrzydła',
    'Twierdza',
    'Tunele',
    'Mozaika',
  ];
  static String name(int level) => _names[(level - 1) % 10];

  static List<ArkanoidBrick> build(int level) {
    final tier = (level - 1) ~/ 10;
    final pattern = (level - 1) % 10;
    final rows = 6 + tier;
    final result = <ArkanoidBrick>[];
    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < 10; col++) {
        final distance = (col - 4.5).abs();
        bool filled;
        switch (pattern) {
          case 0:
            filled = row % 3 != 2 || (col + tier).isEven;
            break;
          case 1:
            filled = distance <= row + 0.5;
            break;
          case 2:
            filled = distance + (row - (rows - 1) / 2).abs() <= rows / 2 + 1;
            break;
          case 3:
            filled = (row + col).isEven || row == 0;
            break;
          case 4:
            filled = row < 2 || col < 2 || col > 7;
            break;
          case 5:
            filled = (row - (2 + 1.7 * sin(col * 0.8 + tier))).abs() < 1.7;
            break;
          case 6:
            filled = distance >= (rows - row - 1) * 0.5;
            break;
          case 7:
            filled =
                row == 0 || row == rows - 1 || col % 3 == 0 || row == rows ~/ 2;
            break;
          case 8:
            filled = col != 2 && col != 7 || row == 0 || row == rows - 1;
            break;
          default:
            filled = (row * 3 + col * 2 + tier) % 5 != 0;
            break;
        }
        if (!filled) continue;
        final hits = 1 +
            (level >= 6 && (row + col) % 4 == 0 ? 1 : 0) +
            (level >= 21 && (row * 2 + col) % 5 == 0 ? 1 : 0);
        result.add(ArkanoidBrick(12 + col * 34.0, 48 + row * 24.0, 30, 19, hits,
            (row + tier * 2) % 6));
      }
    }
    return result;
  }
}

// Stała plansza logiczna. Ekran skaluje tylko rysunek i współrzędne dotyku.
class ArkanoidEngine {
  static const width = 360.0;
  static const height = 560.0;
  static const paddleY = 508.0;
  static const paddleHeight = 12.0;
  static const radius = 5.0;
  static const maxBalls = 24;
  final Random random;
  List<ArkanoidBrick> bricks = [];
  final List<ArkanoidBall> balls = [];
  final List<ArkanoidDrop> drops = [];
  ArkanoidPhase phase = ArkanoidPhase.ready;
  int level = 1, lives = 3, score = 0;
  double paddleX = width / 2;
  double wideSeconds = 0;
  double _bonusCooldown = 0;
  int _levelDrops = 0;
  bool _lifeDropped = false;
  bool _lifeAwarded = false;
  String notice = '';
  double noticeSeconds = 0;

  ArkanoidEngine({Random? random}) : random = random ?? Random() {
    start();
  }

  double get paddleWidth => wideSeconds > 0 ? 152 : 76;
  double get speed => 230.0 + (level - 1) * 4;

  void start({int atLevel = 1}) {
    level = atLevel.clamp(1, ArkanoidLevels.count).toInt();
    lives = 3;
    score = 0;
    _bonusCooldown = 0;
    _lifeDropped = false;
    _lifeAwarded = false;
    _loadLevel();
  }

  void _loadLevel() {
    _levelDrops = 0;
    bricks = ArkanoidLevels.build(level);
    paddleX = width / 2;
    wideSeconds = 0;
    drops.clear();
    notice = '';
    noticeSeconds = 0;
    _serve();
  }

  void _serve() {
    phase = ArkanoidPhase.ready;
    balls
      ..clear()
      ..add(ArkanoidBall(paddleX, paddleY - radius - 1, 0, 0));
  }

  void nextLevel() {
    if (phase != ArkanoidPhase.cleared) return;
    level++;
    _loadLevel();
  }

  void movePaddle(double x) {
    paddleX = x.clamp(paddleWidth / 2, width - paddleWidth / 2).toDouble();
    if (phase == ArkanoidPhase.ready && balls.isNotEmpty)
      balls.first.x = paddleX;
  }

  void launch() {
    if (phase != ArkanoidPhase.ready) return;
    balls.first
      ..vx = speed * 0.32
      ..vy = -speed * sqrt(1 - 0.32 * 0.32);
    phase = ArkanoidPhase.playing;
  }

  void update(double elapsed) {
    if (phase != ArkanoidPhase.playing || elapsed <= 0) return;
    // Małe kroki zapobiegają przeskakiwaniu przez klocki; po zacięciu
    // nie nadrabiamy całego czasu kosztem nagłej utraty życia.
    var remaining = min(elapsed, 0.05);
    while (remaining > 0 && phase == ArkanoidPhase.playing) {
      final dt = min(remaining, 1 / 240);
      _step(dt);
      remaining -= dt;
    }
  }

  void _step(double dt) {
    _bonusCooldown = max(0, _bonusCooldown - dt);
    wideSeconds = max(0, wideSeconds - dt);
    noticeSeconds = max(0, noticeSeconds - dt);
    for (final ball in balls) {
      final oldY = ball.y;
      ball.x += ball.vx * dt;
      ball.y += ball.vy * dt;
      if (ball.x < radius) {
        ball.x = radius;
        ball.vx = ball.vx.abs();
      } else if (ball.x > width - radius) {
        ball.x = width - radius;
        ball.vx = -ball.vx.abs();
      }
      if (ball.y < radius) {
        ball.y = radius;
        ball.vy = ball.vy.abs();
      }
      if (ball.vy > 0 &&
          oldY + radius <= paddleY &&
          ball.y + radius >= paddleY &&
          ball.x >= paddleX - paddleWidth / 2 - radius &&
          ball.x <= paddleX + paddleWidth / 2 + radius) {
        final hit = ((ball.x - paddleX) / (paddleWidth / 2)).clamp(-1.0, 1.0);
        // Odbicie od środka prawie pionowe, od końców wyraźnie ukośne.
        var angle = hit * 1.05;
        if (angle.abs() < 0.10) angle = ball.vx < 0 ? -0.10 : 0.10;
        ball
          ..y = paddleY - radius - 0.01
          ..vx = speed * sin(angle)
          ..vy = -speed * cos(angle);
      }
      for (var i = 0; i < bricks.length; i++) {
        final brick = bricks[i];
        if (!_hitBrick(ball, brick)) continue;
        brick.hits--;
        score += 10;
        if (brick.hits == 0) {
          bricks.removeAt(i);
          score += 15;
          // Maksymalnie 3 bonusy na planszę, z przerwą w aktywnej grze.
          if (_levelDrops < 3 &&
              _bonusCooldown <= 0 &&
              random.nextDouble() < 0.06) {
            final roll = random.nextDouble();
            final kind = !_lifeDropped && roll < 0.10
                ? ArkanoidBonus.extraLife
                : roll < 0.50
                    ? ArkanoidBonus.widePaddle
                    : roll < 0.85
                        ? ArkanoidBonus.addOneBall
                        : ArkanoidBonus.addTwoBalls;
            if (kind == ArkanoidBonus.extraLife) _lifeDropped = true;
            _levelDrops++;
            _bonusCooldown = 12;
            drops.add(ArkanoidDrop(
                brick.x + brick.width / 2, brick.y + brick.height / 2, kind));
          }
        }
        break;
      }
    }
    balls.removeWhere((ball) => ball.y - radius > height);
    if (bricks.isEmpty) {
      score += 100 * level;
      phase = level == ArkanoidLevels.count
          ? ArkanoidPhase.completed
          : ArkanoidPhase.cleared;
      drops.clear();
      return;
    }
    if (balls.isEmpty) {
      lives--;
      wideSeconds = 0;
      drops.clear();
      if (lives <= 0) {
        phase = ArkanoidPhase.gameOver;
      } else {
        _serve();
      }
      return;
    }
    for (final drop in List<ArkanoidDrop>.of(drops)) {
      final oldY = drop.y;
      drop.y += 100 * dt;
      if (oldY + 10 <= paddleY &&
          drop.y + 10 >= paddleY &&
          (drop.x - paddleX).abs() <= paddleWidth / 2 + 12) {
        drops.remove(drop);
        applyBonus(drop.kind);
      } else if (drop.y > height + 12) {
        drops.remove(drop);
      }
    }
  }

  bool _hitBrick(ArkanoidBall ball, ArkanoidBrick brick) {
    final closestX = ball.x.clamp(brick.x, brick.x + brick.width).toDouble();
    final closestY = ball.y.clamp(brick.y, brick.y + brick.height).toDouble();
    final dx = ball.x - closestX, dy = ball.y - closestY;
    final distance2 = dx * dx + dy * dy;
    if (distance2 > radius * radius) return false;
    double nx, ny, overlap;
    if (distance2 > 0.000001) {
      final distance = sqrt(distance2);
      nx = dx / distance;
      ny = dy / distance;
      overlap = radius - distance;
    } else {
      final edges = [
        ball.x - brick.x,
        brick.x + brick.width - ball.x,
        ball.y - brick.y,
        brick.y + brick.height - ball.y
      ];
      var edge = 0;
      for (var i = 1; i < 4; i++) {
        if (edges[i] < edges[edge]) edge = i;
      }
      nx = edge == 0
          ? -1
          : edge == 1
              ? 1
              : 0;
      ny = edge == 2
          ? -1
          : edge == 3
              ? 1
              : 0;
      overlap = radius + edges[edge];
    }
    ball.x += nx * (overlap + 0.01);
    ball.y += ny * (overlap + 0.01);
    final dot = ball.vx * nx + ball.vy * ny;
    if (dot >= 0) return false;
    ball.vx -= 2 * dot * nx;
    ball.vy -= 2 * dot * ny;
    // Po trafieniu narożnika piłka nie może utknąć w poziomym locie.
    if (ball.vy.abs() < speed * 0.22) {
      ball.vy = (ball.vy < 0 ? -1 : 1) * speed * 0.22;
      ball.vx =
          (ball.vx < 0 ? -1 : 1) * sqrt(speed * speed - ball.vy * ball.vy);
    }
    return true;
  }

  void applyBonus(ArkanoidBonus kind) {
    switch (kind) {
      case ArkanoidBonus.widePaddle:
        wideSeconds = 20;
        movePaddle(paddleX);
        notice = 'Platforma ×2 · 20 s';
        break;
      case ArkanoidBonus.extraLife:
        if (_lifeAwarded) return;
        _lifeAwarded = true;
        _lifeDropped = true;
        lives++;
        notice = '♥ Dodatkowe życie';
        break;
      case ArkanoidBonus.addOneBall:
      case ArkanoidBonus.addTwoBalls:
        if (balls.isEmpty) return;
        final count = kind == ArkanoidBonus.addOneBall ? 1 : 2;
        final ball = balls.first;
        var added = 0;
        for (var i = 0; i < count && balls.length < maxBalls; i++) {
          final angle = atan2(ball.vx, -ball.vy) + (i == 0 ? 0.32 : -0.32);
          var vx = speed * sin(angle);
          var vy = -speed * cos(angle);
          if (vy.abs() < speed * 0.22) {
            vy = (vy < 0 ? -1 : 1) * speed * 0.22;
            vx = (vx < 0 ? -1 : 1) * sqrt(speed * speed - vy * vy);
          }
          balls.add(ArkanoidBall(ball.x, ball.y, vx, vy));
          added++;
        }
        notice = added == 0 ? 'Limit piłek' : 'Piłki +$added';
        break;
    }
    noticeSeconds = 2.5;
  }
}
