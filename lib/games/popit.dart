import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import '../app_theme.dart';

class PopItScreen extends StatefulWidget {
  const PopItScreen({super.key});

  @override
  State<PopItScreen> createState() => _PopItScreenState();
}

enum _Faza { start, gra, blad, wygrana }

class _PopItScreenState extends State<PopItScreen> {
  static const int kolumny = 3;
  static const int wiersze = 4;
  static const int poleLacznie = kolumny * wiersze; // 12 okregow
  static const int cel = 10; // dojscie do poziomu 10 = wygrana
  static const int sekundNaPoziom = 3;

  final _rng = Random();
  int _poziom = 1;
  Set<int> _podswietlone = {}; // ktore okregi trzeba klikac
  Set<int> _klikniete = {}; // ktore juz poprawnie klikniete
  _Faza _faza = _Faza.start;
  Timer? _timer;
  int _pozostaloMs = 0;
  static const int _tikMs = 50;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _nowaGra() {
    _poziom = 1;
    _rozpocznijPoziom();
  }

  void _rozpocznijPoziom() {
    _timer?.cancel();
    // Losujemy tyle pol co numer poziomu (ale nie wiecej niz jest pol)
    final ile = min(_poziom, poleLacznie);
    final indeksy = List.generate(poleLacznie, (i) => i)..shuffle(_rng);
    _podswietlone = indeksy.take(ile).toSet();
    _klikniete = {};
    _pozostaloMs = sekundNaPoziom * 1000;

    setState(() => _faza = _Faza.gra);

    // Odliczanie czasu
    _timer = Timer.periodic(const Duration(milliseconds: _tikMs), (t) {
      if (!mounted) return;
      setState(() => _pozostaloMs -= _tikMs);
      if (_pozostaloMs <= 0) {
        t.cancel();
        // Czas minal, a nie wszystkie klikniete -> blad
        setState(() => _faza = _Faza.blad);
      }
    });
  }

  void _tapPole(int index) {
    if (_faza != _Faza.gra) return;

    if (!_podswietlone.contains(index)) {
      // Klikniety zly okrag -> blad
      _timer?.cancel();
      setState(() => _faza = _Faza.blad);
      return;
    }

    if (_klikniete.contains(index)) return; // juz klikniety

    setState(() => _klikniete.add(index));

    if (_klikniete.length == _podswietlone.length) {
      // Wszystkie podswietlone klikniete w czasie -> nastepny poziom
      _timer?.cancel();
      if (_poziom >= cel) {
        setState(() => _faza = _Faza.wygrana);
      } else {
        _poziom++;
        // krotka przerwa i nastepny poziom
        _timer = Timer(const Duration(milliseconds: 500), () {
          if (mounted) _rozpocznijPoziom();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Szybkie klikanie'),
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
            _pasekCzasu(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Rozmiar planszy ograniczony i szerokoscia, i wysokoscia,
                    // by nigdy nie wyszla poza ekran.
                    const odstep = 12.0;
                    final maxSzer = constraints.maxWidth;
                    final maxWys = constraints.maxHeight;
                    // Szerokosc kolka z ograniczenia poziomego i pionowego
                    final zSzer =
                        (maxSzer - odstep * (kolumny - 1)) / kolumny;
                    final zWys =
                        (maxWys - odstep * (wiersze - 1)) / wiersze;
                    final bok = min(zSzer, zWys);
                    final szerPlanszy = bok * kolumny + odstep * (kolumny - 1);
                    final wysPlanszy = bok * wiersze + odstep * (wiersze - 1);
                    return Center(
                      child: SizedBox(
                        width: szerPlanszy,
                        height: wysPlanszy,
                        child: _plansza(),
                      ),
                    );
                  },
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
        text = 'Klikaj podświetlone kółka, zanim minie czas!';
        break;
      case _Faza.gra:
        text = 'Klikaj szybko!';
        break;
      case _Faza.blad:
        text = 'Koniec! Doszedłeś do poziomu $_poziom';
        break;
      case _Faza.wygrana:
        text = 'Brawo! Wygrana!';
        break;
    }
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.tloJasniejsze,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.tekst)),
          const SizedBox(height: 2),
          Text('Poziom $_poziom z $cel',
              style: const TextStyle(
                  fontSize: 13, color: AppColors.tekstSzary)),
        ],
      ),
    );
  }

  Widget _pasekCzasu() {
    final ulamek =
        _faza == _Faza.gra ? (_pozostaloMs / (sekundNaPoziom * 1000)) : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: LinearProgressIndicator(
          value: ulamek.clamp(0.0, 1.0),
          minHeight: 8,
          backgroundColor: AppColors.tloJasniejsze,
          valueColor: AlwaysStoppedAnimation(
            ulamek > 0.3 ? AppColors.zielen : AppColors.koral,
          ),
        ),
      ),
    );
  }

  Widget _plansza() {
    return GridView.count(
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: kolumny,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: List.generate(poleLacznie, (i) {
        final aktywny = _podswietlone.contains(i) && _faza == _Faza.gra;
        final zrobiony = _klikniete.contains(i);
        return GestureDetector(
          onTap: () => _tapPole(i),
          child: _okrag(aktywny: aktywny, zrobiony: zrobiony),
        );
      }),
    );
  }

  Widget _okrag({required bool aktywny, required bool zrobiony}) {
    // Zrobiony = zielony pelny; aktywny = swiecacy bursztyn;
    // reszta = tylko kolorowa obwodka, pusty srodek.
    Color wypelnienie;
    Color obwodka;
    if (zrobiony) {
      wypelnienie = AppColors.zielen;
      obwodka = AppColors.zielen;
    } else if (aktywny) {
      wypelnienie = AppColors.bursztyn;
      obwodka = AppColors.bursztyn;
    } else {
      wypelnienie = Colors.transparent;
      obwodka = AppColors.tekstSzary.withOpacity(0.5);
    }
    return AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      decoration: BoxDecoration(
        color: wypelnienie,
        shape: BoxShape.circle,
        border: Border.all(color: obwodka, width: 3),
        boxShadow: aktywny
            ? [
                BoxShadow(
                  color: AppColors.bursztyn.withOpacity(0.6),
                  blurRadius: 18,
                  spreadRadius: 1,
                )
              ]
            : null,
      ),
    );
  }

  Widget _dolnyPasek() {
    if (_faza == _Faza.start) {
      return _przycisk('Start', AppColors.zielen, _nowaGra);
    }
    if (_faza == _Faza.blad) {
      return _przycisk('Zagraj jeszcze raz', AppColors.bursztyn, _nowaGra);
    }
    if (_faza == _Faza.wygrana) {
      return _przycisk('Zagraj jeszcze raz', AppColors.zielen, _nowaGra);
    }
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
