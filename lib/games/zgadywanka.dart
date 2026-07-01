import 'package:flutter/material.dart';
import 'dart:math';
import '../app_theme.dart';
import 'slowa_baza.dart';

class ZgadywankaScreen extends StatefulWidget {
  const ZgadywankaScreen({super.key});

  @override
  State<ZgadywankaScreen> createState() => _ZgadywankaScreenState();
}

class _ZgadywankaScreenState extends State<ZgadywankaScreen> {
  final _rng = Random();
  late List<int> _kolejnosc; // pomieszana kolejnosc indeksow slow
  int _pozycja = 0;

  late SlowoZagadka _biezace;
  late List<bool> _odsloniete; // ktore litery sa widoczne od razu
  late List<TextEditingController> _pola; // kontrolery dla pol do wpisania
  late List<FocusNode> _ogniska;
  bool _poddane = false;
  bool _zgadniete = false;

  @override
  void initState() {
    super.initState();
    _kolejnosc = List.generate(bazaSlow.length, (i) => i)..shuffle(_rng);
    _przygotujSlowo();
  }

  void _przygotujSlowo() {
    _biezace = bazaSlow[_kolejnosc[_pozycja]];
    final litery = _biezace.slowo.split('');
    final n = litery.length;

    // Odsloniamy okolo 40% liter (min 1), reszta do wpisania.
    // Spacje/laczniki (gdyby byly) traktujemy jak odsloniete.
    final doOdsloniecia = max(1, (n * 0.4).floor());
    _odsloniete = List.filled(n, false);
    final indeksy = List.generate(n, (i) => i)..shuffle(_rng);
    int odsloniete = 0;
    for (final i in indeksy) {
      if (odsloniete >= doOdsloniecia) break;
      _odsloniete[i] = true;
      odsloniete++;
    }

    _pola = [];
    _ogniska = [];
    for (int i = 0; i < n; i++) {
      _pola.add(TextEditingController());
      _ogniska.add(FocusNode());
    }
    _poddane = false;
    _zgadniete = false;
  }

  @override
  void dispose() {
    for (final c in _pola) {
      c.dispose();
    }
    for (final f in _ogniska) {
      f.dispose();
    }
    super.dispose();
  }

  // Normalizacja do porownania: male litery + zamiana ogonkow na podstawowe.
  // Dzieki temu "łokieć" i "lokiec" sa traktowane tak samo.
  String _normalizuj(String s) {
    const mapa = {
      'ą': 'a', 'ć': 'c', 'ę': 'e', 'ł': 'l', 'ń': 'n',
      'ó': 'o', 'ś': 's', 'ź': 'z', 'ż': 'z',
    };
    final buf = StringBuffer();
    for (final ch in s.toLowerCase().split('')) {
      buf.write(mapa[ch] ?? ch);
    }
    return buf.toString();
  }

  // Litera wpisana przez gracza na pozycji i (albo odsloniona)
  String _literaGracza(int i) {
    if (_odsloniete[i]) return _biezace.slowo[i];
    return _pola[i].text;
  }

  void _sprawdz() {
    final litery = _biezace.slowo.split('');
    final zbudowane = StringBuffer();
    for (int i = 0; i < litery.length; i++) {
      zbudowane.write(_literaGracza(i));
    }
    if (_normalizuj(zbudowane.toString()) == _normalizuj(_biezace.slowo)) {
      setState(() => _zgadniete = true);
    } else {
      // Pokaz krotki komunikat i podswietl bledy
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Jeszcze nie tak. Spróbuj jeszcze raz!'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  void _poddajSie() {
    setState(() => _poddane = true);
  }

  void _nastepne() {
    setState(() {
      // sprzataj stare kontrolery
      for (final c in _pola) {
        c.dispose();
      }
      for (final f in _ogniska) {
        f.dispose();
      }
      _pozycja++;
      if (_pozycja >= _kolejnosc.length) {
        // przejrzano wszystkie - tasujemy od nowa
        _kolejnosc.shuffle(_rng);
        _pozycja = 0;
      }
      _przygotujSlowo();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Zgadywanka'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 8),
              // Podpowiedz
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.tloJasniejsze,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb_outline,
                            color: AppColors.bursztyn, size: 20),
                        const SizedBox(width: 8),
                        Text('Podpowiedź',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.bursztyn)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _biezace.podpowiedz,
                      style: const TextStyle(
                          fontSize: 18,
                          height: 1.35,
                          color: AppColors.tekst),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Pola liter
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: _polaLiter(),
                  ),
                ),
              ),
              // Przyciski
              _przyciski(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _polaLiter() {
    final n = _biezace.slowo.length;
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: List.generate(n, (i) {
        final odsloniona = _odsloniete[i];
        final koniec = _zgadniete || _poddane;

        if (odsloniona || koniec) {
          // Litera pokazana (odsloniona od poczatku, albo po zakonczeniu)
          final poprawna = _biezace.slowo[i];
          final gracz = _literaGracza(i);
          // Po poddaniu podswietl na czerwono litery, ktorych gracz nie wpisal
          final blad = _poddane &&
              !odsloniona &&
              _normalizuj(gracz) != _normalizuj(poprawna);
          return _kafelekLitery(
            poprawna,
            tlo: odsloniona
                ? AppColors.tlo
                : (_zgadniete
                    ? AppColors.zielen.withOpacity(0.3)
                    : (blad
                        ? AppColors.koral.withOpacity(0.3)
                        : AppColors.tlo)),
            kolorTekstu: odsloniona
                ? AppColors.tekstSzary
                : AppColors.tekst,
          );
        }

        // Puste pole do wpisania
        return SizedBox(
          width: 44,
          height: 56,
          child: TextField(
            controller: _pola[i],
            focusNode: _ogniska[i],
            textAlign: TextAlign.center,
            maxLength: 1,
            style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AppColors.tekst),
            decoration: InputDecoration(
              counterText: '',
              contentPadding: EdgeInsets.zero,
              filled: true,
              fillColor: AppColors.tloJasniejsze,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    BorderSide(color: AppColors.bursztyn.withOpacity(0.4)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: AppColors.bursztyn, width: 2),
              ),
            ),
            onChanged: (v) {
              // Po wpisaniu litery przejdz do nastepnego pustego pola
              if (v.isNotEmpty) _nastepnePole(i);
            },
          ),
        );
      }),
    );
  }

  Widget _kafelekLitery(String litera,
      {required Color tlo, required Color kolorTekstu}) {
    return Container(
      width: 44,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: tlo,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        litera,
        style: TextStyle(
            fontSize: 26, fontWeight: FontWeight.bold, color: kolorTekstu),
      ),
    );
  }

  void _nastepnePole(int od) {
    for (int j = od + 1; j < _biezace.slowo.length; j++) {
      if (!_odsloniete[j]) {
        _ogniska[j].requestFocus();
        return;
      }
    }
    // brak kolejnych - schowaj klawiature
    FocusScope.of(context).unfocus();
  }

  Widget _przyciski() {
    if (_zgadniete) {
      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, color: AppColors.zielen, size: 26),
              const SizedBox(width: 8),
              const Text('Brawo! Zgadłeś!',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.zielen)),
            ],
          ),
          const SizedBox(height: 12),
          _duzyPrzycisk('Następne słowo', AppColors.zielen, _nastepne),
        ],
      );
    }
    if (_poddane) {
      return Column(
        children: [
          Text('Prawidłowe słowo to: ${_biezace.slowo}',
              style: const TextStyle(
                  fontSize: 17, color: AppColors.tekst)),
          const SizedBox(height: 12),
          _duzyPrzycisk('Następne słowo', AppColors.bursztyn, _nastepne),
        ],
      );
    }
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _poddajSie,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: AppColors.tekstSzary),
            ),
            child: const Text('Poddaję się',
                style: TextStyle(color: AppColors.tekstSzary, fontSize: 16)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: _duzyPrzycisk('Sprawdź', AppColors.bursztyn, _sprawdz),
        ),
      ],
    );
  }

  Widget _duzyPrzycisk(String tekst, Color kolor, VoidCallback onTap) {
    return SizedBox(
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
            style:
                const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
