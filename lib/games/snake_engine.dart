import 'dart:math';

enum SnakeDirection { up, right, down, left }

// Logika niezależna od animacji i wielkości ekranu.
class SnakeEngine {
  static const columns = 20;
  static const rows = 24;
  final Random random;
  List<Point<int>> body = [];
  Point<int>? food;
  SnakeDirection direction = SnakeDirection.right;
  final List<SnakeDirection> _turns = [];
  int score = 0;
  bool over = false;
  bool won = false;

  SnakeEngine({Random? random}) : random = random ?? Random() {
    reset();
  }

  void reset() {
    body = [const Point(7, 12), const Point(6, 12), const Point(5, 12)];
    direction = SnakeDirection.right;
    _turns.clear();
    score = 0;
    over = false;
    won = false;
    _placeFood();
  }

  void turn(SnakeDirection next) {
    if (over || _turns.length >= 2) return;
    final previous = _turns.isEmpty ? direction : _turns.last;
    // Nie można zawrócić wprost na własną szyję. Dwa szybkie gesty
    // wykonujemy w kolejnych krokach, a nie jako natychmiastowy zwrot.
    if (next == previous || (next.index - previous.index).abs() == 2) return;
    _turns.add(next);
  }

  void clearTurns() => _turns.clear();

  void step() {
    if (over) return;
    if (_turns.isNotEmpty) direction = _turns.removeAt(0);
    const offsets = [Point(0, -1), Point(1, 0), Point(0, 1), Point(-1, 0)];
    final head = body.first + offsets[direction.index];
    final eating = head == food;
    // Ogon opuszcza swoje pole w tym samym kroku, o ile wąż nie rośnie.
    final occupied = eating ? body : body.take(body.length - 1);
    if (head.x < 0 || head.x >= columns || head.y < 0 || head.y >= rows ||
        occupied.contains(head)) {
      over = true;
      return;
    }
    body.insert(0, head);
    if (eating) {
      score++;
      _placeFood();
    } else {
      body.removeLast();
    }
  }

  void _placeFood() {
    final occupied = body.toSet();
    final free = <Point<int>>[];
    for (var y = 0; y < rows; y++) {
      for (var x = 0; x < columns; x++) {
        final point = Point(x, y);
        if (!occupied.contains(point)) free.add(point);
      }
    }
    food = free.isEmpty ? null : free[random.nextInt(free.length)];
    if (free.isEmpty) {
      won = true;
      over = true;
    }
  }
}
