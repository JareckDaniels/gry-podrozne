import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../rekordy.dart';
import 'snake_engine.dart';

class SnakeScreen extends StatefulWidget {
  const SnakeScreen({super.key});

  @override
  State<SnakeScreen> createState() => _SnakeScreenState();
}

class _SnakeScreenState extends State<SnakeScreen> with WidgetsBindingObserver {
  final _game = SnakeEngine();
  Timer? _timer;
  bool _started = false;
  bool _paused = false;
  bool _reporting = false;
  Offset? _gestureStart;

  bool get _running => _started && !_paused && !_game.over;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _pause();
  }

  void _start() {
    _timer?.cancel();
    setState(() {
      _game.reset();
      _started = true;
      _paused = false;
      _gestureStart = null;
    });
    _schedule();
  }

  void _schedule() {
    _timer?.cancel();
    if (!_running) return;
    // Stopniowe przyspieszanie, maksymalnie 10 pól na sekundę.
    final milliseconds = max(100, 220 - (_game.score ~/ 5) * 10);
    _timer = Timer(Duration(milliseconds: milliseconds), () {
      if (!mounted || !_running) return;
      setState(_game.step);
      if (_game.over) {
        _report();
      } else {
        _schedule();
      }
    });
  }

  Future<void> _report() async {
    setState(() => _reporting = true);
    try {
      await Rekordy.zglos(context, Gry.snake, _game.score);
    } finally {
      if (mounted) setState(() => _reporting = false);
    }
  }

  void _pause() {
    if (!_running) return;
    _timer?.cancel();
    setState(() {
      _paused = true;
      _gestureStart = null;
      _game.clearTurns();
    });
  }

  void _resume() {
    setState(() => _paused = false);
    _schedule();
  }

  void _swipe(DragUpdateDetails details) {
    final start = _gestureStart;
    if (!_running || start == null) return;
    final delta = details.localPosition - start;
    if (delta.distance < 14) return;
    final direction = delta.dx.abs() > delta.dy.abs()
        ? (delta.dx > 0 ? SnakeDirection.right : SnakeDirection.left)
        : (delta.dy > 0 ? SnakeDirection.down : SnakeDirection.up);
    _game.turn(direction);
    _gestureStart =
        null; // Jeden gest = jeden skręt, bez czekania na puszczenie.
  }

  @override
  Widget build(BuildContext context) {
    final status = !_started
        ? 'Zbieraj piksele i rośnij!'
        : _game.over
            ? (_game.won ? 'Brawo! Cała plansza jest Twoja!' : 'Koniec gry!')
            : _paused
                ? 'Pauza'
                : 'Uważaj na ściany i własny ogon';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wąż'),
        actions: [
          if (UstawieniaRekordow.instance.wlaczone(Gry.snake))
            IconButton(
              tooltip: 'Najlepsze wyniki',
              icon: const Icon(Icons.emoji_events_outlined),
              onPressed: _reporting
                  ? null
                  : () {
                      _pause();
                      Rekordy.pokaz(context, Gry.snake);
                    },
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 6, 16, 0),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: AppTheme.panel(AppColors.zielen),
              child: Column(children: [
                Text('Wynik: ${_game.score}',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppColors.zielen,
                    )),
                const SizedBox(height: 4),
                Text(status, textAlign: TextAlign.center),
              ]),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: AspectRatio(
                    aspectRatio: SnakeEngine.columns / SnakeEngine.rows,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onPanDown: (d) => _gestureStart = d.localPosition,
                      onPanUpdate: _swipe,
                      onPanEnd: (_) => _gestureStart = null,
                      onPanCancel: () => _gestureStart = null,
                      child: Semantics(
                        label: 'Plansza węża. Przesuwaj palcem w górę, w dół, '
                            'w lewo lub w prawo.',
                        child: CustomPaint(
                          painter: _SnakePainter(
                            List.of(_game.body),
                            _game.food,
                            _game.direction,
                          ),
                          child: Center(
                            child: !_running
                                ? Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: AppColors.tlo.withOpacity(0.9),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      !_started
                                          ? 'SNAKE'
                                          : _game.over
                                              ? (_game.won
                                                  ? 'WYGRANA!'
                                                  : 'KONIEC GRY')
                                              : 'PAUZA',
                                      style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                  'Przesuwaj palcem po planszy: ↑ ↓ ← →\n'
                  '1 piksel = 1 punkt. Ściana lub ogon kończy grę.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.tekstSzary)),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _reporting
                      ? null
                      : !_started || _game.over
                          ? _start
                          : _paused
                              ? _resume
                              : _pause,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.zielen,
                    foregroundColor: AppColors.tlo,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(!_started
                      ? 'Start'
                      : _game.over
                          ? 'Zagraj jeszcze raz'
                          : _paused
                              ? 'Wznów'
                              : 'Pauza'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SnakePainter extends CustomPainter {
  final List<Point<int>> body;
  final Point<int>? food;
  final SnakeDirection direction;
  _SnakePainter(this.body, this.food, this.direction);

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / SnakeEngine.columns;
    final paint = Paint()..color = const Color(0xFF9EAD79);
    canvas.drawRect(Offset.zero & size, paint);
    paint.color = const Color(0xFF92A16F);
    paint.strokeWidth = 0.5;
    for (var x = 1; x < SnakeEngine.columns; x++) {
      canvas.drawLine(
          Offset(x * cell, 0), Offset(x * cell, size.height), paint);
    }
    for (var y = 1; y < SnakeEngine.rows; y++) {
      canvas.drawLine(Offset(0, y * cell), Offset(size.width, y * cell), paint);
    }
    paint.color = const Color(0xFF263522);
    for (final part in body) {
      canvas.drawRect(
          Rect.fromLTWH(
              part.x * cell + 1, part.y * cell + 1, cell - 2, cell - 2),
          paint);
    }
    final snack = food;
    if (snack != null) {
      canvas.drawRect(
          Rect.fromLTWH((snack.x + 0.22) * cell, (snack.y + 0.22) * cell,
              cell * 0.56, cell * 0.56),
          paint);
    }
    // Dwa jasne piksele oczu wskazują aktualny kierunek głowy.
    paint.color = const Color(0xFFCFDCA6);
    final head = body.first;
    final horizontal =
        direction == SnakeDirection.left || direction == SnakeDirection.right;
    final front =
        direction == SnakeDirection.right || direction == SnakeDirection.down
            ? 0.7
            : 0.3;
    for (final side in [0.3, 0.7]) {
      canvas.drawRect(
          Rect.fromCenter(
            center: Offset((head.x + (horizontal ? front : side)) * cell,
                (head.y + (horizontal ? side : front)) * cell),
            width: cell * 0.15,
            height: cell * 0.15,
          ),
          paint);
    }
    paint
      ..color = const Color(0xFF263522)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawRect((Offset.zero & size).deflate(2), paint);
  }

  @override
  bool shouldRepaint(covariant _SnakePainter oldDelegate) => true;
}
