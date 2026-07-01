import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import '../app_theme.dart';

class SimonScreen extends StatefulWidget {
  const SimonScreen({super.key});

  @override
  State<SimonScreen> createState() => _SimonScreenState();
}

enum _Faza { start, pokaz, powtarzaj, blad, wygrana }

class _SimonScreenState extends State<SimonScreen> {
  static const int cel = 10; // dojscie do 10 = wygrana

  // Kolory pol: 0=zielony, 1=czerwony, 2=zolty, 3=niebieski
  static const _kolory = [
    Color(0xFF4CB782), // zielony
    Color(0xFFE85D5D), // czerwony
    Color(0xFFE8C13D), // zolty
    Color(0xFF4A9FE8), // niebieski
  ];

  final _rng = Random();
  final List<int> _sekwencja = [];
  int _krokGracza = 0; // ile z sekwencji gracz juz poprawnie powtorzyl
  int _podswietlone = -1; // ktore pole aktualnie sie swieci (-1 = zadne)
  _Faza _faza = _Faza.start;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _nowaGra() {
    _timer?.cancel();
    _sekwencja.clear();
    _krokGracza = 0;
    _dodajKrokIPokaz();
  }

  // Dokłada jeden losowy kolor i odtwarza cala sekwencje
  void _dodajKrokIPokaz() {
    _sekwencja.add(_rng.nextInt(4));
    _krokGracza = 0;
    _odtworzSekwencje();
  }

  void _odtworzSekwencje() {
    setState(() {
      _faza = _Faza.pokaz;
      _podswietlone = -1;
    });
    int i = 0;
    // Co 700 ms zapalamy kolejny kolor na ~400 ms
    _timer = Timer.periodic(const Duration(milliseconds: 700), (t) {
      if (!mounted) return;
      if (i >= _sekwencja.length) {
        t.cancel();
        setState(() {
          _faza = _Faza.powtarzaj;
          _podswietlone = -1;
        });
        return;
      }
      final kolor = _sekwencja[i];
      setState(() => _podswietlone = kolor);
      Timer(const Duration(milliseconds: 400), () {
        if (mounted) setState(() => _podswietlone = -1);
      });
      i++;
    });
  }

  void _tapPole(int index) {
    if (_faza != _Faza.powtarzaj) return;

    // Krotki blysk na dotkniecie
    setState(() => _podswietlone = index);
    Timer(const Duration(milliseconds: 200), () {
      if (mounted && _faza == _Faza.powtarzaj) {
        setState(() => _podswietlone = -1);
      }
    });

    if (index == _sekwencja[_krokGracza]) {
      // dobrze
      _krokGracza++;
      if (_krokGracza == _sekwencja.length) {
        // cala sekwencja powtorzona poprawnie
        if (_sekwencja.length >= cel) {
          setState(() => _faza = _Faza.wygrana);
        } else {
          // kolejna runda po krotkiej przerwie
          _timer = Timer(const Duration(milliseconds: 700), () {
            if (mounted) _dodajKrokIPokaz();
          });
        }
      }
    } else {
      // blad
      setState(() => _faza = _Faza.blad);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Simon'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Nowa gra',
            onPressed: _nowaGra,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _pasekStanu(),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: _plansza(),
                  ),
                ),
              ),
            ),
            _dolnyPasek(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _pasekStanu() {
    String text;
    switch (_faza) {
      case _Faza.start:
        text = 'Zapamiętaj kolejność kolorów';
        break;
      case _Faza.pokaz:
        text = 'Patrz uważnie...';
        break;
      case _Faza.powtarzaj:
        text = 'Twoja kolej — powtórz!';
        break;
      case _Faza.blad:
        text = 'Pomyłka! Doszedłeś do ${_sekwencja.length - 1}';
        break;
      case _Faza.wygrana:
        text = 'Brawo! Wygrana!';
        break;
    }

    // Poziom = dlugosc sekwencji (dla start pokazujemy 0)
    final poziom = _faza == _Faza.start ? 0 : _sekwencja.length;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.tloJasniejsze,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            text,
            style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w600,
                color: AppColors.tekst),
          ),
          const SizedBox(height: 4),
          Text(
            'Poziom $poziom z $cel',
            style: const TextStyle(fontSize: 14, color: AppColors.tekstSzary),
          ),
        ],
      ),
    );
  }

  Widget _plansza() {
    return GridView.count(
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      children: List.generate(4, (i) {
        final swieci = _podswietlone == i;
        final aktywne = _faza == _Faza.powtarzaj;
        return GestureDetector(
          onTap: () => _tapPole(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            decoration: BoxDecoration(
              color: swieci
                  ? _kolory[i]
                  : _kolory[i].withOpacity(aktywne ? 0.55 : 0.35),
              borderRadius: BorderRadius.circular(20),
              boxShadow: swieci
                  ? [
                      BoxShadow(
                        color: _kolory[i].withOpacity(0.7),
                        blurRadius: 24,
                        spreadRadius: 2,
                      )
                    ]
                  : null,
            ),
          ),
        );
      }),
    );
  }

  Widget _dolnyPasek() {
    // Przycisk startu / restartu zaleznie od fazy
    if (_faza == _Faza.start) {
      return _przycisk('Start', AppColors.zielen, _nowaGra);
    }
    if (_faza == _Faza.blad) {
      return _przycisk('Zagraj jeszcze raz', AppColors.bursztyn, _nowaGra);
    }
    if (_faza == _Faza.wygrana) {
      return _przycisk('Zagraj jeszcze raz', AppColors.zielen, _nowaGra);
    }
    // W trakcie pokazu/powtarzania - brak przycisku (pusto)
    return const SizedBox(height: 52);
  }

  Widget _przycisk(String tekst, Color kolor, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: kolor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(tekst,
              style: const TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}
