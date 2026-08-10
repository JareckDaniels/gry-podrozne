import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'dart:math';
import '../app_theme.dart';

class BiegaczScreen extends StatefulWidget {
  const BiegaczScreen({super.key});

  @override
  State<BiegaczScreen> createState() => _BiegaczScreenState();
}

enum _Faza { start, gra, koniec }

class _BiegaczScreenState extends State<BiegaczScreen>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _ostatni = Duration.zero;

  _Faza _faza = _Faza.start;
  final _rng = Random();

  // Wspolrzedne w "jednostkach gry" (wysokosc pola = 1.0).
  // Postac stoi na ziemi po lewej; y = wysokosc nad ziemia (0 = na ziemi).
  static const double postacX = 0.16; // pozioma pozycja postaci (ulamek szer.)
  static const double grawitacja = 3.6; // przyciaganie w dol
  static const double silaSkoku = 1.35; // predkosc poczatkowa skoku

  double _y = 0; // wysokosc postaci nad ziemia
  double _vy = 0; // predkosc pionowa
  bool _wPowietrzu = false;

  // Przeszkody: lista pozycji X (ulamek szerokosci, od prawej w lewo)
  // oraz ich wysokosc i typ (0 = niska, 1 = wysoka)
  final List<_Przeszkoda> _przeszkody = [];
  double _predkosc = 0.42; // predkosc przesuwania (ulamek szer. na sekunde)
  double _doNastepnej = 0; // odliczanie do kolejnej przeszkody

  int _wynik = 0;
  int _rekord = 0;
  double _dystans = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tik);
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _nowaGra() {
    setState(() {
      _faza = _Faza.gra;
      _y = 0;
      _vy = 0;
      _wPowietrzu = false;
      _przeszkody.clear();
      _predkosc = 0.42;
      _doNastepnej = 0.6;
      _wynik = 0;
      _dystans = 0;
    });
    _ostatni = Duration.zero;
    _ticker.stop();
    _ticker.start();
  }

  void _skok() {
    if (_faza == _Faza.start || _faza == _Faza.koniec) {
      _nowaGra();
      return;
    }
    if (!_wPowietrzu) {
      _vy = silaSkoku;
      _wPowietrzu = true;
    }
  }

  void _tik(Duration czas) {
    if (_ostatni == Duration.zero) {
      _ostatni = czas;
      return;
    }
    final dt = (czas - _ostatni).inMicroseconds / 1e6;
    _ostatni = czas;
    if (_faza != _Faza.gra) return;

    // Fizyka skoku
    _vy -= grawitacja * dt;
    _y += _vy * dt;
    if (_y <= 0) {
      _y = 0;
      _vy = 0;
      _wPowietrzu = false;
    }

    // Ruch przeszkod
    for (final p in _przeszkody) {
      p.x -= _predkosc * dt;
    }
    _przeszkody.removeWhere((p) => p.x < -0.15);

    // Generowanie kolejnych przeszkod
    _doNastepnej -= _predkosc * dt;
    if (_doNastepnej <= 0) {
      final wysoka = _rng.nextBool();
      _przeszkody.add(_Przeszkoda(
        x: 1.1,
        wysokosc: wysoka ? 0.14 : 0.09,
        szerokosc: 0.05 + _rng.nextDouble() * 0.02,
      ));
      // Odstep losowy, ale malejacy z predkoscia (trudniej)
      _doNastepnej = 0.5 + _rng.nextDouble() * 0.5;
    }

    // Predkosc rosnie z czasem
    _predkosc += 0.012 * dt;

    // Wynik = pokonany dystans
    _dystans += _predkosc * dt * 100;
    _wynik = _dystans.floor();

    // Kolizje
    if (_kolizja()) {
      _koniec();
      return;
    }

    setState(() {});
  }

  bool _kolizja() {
    // Prostokat postaci (w ulamkach szerokosci/wysokosci pola)
    // Postac jest kwadratem o boku ~postacBok
    const postacBok = 0.11;
    final px = postacX;
    final pyDol = _y; // wysokosc dolu postaci nad ziemia

    for (final p in _przeszkody) {
      // Przeszkoda: od p.x do p.x+szerokosc, wysokosc od 0 do p.wysokosc
      final naklada = px + postacBok * 0.6 > p.x &&
          px < p.x + p.szerokosc;
      if (naklada && pyDol < p.wysokosc) {
        return true;
      }
    }
    return false;
  }

  void _koniec() {
    _ticker.stop();
    setState(() {
      _faza = _Faza.koniec;
      if (_wynik > _rekord) _rekord = _wynik;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Biegacz'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Nowa gra',
            onPressed: _nowaGra,
          ),
        ],
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _skok(),
        child: Stack(
          children: [
            // Pole gry
            Positioned.fill(
              child: CustomPaint(
                painter: _BiegaczPainter(
                  y: _y,
                  przeszkody: _przeszkody,
                  bursztyn: AppColors.bursztyn,
                  koral: AppColors.koral,
                  zielen: AppColors.zielen,
                  tlo: AppColors.tlo,
                  tekstSzary: AppColors.tekstSzary,
                ),
              ),
            ),
            // Wynik u gory
            Positioned(
              top: 12,
              right: 16,
              child: Text(
                'HI ${_rekord.toString().padLeft(5, '0')}   '
                '${_wynik.toString().padLeft(5, '0')}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.tekstSzary,
                  letterSpacing: 1,
                ),
              ),
            ),
            // Nakladki start / koniec
            if (_faza != _Faza.gra) _nakladka(),
          ],
        ),
      ),
    );
  }

  Widget _nakladka() {
    final koniec = _faza == _Faza.koniec;
    return Center(
      child: Container(
        padding: const EdgeInsets.all(28),
        margin: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.tloJasniejsze.withOpacity(0.95),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              koniec ? 'Koniec gry' : 'Biegacz',
              style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.tekst),
            ),
            const SizedBox(height: 8),
            Text(
              koniec
                  ? 'Wynik: $_wynik   Rekord: $_rekord'
                  : 'Dotknij ekran, aby skoczyć.\nOmijaj przeszkody!',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 15, color: AppColors.tekstSzary, height: 1.4),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: _nowaGra,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.zielen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                koniec ? 'Zagraj jeszcze raz' : 'Start',
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Przeszkoda {
  double x;
  final double wysokosc;
  final double szerokosc;
  _Przeszkoda(
      {required this.x, required this.wysokosc, required this.szerokosc});
}

class _BiegaczPainter extends CustomPainter {
  final double y;
  final List<_Przeszkoda> przeszkody;
  final Color bursztyn, koral, zielen, tlo, tekstSzary;

  _BiegaczPainter({
    required this.y,
    required this.przeszkody,
    required this.bursztyn,
    required this.koral,
    required this.zielen,
    required this.tlo,
    required this.tekstSzary,
  });

  static const double ziemiaOdDolu = 0.16;
  static const double postacX = 0.16;
  static const double postacBok = 0.11;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final ziemiaY = h * (1 - ziemiaOdDolu);

    // Linia ziemi
    final farbaZiemia = Paint()
      ..color = tekstSzary.withOpacity(0.6)
      ..strokeWidth = 2;
    canvas.drawLine(Offset(0, ziemiaY), Offset(w, ziemiaY), farbaZiemia);

    // Przeszkody (geometryczne "kaktusy" - zaokraglone slupki)
    final farbaPrzesz = Paint()..color = koral;
    for (final p in przeszkody) {
      final px = p.x * w;
      final szer = p.szerokosc * w;
      final wys = p.wysokosc * h;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(px, ziemiaY - wys, szer, wys),
        const Radius.circular(4),
      );
      canvas.drawRRect(rect, farbaPrzesz);
      // maly "kolec" z boku dla charakteru kaktusa
      final kolec = Paint()..color = koral;
      final ky = ziemiaY - wys * 0.6;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(px - szer * 0.4, ky, szer * 0.4, wys * 0.28),
          const Radius.circular(3),
        ),
        kolec,
      );
    }

    // Postac (nasz stworek: zaokraglony korpus + oczko + nozki)
    final bok = postacBok * h;
    final cx = postacX * w;
    final cyDol = ziemiaY - y * h; // dol postaci
    final cyGora = cyDol - bok;

    final farbaPostac = Paint()..color = bursztyn;
    // korpus
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx, cyGora, bok * 0.9, bok),
        Radius.circular(bok * 0.28),
      ),
      farbaPostac,
    );
    // ogon (trojkat z tylu) - lekko "gadzia" sylwetka
    final ogon = Path()
      ..moveTo(cx, cyGora + bok * 0.35)
      ..lineTo(cx - bok * 0.35, cyGora + bok * 0.15)
      ..lineTo(cx, cyGora + bok * 0.75)
      ..close();
    canvas.drawPath(ogon, farbaPostac);
    // oczko
    final oko = Paint()..color = tlo;
    canvas.drawCircle(
        Offset(cx + bok * 0.62, cyGora + bok * 0.3), bok * 0.09, oko);
    // nozki (dwa male prostokaty)
    canvas.drawRect(
        Rect.fromLTWH(cx + bok * 0.15, cyDol - bok * 0.06,
            bok * 0.18, bok * 0.12),
        farbaPostac);
    canvas.drawRect(
        Rect.fromLTWH(cx + bok * 0.55, cyDol - bok * 0.06,
            bok * 0.18, bok * 0.12),
        farbaPostac);
  }

  @override
  bool shouldRepaint(covariant _BiegaczPainter old) => true;
}
