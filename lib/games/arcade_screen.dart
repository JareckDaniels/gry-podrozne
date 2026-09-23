import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import '../app_theme.dart';
import '../rekordy.dart';
import 'arcade_engines.dart';

class ArcadeScreen extends StatefulWidget {
  final bool balloon;
  const ArcadeScreen({super.key, required this.balloon});
  @override
  State<ArcadeScreen> createState() => _ArcadeScreenState();
}

class _ArcadeScreenState extends State<ArcadeScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final ArcadeEngine game;
  late final Ticker ticker;
  Duration? previous;
  bool started = false, paused = false, reporting = false;
  int best = 0;
  double scale = 1;
  Gra get record => widget.balloon ? Gry.balon : Gry.biegacz;
  Color get accent => widget.balloon ? AppColors.zielen : AppColors.bursztyn;
  bool get running => started && !paused && !game.over && !reporting;

  @override
  void initState() {
    super.initState();
    game = widget.balloon ? BalloonEngine() : RunnerEngine();
    ticker = createTicker(tick);
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight
    ]);
    loadBest();
  }

  Future<void> loadBest() async {
    final scores = await Rekordy.wczytaj(record);
    if (mounted) setState(() => best = scores.isEmpty ? 0 : scores.first.wynik);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ticker.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) pause();
  }

  @override
  void didChangeMetrics() {
    pause();
  }

  void pause() {
    if (!running) return;
    ticker.stop();
    previous = null;
    if (game is RunnerEngine) (game as RunnerEngine).release();
    setState(() => paused = true);
  }

  void resume() {
    setState(() => paused = false);
    previous = null;
    ticker.start();
  }

  void start() {
    ticker.stop();
    if (game is RunnerEngine) {
      (game as RunnerEngine).reset();
    } else {
      (game as BalloonEngine).reset();
    }
    setState(() {
      started = true;
      paused = false;
    });
    previous = null;
    ticker.start();
  }

  void tick(Duration elapsed) {
    final last = previous;
    previous = elapsed;
    if (!running || last == null) return;
    game.update((elapsed - last).inMicroseconds / 1e6);
    if (game.over) {
      ticker.stop();
      finish();
    }
    setState(() {});
  }

  Future<void> finish() async {
    reporting = true;
    try {
      await Rekordy.zglos(context, record, game.score);
    } finally {
      if (mounted) {
        setState(() => reporting = false);
        loadBest();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final landscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    return Scaffold(
      appBar: AppBar(
          title: Text(record.nazwa),
          toolbarHeight: landscape ? 44 : 56,
          actions: [
            IconButton(
                tooltip: paused ? 'Wznów' : 'Pauza',
                onPressed: started && !game.over && !reporting
                    ? (paused ? resume : pause)
                    : null,
                icon: Icon(
                    paused ? Icons.play_arrow_rounded : Icons.pause_rounded)),
            if (UstawieniaRekordow.instance.wlaczone(record))
              IconButton(
                  tooltip: 'Najlepsze wyniki',
                  icon: const Icon(Icons.emoji_events_outlined),
                  onPressed: reporting
                      ? null
                      : () {
                          pause();
                          Rekordy.pokaz(context, record);
                        }),
            IconButton(
                tooltip: 'Nowa gra',
                icon: const Icon(Icons.refresh_rounded),
                onPressed: reporting ? null : start),
          ]),
      body: SafeArea(child: LayoutBuilder(builder: (context, constraints) {
        scale = min(constraints.maxWidth / 400, constraints.maxHeight / 420);
        if (scale <= 0) return const SizedBox.shrink();
        final w = constraints.maxWidth / scale,
            h = constraints.maxHeight / scale;
        if ((game.width - w).abs() > 0.01 || (game.height - h).abs() > 0.01)
          game.resize(w, h);
        return Stack(children: [
          Positioned.fill(
              child: Listener(
            onPointerDown: (_) {
              if (running && game is RunnerEngine)
                (game as RunnerEngine).press();
            },
            onPointerUp: (_) {
              if (game is RunnerEngine) (game as RunnerEngine).release();
            },
            onPointerCancel: (_) {
              if (game is RunnerEngine) (game as RunnerEngine).release();
            },
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragUpdate: (d) {
                if (running && game is BalloonEngine)
                  (game as BalloonEngine).drag(d.delta.dx / scale);
              },
              child: CustomPaint(painter: _ArcadePainter(game, accent)),
            ),
          )),
          Positioned(
              top: 12,
              left: 16,
              right: 16,
              child: IgnorePointer(
                  child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                spacing: 8,
                runSpacing: 6,
                children: [
                  _badge(
                      widget.balloon
                          ? Icons.stars_rounded
                          : Icons.route_rounded,
                      '${game.score} ${record.jednostka}',
                      accent),
                  if (UstawieniaRekordow.instance.wlaczone(record))
                    _badge(Icons.emoji_events_outlined, 'Rekord $best',
                        AppColors.tekstSzary),
                ],
              ))),
          if (running)
            Positioned(
                bottom: 12,
                left: 16,
                right: 16,
                child: IgnorePointer(
                    child: Text(
                        widget.balloon
                            ? 'PRZESUWAJ PALCEM W BOK'
                            : 'DOTKNIJ, ABY SKOCZYĆ · PRZYTRZYMAJ, ABY SKOCZYĆ WYŻEJ',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 10,
                            letterSpacing: 1.1,
                            color: AppColors.tekstSzary)))),
          if (!started || paused || game.over)
            Positioned.fill(
                child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 360),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                      color: AppColors.tloJasniejsze.withOpacity(0.97),
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(color: accent.withOpacity(0.3)),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 30)
                      ]),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(
                        paused
                            ? Icons.pause_circle_outline
                            : game.over
                                ? Icons.flag_rounded
                                : widget.balloon
                                    ? Icons.air_rounded
                                    : Icons.directions_run_rounded,
                        size: landscape ? 32 : 46,
                        color: accent),
                    const SizedBox(height: 10),
                    Text(
                        paused
                            ? 'Chwila przerwy'
                            : game.over
                                ? 'Koniec gry'
                                : record.nazwa,
                        style: const TextStyle(
                            fontSize: 25, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 10),
                    Text(
                        paused
                            ? 'Wróć do gry, kiedy będziesz gotowy.'
                            : game.over
                                ? 'Twój wynik: ${game.score} ${record.jednostka}'
                                : widget.balloon
                                    ? 'Prowadź balon przez przerwy.\nZbieraj złote kółka i unikaj barier.'
                                    : 'Dotknij, aby skoczyć, przytrzymaj na wyższy skok.\nPod latającymi przeszkodami przebiegnij.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            height: 1.45, color: AppColors.tekstSzary)),
                    const SizedBox(height: 20),
                    SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: reporting
                              ? null
                              : paused
                                  ? resume
                                  : start,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: accent,
                              foregroundColor: AppColors.tlo),
                          child: Text(paused
                              ? 'Wznów'
                              : game.over
                                  ? 'Zagraj jeszcze raz'
                                  : 'Start'),
                        )),
                  ]),
                ),
              ),
            )),
        ]);
      })),
    );
  }

  Widget _badge(IconData icon, String text, Color color) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
          color: AppColors.tlo.withOpacity(0.8),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.18))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 17, color: color),
        const SizedBox(width: 8),
        Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w700))
      ]));
}

class _ArcadePainter extends CustomPainter {
  final ArcadeEngine game;
  final Color accent;
  _ArcadePainter(this.game, this.accent);
  final Paint p = Paint();
  void rounded(Canvas c, Rect rect, Color color, [double radius = 6]) {
    p
      ..shader = null
      ..style = PaintingStyle.fill
      ..color = color;
    c.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)), p);
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / game.width, size.height / game.height);
    final w = game.width, h = game.height;
    canvas.clipRect(Rect.fromLTWH(0, 0, w, h));
    final balloon = game is BalloonEngine;
    p.shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: balloon
                ? [const Color(0xFF11263B), const Color(0xFF234654)]
                : [const Color(0xFF151D35), const Color(0xFF302B42)])
        .createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), p);
    p.shader = null;
    p.color = const Color(0xFFF9DFA7).withOpacity(0.14);
    canvas.drawCircle(Offset(w * 0.80, h * 0.20), 42, p);
    p.color = const Color(0xFFF9DFA7).withOpacity(0.6);
    canvas.drawCircle(Offset(w * 0.80, h * 0.20), 27, p);
    // Dwie warstwy krajobrazu przewijają się wolniej niż przeszkody.
    for (var layer = 0; layer < 2; layer++) {
      final path = Path()..moveTo(0, h);
      final distance = balloon
          ? (game as BalloonEngine).travelled
          : (game as RunnerEngine).distance;
      for (var x = -20.0; x <= w + 20; x += 12) {
        final y = h * (0.72 + layer * 0.1) +
            sin((x + distance * (0.08 + layer * 0.04)) / 100) * 28 +
            cos(x / 57 + layer) * 10;
        path.lineTo(x, y);
      }
      path
        ..lineTo(w, h)
        ..close();
      p.color = layer == 0 ? const Color(0xFF294054) : const Color(0xFF1B3043);
      canvas.drawPath(path, p);
    }
    if (balloon) {
      drawBalloon(canvas, game as BalloonEngine);
    } else {
      drawRunner(canvas, game as RunnerEngine);
    }
    canvas.restore();
  }

  void drawRunner(Canvas c, RunnerEngine g) {
    final ground = g.height * 0.83;
    rounded(c, Rect.fromLTWH(0, ground, g.width, g.height - ground),
        const Color(0xFF131F2C), 0);
    rounded(
        c, Rect.fromLTWH(0, ground, g.width, 3), accent.withOpacity(0.7), 0);
    for (var i = 0; i < g.width / 32 + 2; i++) {
      final x = i * 32 - g.distance % 32;
      rounded(
          c, Rect.fromLTWH(x, ground + 16, 10, 2), const Color(0xFF344251), 1);
    }
    for (final o in g.obstacles) {
      final rect =
          Rect.fromLTWH(o.x, ground - o.bottom - o.height, o.width, o.height);
      if (o.flying) {
        final radius = min(rect.width, rect.height) / 2;
        c.save();
        c.translate(rect.center.dx, rect.center.dy);
        c.rotate(g.time * 8 + o.x * 0.012);
        final star = Path();
        for (var blade = 0; blade < 4; blade++) {
          final angle = blade * pi / 2;
          final tip = Offset(cos(angle), sin(angle)) * radius;
          final heel =
              Offset(cos(angle + 0.48), sin(angle + 0.48)) * (radius * 0.42);
          final notch = Offset(cos(angle + pi / 4), sin(angle + pi / 4)) *
              (radius * 0.28);
          if (blade == 0) {
            star.moveTo(tip.dx, tip.dy);
          } else {
            star.lineTo(tip.dx, tip.dy);
          }
          star
            ..lineTo(heel.dx, heel.dy)
            ..lineTo(notch.dx, notch.dy);
        }
        star.close();
        p
          ..style = PaintingStyle.fill
          ..shader = const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFF0F5FF),
                Color(0xFF8095B7),
                Color(0xFFC1D5EE)
              ]).createShader(
              Rect.fromCircle(center: Offset.zero, radius: radius));
        c.drawPath(star, p);
        p
          ..shader = null
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = const Color(0xFF4B607F);
        c.drawPath(star, p);
        p
          ..style = PaintingStyle.fill
          ..color = AppColors.koral;
        c.drawCircle(Offset.zero, radius * 0.23, p);
        p.color = AppColors.tlo;
        c.drawCircle(Offset.zero, radius * 0.10, p);
        c.restore();
      } else {
        rounded(c, rect, const Color(0xFF4EBCAB), 5);
        rounded(c, Rect.fromLTWH(o.x + 4, rect.top + 4, 4, o.height - 8),
            Colors.white.withOpacity(0.2), 2);
        rounded(
            c,
            Rect.fromLTWH(o.x + o.width - 6, rect.top + 4, 3, o.height - 8),
            Colors.black.withOpacity(0.12),
            1);
      }
    }
    final x = g.playerX, foot = ground - g.y;
    p
      ..style = PaintingStyle.fill
      ..color = Colors.black.withOpacity(0.22);
    c.drawOval(
        Rect.fromCenter(
            center: Offset(x, ground + 4),
            width: max(14, 34 - g.y * 0.12),
            height: 7),
        p);
    final stride = g.y > 0 ? 0.5 : sin(g.distance / 13);
    p
      ..color = accent
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    c.drawLine(Offset(x, foot - 17), Offset(x + stride * 10, foot - 2), p);
    c.drawLine(Offset(x, foot - 17), Offset(x - stride * 10, foot - 2), p);
    rounded(c, Rect.fromLTWH(x - 8, foot - 32, 16, 18), accent, 5);
    p
      ..color = const Color(0xFFFFD6AB)
      ..style = PaintingStyle.fill;
    c.drawCircle(Offset(x + 1, foot - 37), 8, p);
    rounded(c, Rect.fromLTWH(x - 7, foot - 43, 18, 5), AppColors.koral, 2);
    p
      ..color = AppColors.tlo
      ..strokeWidth = 2;
    c.drawCircle(Offset(x + 5, foot - 37), 1.5, p);
    p
      ..color = accent
      ..strokeWidth = 4;
    c.drawLine(Offset(x, foot - 28), Offset(x - stride * 10, foot - 20), p);
    p
      ..color = AppColors.koral
      ..strokeWidth = 3;
    c.drawLine(
        Offset(x - 7, foot - 31), Offset(x - 23, foot - 32 + stride * 3), p);
  }

  void drawBalloon(Canvas c, BalloonEngine g) {
    for (var i = 0; i < 8; i++) {
      final x = (i * 113.0 + 37) % g.width;
      final y = (i * 97 + g.travelled * 0.22) % g.height;
      p
        ..color = Colors.white.withOpacity(0.05)
        ..style = PaintingStyle.fill;
      c.drawOval(
          Rect.fromCenter(center: Offset(x, y), width: 75, height: 16), p);
    }
    for (final gate in g.gates) {
      for (final rect in [
        Rect.fromLTRB(0, gate.y - 8, gate.gap - gate.gapWidth / 2, gate.y + 8),
        Rect.fromLTRB(
            gate.gap + gate.gapWidth / 2, gate.y - 8, g.width, gate.y + 8)
      ]) {
        rounded(c, rect, const Color(0xFFDB7B85), 3);
        rounded(c, Rect.fromLTWH(rect.left, rect.top, rect.width, 3),
            Colors.white.withOpacity(0.25), 1);
        for (var x = rect.left + 10; x < rect.right - 5; x += 20) {
          rounded(c, Rect.fromLTWH(x, rect.top + 5, 4, 6),
              AppColors.tlo.withOpacity(0.25), 1);
        }
      }
    }
    for (final coin in g.coins) {
      p
        ..style = PaintingStyle.fill
        ..color = AppColors.bursztyn.withOpacity(0.14);
      c.drawCircle(Offset(coin.x, coin.y), 12, p);
      p
        ..color = AppColors.bursztyn
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      c.drawCircle(Offset(coin.x, coin.y), 6, p);
    }
    final center = Offset(g.x, g.balloonY);
    p
      ..style = PaintingStyle.fill
      ..shader = const LinearGradient(
              colors: [Color(0xFF9CE7CE), Color(0xFF3BAA98)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight)
          .createShader(Rect.fromCircle(center: center, radius: 19));
    c.drawCircle(center, 19, p);
    p.shader = null;
    p..color = const Color(0xFFDBF8CB).withOpacity(0.6);
    c.drawOval(Rect.fromCenter(center: center, width: 13, height: 37), p);
    p..color = Colors.white.withOpacity(0.55);
    c.drawOval(
        Rect.fromCenter(
            center: center + const Offset(-8, -8), width: 5, height: 8),
        p);
    p
      ..color = AppColors.tekstSzary
      ..strokeWidth = 1.5;
    c.drawLine(
        center + const Offset(-10, 15), center + const Offset(-6, 24), p);
    c.drawLine(center + const Offset(10, 15), center + const Offset(6, 24), p);
    rounded(
        c,
        Rect.fromCenter(
            center: center + const Offset(0, 27), width: 14, height: 10),
        AppColors.bursztyn,
        2);
  }

  @override
  bool shouldRepaint(covariant _ArcadePainter oldDelegate) => true;
}
