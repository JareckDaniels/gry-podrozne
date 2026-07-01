import 'package:flutter/material.dart';
import 'dart:async';
import '../app_theme.dart';

class TapBattleScreen extends StatefulWidget {
  const TapBattleScreen({super.key});

  @override
  State<TapBattleScreen> createState() => _TapBattleScreenState();
}

enum _Phase { gotowi, odliczanie, gra, koniec }

class _TapBattleScreenState extends State<TapBattleScreen> {
  _Phase _phase = _Phase.gotowi;
  int _score1 = 0;
  int _score2 = 0;
  int _countdown = 3;
  int _timeLeft = 10;
  Timer? _timer;

  static const _gameSeconds = 10;

  void _startCountdown() {
    setState(() {
      _phase = _Phase.odliczanie;
      _score1 = 0;
      _score2 = 0;
      _countdown = 3;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _countdown--);
      if (_countdown <= 0) {
        t.cancel();
        _startGame();
      }
    });
  }

  void _startGame() {
    setState(() {
      _phase = _Phase.gra;
      _timeLeft = _gameSeconds;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _timeLeft--);
      if (_timeLeft <= 0) {
        t.cancel();
        setState(() => _phase = _Phase.koniec);
      }
    });
  }

  void _tap(int player) {
    if (_phase != _Phase.gra) return;
    setState(() {
      if (player == 1) {
        _score1++;
      } else {
        _score2++;
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bitwa klikania'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Nowa runda',
            onPressed: _startCountdown,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: RotatedBox(
              quarterTurns: 2,
              child: _half(1, _score1),
            ),
          ),
          _centerBar(),
          Expanded(child: _half(2, _score2)),
        ],
      ),
    );
  }

  Widget _centerBar() {
    String text;
    switch (_phase) {
      case _Phase.gotowi:
        text = 'Dotknij dowolnej strony, aby zacząć';
        break;
      case _Phase.odliczanie:
        text = 'Start za $_countdown...';
        break;
      case _Phase.gra:
        text = 'Czas: $_timeLeft s';
        break;
      case _Phase.koniec:
        if (_score1 == _score2) {
          text = 'Remis! $_score1 : $_score2';
        } else {
          final w = _score1 > _score2 ? 1 : 2;
          text = 'Wygrywa gracz $w!  $_score1 : $_score2';
        }
        break;
    }
    return Container(
      width: double.infinity,
      color: AppColors.tlo,
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: AppColors.tekst,
        ),
      ),
    );
  }

  Widget _half(int player, int score) {
    final color = player == 1 ? AppColors.fiolet : AppColors.koral;
    final active = _phase == _Phase.gra;
    final isWinner = _phase == _Phase.koniec &&
        ((player == 1 && _score1 > _score2) ||
            (player == 2 && _score2 > _score1));

    return GestureDetector(
      onTap: () {
        // Start tylko z ekranu poczatkowego. Po koncu gry nowa runda
        // wylacznie przyciskiem restart (prawy gorny rog) - zeby nie
        // przeklikac wyniku dobijajac ekran.
        if (_phase == _Phase.gotowi) {
          _startCountdown();
        } else {
          _tap(player);
        }
      },
      child: Container(
        width: double.infinity,
        color: active
            ? color.withOpacity(0.22)
            : (isWinner ? color.withOpacity(0.35) : AppColors.tloJasniejsze),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Gracz $player',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.tekst.withOpacity(0.7),
                  )),
              const SizedBox(height: 8),
              Text(
                '$score',
                style: TextStyle(
                  fontSize: 72,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              if (active)
                const Text('Klikaj!',
                    style: TextStyle(
                        fontSize: 18, color: AppColors.tekstSzary)),
            ],
          ),
        ),
      ),
    );
  }
}
