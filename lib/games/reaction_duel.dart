import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import '../app_theme.dart';
import '../game_clock.dart';
import '../rekordy.dart';

class ReactionDuelScreen extends StatefulWidget {
  const ReactionDuelScreen({super.key});

  @override
  State<ReactionDuelScreen> createState() => _ReactionDuelScreenState();
}

enum _Phase { gotowi, czekaj, teraz, koniec }

class _ReactionDuelScreenState extends State<ReactionDuelScreen> {
  final _clock = GameClock();

  _Phase _phase = _Phase.gotowi;
  Timer? _timer;
  int? _winner; // 1 (gora) lub 2 (dol)
  String _message = '';
  Duration? _sygnal; // kiedy zapalil sie sygnal "TERAZ"

  void _start() {
    _clock.cancelAll();
    _clock.resume();
    setState(() {
      _phase = _Phase.czekaj;
      _winner = null;
      _message = '';
      _sygnal = null;
    });
    // Losowe opoznienie 2-5 s, potem sygnal
    final ms = 2000 + Random().nextInt(3000);
    _timer = _clock.once(Duration(milliseconds: ms), () {
      if (!mounted) return;
      setState(() {
        _phase = _Phase.teraz;
        _sygnal = _clock.elapsed;
      });
    });
  }

  void _tap(int player) {
    if (_clock.paused) return;
    // Start tylko z ekranu poczatkowego. Po koncu - nowa runda wylacznie
    // przyciskiem restart, zeby nie przeklikac wyniku.
    if (_phase == _Phase.gotowi) {
      _start();
      return;
    }
    if (_phase == _Phase.koniec) {
      return;
    }
    if (_phase == _Phase.czekaj) {
      // Falstart - kliknal za wczesnie, przegrywa
      _timer?.cancel();
      setState(() {
        _phase = _Phase.koniec;
        _winner = player == 1 ? 2 : 1;
        _message = 'Falstart! Za wcześnie';
      });
      return;
    }
    if (_phase == _Phase.teraz) {
      final start = _sygnal;
      final ms = start == null ? null : (_clock.elapsed - start).inMilliseconds;
      setState(() {
        _phase = _Phase.koniec;
        _winner = player;
        _message = ms == null ? 'Szybsza reakcja!' : 'Reakcja: $ms ms';
      });
      if (ms != null && ms > 0) {
        Rekordy.zglos(context, Gry.refleks, ms);
      }
    }
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pojedynek refleksu'),
        actions: [
          GamePauseButton(clock: _clock),
          RekordyPrzycisk(gra: Gry.refleks, beforeOpen: _clock.pause),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Nowa runda',
            onPressed: () {
              _timer?.cancel();
              _start();
            },
          ),
        ],
      ),
      body: GamePauseLayer(
          clock: _clock,
          child: SafeArea(
              child: Column(
            children: [
              // Gracz 1 (gora) - obrocony, by patrzyl ze swojej strony
              Expanded(
                child: RotatedBox(
                  quarterTurns: 2,
                  child: _half(1),
                ),
              ),
              const Divider(height: 2, thickness: 2, color: AppColors.tlo),
              // Gracz 2 (dol)
              Expanded(child: _half(2)),
            ],
          ))),
    );
  }

  Widget _half(int player) {
    Color bg;
    String text;
    final won = _phase == _Phase.koniec && _winner == player;
    final lost = _phase == _Phase.koniec && _winner != player;

    switch (_phase) {
      case _Phase.gotowi:
        bg = AppColors.tloJasniejsze;
        text = 'Dotknij, aby zacząć';
        break;
      case _Phase.czekaj:
        bg = AppColors.koral.withOpacity(0.25);
        text = 'Czekaj...';
        break;
      case _Phase.teraz:
        bg = AppColors.zielen;
        text = 'TERAZ!';
        break;
      case _Phase.koniec:
        bg = won ? AppColors.zielen.withOpacity(0.9) : AppColors.tloJasniejsze;
        text = won ? 'Wygrana!\n$_message' : (lost ? _message : '');
        break;
    }

    return GestureDetector(
      onTapDown: (_) => _tap(player),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
              bg,
              Color.alphaBlend(Colors.black.withOpacity(0.18), bg)
            ])),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Gracz $player',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: (_phase == _Phase.teraz || won
                            ? AppColors.tlo
                            : AppColors.tekst)
                        .withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  text,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: _phase == _Phase.teraz ? 44 : 22,
                    fontWeight: FontWeight.bold,
                    color: _phase == _Phase.teraz || won
                        ? AppColors.tlo
                        : AppColors.tekst,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
