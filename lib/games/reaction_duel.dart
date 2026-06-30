import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import '../app_theme.dart';

class ReactionDuelScreen extends StatefulWidget {
  const ReactionDuelScreen({super.key});

  @override
  State<ReactionDuelScreen> createState() => _ReactionDuelScreenState();
}

enum _Phase { gotowi, czekaj, teraz, koniec }

class _ReactionDuelScreenState extends State<ReactionDuelScreen> {
  _Phase _phase = _Phase.gotowi;
  Timer? _timer;
  int? _winner; // 1 (gora) lub 2 (dol)
  String _message = '';

  void _start() {
    setState(() {
      _phase = _Phase.czekaj;
      _winner = null;
      _message = '';
    });
    // Losowe opoznienie 2-5 s, potem sygnal
    final ms = 2000 + Random().nextInt(3000);
    _timer = Timer(Duration(milliseconds: ms), () {
      if (mounted) setState(() => _phase = _Phase.teraz);
    });
  }

  void _tap(int player) {
    if (_phase == _Phase.gotowi || _phase == _Phase.koniec) {
      _start();
      return;
    }
    if (_phase == _Phase.czekaj) {
      // Falstart - kliknal za wczesnie, przegrywa
      _timer?.cancel();
      setState(() {
        _phase = _Phase.koniec;
        _winner = player == 1 ? 2 : 1;
        _message = 'Falstart! Za wczesnie';
      });
      return;
    }
    if (_phase == _Phase.teraz) {
      setState(() {
        _phase = _Phase.koniec;
        _winner = player;
        _message = 'Szybsza reakcja!';
      });
    }
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
        title: const Text('Pojedynek refleksu'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Od nowa',
            onPressed: () {
              _timer?.cancel();
              setState(() {
                _phase = _Phase.gotowi;
                _winner = null;
                _message = '';
              });
            },
          ),
        ],
      ),
      body: Column(
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
      ),
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
        text = 'Dotknij, aby zaczac';
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
        bg = won
            ? AppColors.zielen.withOpacity(0.9)
            : AppColors.tloJasniejsze;
        text = won ? 'Wygrana!\n$_message' : (lost ? _message : '');
        break;
    }

    return GestureDetector(
      onTap: () => _tap(player),
      child: Container(
        width: double.infinity,
        color: bg,
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
                    color: AppColors.tekst.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  text,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: _phase == _Phase.teraz ? 44 : 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.tekst,
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
