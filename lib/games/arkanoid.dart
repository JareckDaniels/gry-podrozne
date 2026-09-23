import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app_theme.dart';
import '../rekordy.dart';
import 'arkanoid_engine.dart';

class ArkanoidScreen extends StatefulWidget {
  const ArkanoidScreen({super.key});

  @override
  State<ArkanoidScreen> createState() => _ArkanoidScreenState();
}

class _ArkanoidScreenState extends State<ArkanoidScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const _progressKey = 'arkanoid_odblokowany_poziom';
  final _game = ArkanoidEngine();
  late final Ticker _ticker;
  Duration? _previousTick;
  bool _paused = false, _loading = true, _reporting = false;
  bool _helpOpen = false;
  int _unlocked = 1;
  String? _saveError;
  SharedPreferences? _prefs;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ticker = createTicker(_tick);
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      _unlocked = (_prefs!.getInt(_progressKey) ?? 1)
          .clamp(1, ArkanoidLevels.count)
          .toInt();
    } catch (_) {
      _saveError = 'Nie udało się odczytać postępu.';
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _unlock(int level) async {
    if (level <= _unlocked) return;
    _unlocked = level;
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      _prefs = prefs;
      if (!await prefs.setInt(_progressKey, _unlocked)) {
        throw StateError('Zapis nieudany');
      }
    } catch (_) {
      if (mounted)
        setState(() {
          _saveError = 'Postęp odblokowany na tę sesję; zapis nie powiódł się.';
        });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _pause();
  }

  void _tick(Duration elapsed) {
    final previous = _previousTick;
    _previousTick = elapsed;
    if (previous == null || _paused || _reporting) return;
    final before = _game.phase;
    _game.update((elapsed - previous).inMicroseconds / 1000000);
    if (_game.phase != ArkanoidPhase.playing) {
      _ticker.stop();
      _previousTick = null;
    }
    if (before != _game.phase) {
      if (_game.phase == ArkanoidPhase.cleared) _unlock(_game.level + 1);
      if (_game.phase == ArkanoidPhase.gameOver ||
          _game.phase == ArkanoidPhase.completed) {
        _reportScore();
      }
    }
    setState(() {});
  }

  Future<void> _reportScore() async {
    _reporting = true;
    try {
      await Rekordy.zglos(context, Gry.arkanoid, _game.score);
    } finally {
      if (mounted) setState(() => _reporting = false);
    }
  }

  void _pause() {
    if (_loading || _paused) return;
    if (_game.phase != ArkanoidPhase.playing &&
        _game.phase != ArkanoidPhase.ready) return;
    _ticker.stop();
    _previousTick = null;
    setState(() => _paused = true);
  }

  void _resume() {
    setState(() => _paused = false);
    _previousTick = null;
    if (_game.phase == ArkanoidPhase.playing) _ticker.start();
  }

  void _launch() {
    if (_paused || _loading || _reporting) return;
    if (_game.phase != ArkanoidPhase.ready) return;
    setState(_game.launch);
    _previousTick = null;
    _ticker.start();
  }

  void _start(int level) {
    _ticker.stop();
    _previousTick = null;
    setState(() {
      _game.start(atLevel: level);
      _paused = false;
    });
  }

  Future<void> _chooseLevel() async {
    _pause();
    final chosen = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Wybierz poziom'),
        content: SizedBox(
          width: 330,
          height: 340,
          child: Column(children: [
            const Text(
                'Nowa gra: 3 życia i 0 punktów.\n'
                'Odblokowane poziomy zostają zapisane.',
                style: TextStyle(fontSize: 13, color: AppColors.tekstSzary)),
            const SizedBox(height: 12),
            Expanded(
                child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
              ),
              itemCount: ArkanoidLevels.count,
              itemBuilder: (_, i) => OutlinedButton(
                style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
                onPressed:
                    i < _unlocked ? () => Navigator.pop(ctx, i + 1) : null,
                child: i < _unlocked
                    ? Text('${i + 1}')
                    : const Icon(Icons.lock_outline, size: 16),
              ),
            )),
          ]),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Zamknij'))
        ],
      ),
    );
    if (mounted && chosen != null) _start(chosen);
  }

  Future<void> _help() async {
    _pause();
    _helpOpen = true;
    await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
              title: const Text('Jak grać?'),
              content: const SingleChildScrollView(
                  child: Text(
                'Przesuwaj palcem po planszy lub po pasku pod nią, aby sterować '
                'platformą. Dotknij planszy albo przycisku „Wypuść piłkę”.\n\n'
                'Trafienie przy końcu platformy odbija piłkę pod większym kątem. '
                'Małe kreski na klocku oznaczają liczbę pozostałych trafień.\n\n'
                'Łap spadające bonusy:\n'
                '×2 / ×3 — mnożą piłki (maks. 24).\n'
                '↔ — platforma dwa razy szersza przez 20 sekund.\n'
                '+1 — dodatkowe życie.\n\n'
                'Życie tracisz, gdy spadną wszystkie piłki. Po stracie życia '
                'zniszczone klocki nie wracają. Po przegranej ponowienie poziomu '
                'daje 3 życia i zeruje wynik.\n\n'
                'Zapisujemy odblokowane poziomy. Po ponownym otwarciu gry '
                'wybierz poziom przyciskiem z kratką. HIGH-SCORE zapisuje się '
                'po przegranej lub ukończeniu wszystkich 30 plansz.',
              )),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Rozumiem'))
              ],
            ));
    _helpOpen = false;
  }

  String get _status {
    if (_paused) return 'Pauza';
    switch (_game.phase) {
      case ArkanoidPhase.ready:
        return 'Ustaw platformę i wypuść piłkę';
      case ArkanoidPhase.playing:
        return _game.noticeSeconds > 0
            ? _game.notice
            : 'Rozbij wszystkie klocki!';
      case ArkanoidPhase.cleared:
        return 'Poziom ukończony!';
      case ArkanoidPhase.gameOver:
        return 'Koniec gry · wynik: ${_game.score}';
      case ArkanoidPhase.completed:
        return 'Brawo! Ukończono wszystkie 30 poziomów!';
    }
  }

  void _primaryAction() {
    if (_paused) {
      _resume();
      return;
    }
    switch (_game.phase) {
      case ArkanoidPhase.ready:
        _launch();
        break;
      case ArkanoidPhase.playing:
        _pause();
        break;
      case ArkanoidPhase.cleared:
        setState(_game.nextLevel);
        break;
      case ArkanoidPhase.gameOver:
        _start(_game.level);
        break;
      case ArkanoidPhase.completed:
        _start(1);
        break;
    }
  }

  String get _buttonText {
    if (_paused) return 'Wznów';
    switch (_game.phase) {
      case ArkanoidPhase.ready:
        return 'Wypuść piłkę';
      case ArkanoidPhase.playing:
        return 'Pauza';
      case ArkanoidPhase.cleared:
        return 'Następny poziom';
      case ArkanoidPhase.gameOver:
        return 'Ponów poziom · nowy wynik';
      case ArkanoidPhase.completed:
        return 'Zagraj od początku';
    }
  }

  void _move(double x, double areaWidth) {
    if (_paused || _loading || _reporting) return;
    if (_game.phase != ArkanoidPhase.ready &&
        _game.phase != ArkanoidPhase.playing) return;
    setState(() => _game.movePaddle(x / areaWidth * ArkanoidEngine.width));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Arkanoid'), actions: [
        IconButton(
            tooltip: 'Poziomy',
            icon: const Icon(Icons.grid_view),
            onPressed: _loading || _reporting ? null : _chooseLevel),
        if (UstawieniaRekordow.instance.wlaczone(Gry.arkanoid))
          IconButton(
              tooltip: 'Najlepsze wyniki',
              icon: const Icon(Icons.emoji_events_outlined),
              onPressed: _reporting || _loading
                  ? null
                  : () {
                      _pause();
                      Rekordy.pokaz(context, Gry.arkanoid);
                    }),
        IconButton(
            tooltip: 'Zasady',
            icon: const Icon(Icons.help_outline),
            onPressed: _helpOpen || _loading || _reporting ? null : _help),
      ]),
      body: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : Column(children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
                    child: Column(children: [
                      Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 18,
                          runSpacing: 4,
                          children: [
                            Text('Poziom ${_game.level}/30',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.bursztyn)),
                            Text('♥ ${_game.lives}',
                                style: const TextStyle(color: AppColors.koral)),
                            Text('${_game.score} pkt',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                          ]),
                      const SizedBox(height: 4),
                      Text('${ArkanoidLevels.name(_game.level)} · $_status',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12)),
                      if (_saveError != null)
                        Text(_saveError!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.koral)),
                    ]),
                  ),
                  Expanded(
                      child: LayoutBuilder(builder: (context, constraints) {
                    final boardWidth = min(
                        constraints.maxWidth - 24,
                        max(1.0, constraints.maxHeight - 44) *
                            ArkanoidEngine.width /
                            ArkanoidEngine.height);
                    final boardHeight = boardWidth *
                        ArkanoidEngine.height /
                        ArkanoidEngine.width;
                    return Center(
                        child: SizedBox(
                            width: boardWidth,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTapUp: (_) => _launch(),
                                  onHorizontalDragStart: (d) =>
                                      _move(d.localPosition.dx, boardWidth),
                                  onHorizontalDragUpdate: (d) =>
                                      _move(d.localPosition.dx, boardWidth),
                                  child: SizedBox(
                                      height: boardHeight,
                                      width: boardWidth,
                                      child: CustomPaint(
                                        painter: _ArkanoidPainter(_game),
                                        child: _paused ||
                                                _game.phase ==
                                                    ArkanoidPhase.cleared ||
                                                _game.phase ==
                                                    ArkanoidPhase.gameOver ||
                                                _game.phase ==
                                                    ArkanoidPhase.completed
                                            ? Center(
                                                child: Container(
                                                padding:
                                                    const EdgeInsets.all(16),
                                                decoration: BoxDecoration(
                                                  color: AppColors.tlo
                                                      .withOpacity(0.94),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                    _paused
                                                        ? 'PAUZA'
                                                        : _game.phase ==
                                                                ArkanoidPhase
                                                                    .cleared
                                                            ? 'POZIOM UKOŃCZONY'
                                                            : _game.phase ==
                                                                    ArkanoidPhase
                                                                        .completed
                                                                ? 'WYGRANA!'
                                                                : 'KONIEC GRY',
                                                    textAlign: TextAlign.center,
                                                    style: const TextStyle(
                                                        fontSize: 20,
                                                        fontWeight:
                                                            FontWeight.bold)),
                                              ))
                                            : null,
                                      )),
                                ),
                                GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onHorizontalDragStart: (d) =>
                                      _move(d.localPosition.dx, boardWidth),
                                  onHorizontalDragUpdate: (d) =>
                                      _move(d.localPosition.dx, boardWidth),
                                  onTapDown: (d) =>
                                      _move(d.localPosition.dx, boardWidth),
                                  child: Container(
                                    height: 44,
                                    alignment: Alignment.center,
                                    color: AppColors.tloJasniejsze,
                                    child: const Text('←  PRZESUWAJ PALCEM  →',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: AppColors.tekstSzary)),
                                  ),
                                ),
                              ],
                            )));
                  })),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _reporting ? null : _primaryAction,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.bursztyn,
                            foregroundColor: AppColors.tlo,
                            padding: const EdgeInsets.symmetric(vertical: 12)),
                        child: Text(_buttonText),
                      ),
                    ),
                  ),
                ])),
    );
  }
}

class _ArkanoidPainter extends CustomPainter {
  final ArkanoidEngine game;
  _ArkanoidPainter(this.game);
  static const colors = [
    AppColors.koral,
    AppColors.bursztyn,
    Color(0xFFE8CF63),
    AppColors.zielen,
    Color(0xFF5FAFE1),
    AppColors.fiolet
  ];

  void _text(
      Canvas canvas, String text, Offset position, Color color, double size) {
    final painter = TextPainter(
      text: TextSpan(
          text: text,
          style: TextStyle(
              color: color,
              fontSize: size,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace')),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
        canvas, position - Offset(painter.width / 2, painter.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(
        size.width / ArkanoidEngine.width, size.height / ArkanoidEngine.height);
    canvas.clipRect(
        const Rect.fromLTWH(0, 0, ArkanoidEngine.width, ArkanoidEngine.height));
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF182940), Color(0xFF0E1321)],
      ).createShader(const Rect.fromLTWH(0, 0, 360, 560));
    canvas.drawRect(const Rect.fromLTWH(0, 0, 360, 560), paint);
    paint.shader = null;
    paint.color = const Color(0xFF25334A);
    for (var y = 12.0; y < 560; y += 20) {
      for (var x = 10.0; x < 360; x += 20) {
        canvas.drawRect(Rect.fromLTWH(x, y, 1, 1), paint);
      }
    }
    for (final brick in game.bricks) {
      paint.color = colors[brick.color];
      final rect = Rect.fromLTWH(brick.x, brick.y, brick.width, brick.height);
      paint.shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors[brick.color],
            Color.alphaBlend(Colors.black.withOpacity(0.2), colors[brick.color])
          ]).createShader(rect);
      canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(4)), paint);
      paint.shader = null;
      paint.color = Colors.white.withOpacity(0.3);
      canvas.drawRect(Rect.fromLTWH(brick.x, brick.y, brick.width, 3), paint);
      if (brick.hits > 1) {
        paint.color = AppColors.tlo;
        for (var i = 0; i < brick.hits; i++) {
          canvas.drawRect(
              Rect.fromLTWH(brick.x + 5 + i * 7, brick.y + 9, 4, 4), paint);
        }
      }
    }
    paint.color = game.wideSeconds > 0 ? AppColors.zielen : AppColors.bursztyn;
    canvas.drawRect(
        Rect.fromLTWH(
            game.paddleX - game.paddleWidth / 2,
            ArkanoidEngine.paddleY,
            game.paddleWidth,
            ArkanoidEngine.paddleHeight),
        paint);
    paint.color = Colors.white.withOpacity(0.65);
    canvas.drawRect(
        Rect.fromLTWH(game.paddleX - game.paddleWidth / 2,
            ArkanoidEngine.paddleY, game.paddleWidth, 3),
        paint);
    for (final ball in game.balls) {
      paint.color = AppColors.bursztyn.withOpacity(0.13);
      canvas.drawCircle(
          Offset(ball.x, ball.y), ArkanoidEngine.radius * 2.2, paint);
      paint.color = AppColors.tekst;
      canvas.drawCircle(Offset(ball.x, ball.y), ArkanoidEngine.radius, paint);
    }
    for (final drop in game.drops) {
      final labels = ['×2', '×3', '↔', '+1'];
      final dropColors = [
        AppColors.fiolet,
        const Color(0xFF5FAFE1),
        AppColors.zielen,
        AppColors.koral
      ];
      paint.color = dropColors[drop.kind.index];
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromCenter(
                  center: Offset(drop.x, drop.y), width: 28, height: 20),
              const Radius.circular(3)),
          paint);
      _text(canvas, labels[drop.kind.index], Offset(drop.x, drop.y),
          AppColors.tlo, 13);
    }
    if (game.wideSeconds > 0) {
      _text(canvas, '↔ ${game.wideSeconds.ceil()} s', const Offset(180, 25),
          AppColors.zielen, 13);
    }
    paint
      ..color = const Color(0xFF52617A)
      ..strokeWidth = 3;
    canvas.drawLine(const Offset(1, 560), const Offset(1, 1), paint);
    canvas.drawLine(const Offset(1, 1), const Offset(359, 1), paint);
    canvas.drawLine(const Offset(359, 1), const Offset(359, 560), paint);
    paint.color = AppColors.koral.withOpacity(0.45);
    for (var x = 4.0; x < 360; x += 12) {
      canvas.drawRect(Rect.fromLTWH(x, 557, 6, 2), paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ArkanoidPainter oldDelegate) => true;
}
