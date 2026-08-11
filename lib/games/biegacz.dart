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
  static const double grawitacja = 2.4; // przyciaganie w dol (mniejsze = dluzszy skok)
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
      _predkosc = 0.34;
      _doNastepnej = 1.1;
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
      // Latajace pojawiaja sie dopiero po pewnym wyniku i rzadziej
      final mozeLatajaca = _wynik > 250;
      if (mozeLatajaca && _rng.nextDouble() < 0.35) {
        // Ptak: leci na wysokosci, na ktora wpadniesz skaczac.
        // Trzeba przebiec pod spodem (nie skakac) albo w luku skoku go minac.
        _przeszkody.add(_Przeszkoda(
          x: 1.1,
          wysokosc: 0,
          szerokosc: 0.06 + _rng.nextDouble() * 0.02,
          latajaca: true,
          yDol: 0.13,
          yGora: 0.20,
        ));
      } else {
        final wysoka = _rng.nextBool();
        _przeszkody.add(_Przeszkoda(
          x: 1.1,
          wysokosc: wysoka ? 0.11 : 0.07,
          szerokosc: 0.045 + _rng.nextDouble() * 0.02,
        ));
      }
      // Odstep losowy - wiekszy, by dac czas na reakcje
      _doNastepnej = 0.75 + _rng.nextDouble() * 0.6;
    }

    // Predkosc rosnie z czasem (powoli)
    _predkosc += 0.008 * dt;

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
    const postacBok = 0.11;
    final px = postacX;
    final pyDol = _y; // dol postaci nad ziemia
    final pyGora = _y + postacBok; // gora postaci nad ziemia

    for (final p in _przeszkody) {
      final naklada = px + postacBok * 0.6 > p.x &&
          px < p.x + p.szerokosc;
      if (!naklada) continue;

      if (p.latajaca) {
        // Kolizja, gdy postac zachodzi na pas wysokosci ptaka
        if (pyGora > p.yDol && pyDol < p.yGora) {
          return true;
        }
      } else {
        // Naziemna: kolizja gdy dol postaci nizej niz szczyt slupka
        if (pyDol < p.wysokosc) {
          return true;
        }
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
  final double wysokosc; // dla naziemnych: wysokosc slupka
  final double szerokosc;
  final bool latajaca; // true = lecaca w powietrzu (jak ptak)
  final double yDol; // dla latajacych: dolna krawedz nad ziemia
  final double yGora; // dla latajacych: gorna krawedz nad ziemia
  _Przeszkoda({
    required this.x,
    required this.wysokosc,
    required this.szerokosc,
    this.latajaca = false,
    this.yDol = 0,
    this.yGora = 0,
  });
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

    // Przeszkody
    for (final p in przeszkody) {
      final px = p.x * w;
      final szer = p.szerokosc * w;
      if (p.latajaca) {
        _rysujPtaka(canvas, px, ziemiaY - ((p.yDol + p.yGora) / 2) * h,
            szer, (p.yGora - p.yDol) * h);
      } else {
        _rysujKaktus(canvas, px, ziemiaY, szer, p.wysokosc * h);
      }
    }

    // Postac - dinozaurek
    _rysujDinozaura(canvas, postacX * w, ziemiaY - y * h, postacBok * h);
  }

  void _rysujKaktus(
      Canvas canvas, double x, double ziemiaY, double szer, double wys) {
    final farba = Paint()..color = zielen;
    final grubosc = szer * 0.55;
    // glowny slup
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x + (szer - grubosc) / 2, ziemiaY - wys, grubosc, wys),
        Radius.circular(grubosc * 0.5),
      ),
      farba,
    );
    // lewe ramie
    final ramieGr = grubosc * 0.7;
    final ramieY = ziemiaY - wys * 0.62;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x - ramieGr * 0.3, ramieY, ramieGr, wys * 0.30),
        Radius.circular(ramieGr * 0.5),
      ),
      farba,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x - ramieGr * 0.3, ramieY, ramieGr * 0.9, ramieGr),
        Radius.circular(ramieGr * 0.5),
      ),
      farba,
    );
    // prawe ramie
    final praweX = x + szer - ramieGr * 0.7;
    final ramieY2 = ziemiaY - wys * 0.48;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(praweX, ramieY2, ramieGr, wys * 0.34),
        Radius.circular(ramieGr * 0.5),
      ),
      farba,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(praweX + ramieGr * 0.1, ramieY2, ramieGr * 0.9, ramieGr),
        Radius.circular(ramieGr * 0.5),
      ),
      farba,
    );
  }

  void _rysujPtaka(
      Canvas canvas, double x, double srodekY, double szer, double wys) {
    final farba = Paint()..color = koral;
    final cx = x + szer / 2;
    // korpus (owalny)
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx, srodekY), width: szer * 0.7, height: wys * 0.7),
      farba,
    );
    // skrzydla (dwa trojkaty w gore i w dol - "w locie")
    final skrzydlo = Path()
      ..moveTo(cx, srodekY)
      ..lineTo(cx - szer * 0.5, srodekY - wys * 0.6)
      ..lineTo(cx - szer * 0.1, srodekY)
      ..close();
    canvas.drawPath(skrzydlo, farba);
    final skrzydlo2 = Path()
      ..moveTo(cx, srodekY)
      ..lineTo(cx + szer * 0.5, srodekY - wys * 0.6)
      ..lineTo(cx + szer * 0.1, srodekY)
      ..close();
    canvas.drawPath(skrzydlo2, farba);
    // dziobek
    final dziob = Path()
      ..moveTo(cx - szer * 0.35, srodekY)
      ..lineTo(cx - szer * 0.55, srodekY - wys * 0.05)
      ..lineTo(cx - szer * 0.35, srodekY + wys * 0.12)
      ..close();
    canvas.drawPath(dziob, Paint()..color = bursztyn);
  }

  void _rysujDinozaura(Canvas canvas, double x, double cyDol, double bok) {
    final cyGora = cyDol - bok;
    final farba = Paint()..color = bursztyn;

    // Korpus (zaokraglony, pionowo owalny)
    final korpus = RRect.fromRectAndRadius(
      Rect.fromLTWH(x, cyGora + bok * 0.15, bok * 0.72, bok * 0.7),
      Radius.circular(bok * 0.22),
    );
    canvas.drawRRect(korpus, farba);

    // Ogon (trojkat z tylu, u dolu)
    final ogon = Path()
      ..moveTo(x + bok * 0.05, cyGora + bok * 0.45)
      ..lineTo(x - bok * 0.35, cyGora + bok * 0.5)
      ..lineTo(x + bok * 0.1, cyGora + bok * 0.85)
      ..close();
    canvas.drawPath(ogon, farba);

    // Glowa (u gory z przodu)
    final glowa = RRect.fromRectAndRadius(
      Rect.fromLTWH(x + bok * 0.42, cyGora, bok * 0.5, bok * 0.42),
      Radius.circular(bok * 0.16),
    );
    canvas.drawRRect(glowa, farba);

    // Pysk (lekko wystajacy)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x + bok * 0.78, cyGora + bok * 0.14, bok * 0.2, bok * 0.2),
        Radius.circular(bok * 0.06),
      ),
      farba,
    );

    // Zabki na grzbiecie (male trojkaty)
    final grzbiet = Paint()..color = bursztyn;
    for (int i = 0; i < 3; i++) {
      final gx = x + bok * (0.15 + i * 0.16);
      final t = Path()
        ..moveTo(gx, cyGora + bok * 0.16)
        ..lineTo(gx + bok * 0.08, cyGora - bok * 0.02)
        ..lineTo(gx + bok * 0.16, cyGora + bok * 0.16)
        ..close();
      canvas.drawPath(t, grzbiet);
    }

    // Oczko
    canvas.drawCircle(
        Offset(x + bok * 0.62, cyGora + bok * 0.16), bok * 0.07,
        Paint()..color = tlo);

    // Nóżka
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x + bok * 0.3, cyDol - bok * 0.12, bok * 0.16, bok * 0.16),
        Radius.circular(bok * 0.04),
      ),
      farba,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x + bok * 0.55, cyDol - bok * 0.12, bok * 0.16, bok * 0.16),
        Radius.circular(bok * 0.04),
      ),
      farba,
    );
  }

  @override
  bool shouldRepaint(covariant _BiegaczPainter old) => true;
}
