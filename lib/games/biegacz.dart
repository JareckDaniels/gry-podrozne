import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import 'dart:math';
import '../app_theme.dart';
import '../rekordy.dart';

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

  // UKLAD WSPOLRZEDNYCH
  // Pozycje w poziomie (x, predkosc) = ulamki SZEROKOSCI pola.
  //   Dzieki temu odstepy miedzy przeszkodami w CZASIE sa takie same
  //   niezaleznie od tego, czy telefon stoi w pionie czy w poziomie.
  // Wszystkie ROZMIARY (postac, przeszkody, ziemia) = ulamki WYSOKOSCI pola.
  //   Dzieki temu nic sie nie rozciaga na boki po obroceniu ekranu -
  //   cala scena zachowuje te same proporcje, tylko jest nizsza.
  static const double postacX = 0.16; // srodek postaci (ulamek szerokosci)
  static const double postacBok = 0.11; // wysokosc postaci (ulamek wysokosci)
  static const double grawitacja = 2.7;
  static const double silaSkoku = 1.154;

  // Rozmiar pola gry - potrzebny, by przeliczac rozmiary (wysokosc)
  // na polozenia (szerokosc). Ustawiany z LayoutBuilder przy kazdym budowaniu.
  double _szerPola = 1;
  double _wysPola = 1;

  // 1 jednostka rozmiaru (czyli 1 x wysokosc pola) wyrazona w ulamku szerokosci
  double get _naSzerokosc => _wysPola / _szerPola;

  double _y = 0; // wysokosc postaci nad ziemia
  double _vy = 0; // predkosc pionowa
  bool _wPowietrzu = false;

  final List<_Przeszkoda> _przeszkody = [];
  double _predkosc = 0.42; // ulamek szerokosci na sekunde
  double _doNastepnej = 0;

  int _wynik = 0;
  int _rekord = 0;
  double _dystans = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tik);
    // Ta gra MOZE sie obracac - odblokowujemy wszystkie polozenia.
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    _ticker.dispose();
    // Wychodzac wracamy do pionu, zeby reszta aplikacji byla zablokowana.
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  void _nowaGra() {
    setState(() {
      _faza = _Faza.gra;
      _y = 0;
      _vy = 0;
      _wPowietrzu = false;
      _przeszkody.clear();
      _predkosc = 0.40;
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
    _przeszkody.removeWhere((p) => p.x < -0.3);

    // Generowanie kolejnych przeszkod
    _doNastepnej -= _predkosc * dt;
    if (_doNastepnej <= 0) {
      final mozeLatajaca = _wynik > 250;
      if (mozeLatajaca && _rng.nextDouble() < 0.35) {
        // Pocisk leci na wysokosci, na ktora wpadniesz skaczac.
        _przeszkody.add(_Przeszkoda(
          x: 1.1,
          wysokosc: 0,
          szerokosc: 0.031 + _rng.nextDouble() * 0.011,
          latajaca: true,
          yDol: 0.13,
          yGora: 0.20,
        ));
      } else {
        final wysoka = _rng.nextBool();
        _przeszkody.add(_Przeszkoda(
          x: 1.1,
          wysokosc: wysoka ? 0.11 : 0.07,
          szerokosc: 0.023 + _rng.nextDouble() * 0.010,
        ));
      }
      _doNastepnej = 0.75 + _rng.nextDouble() * 0.6;
    }

    _predkosc += 0.018 * dt;

    _dystans += _predkosc * dt * 100;
    _wynik = _dystans.floor();

    if (_kolizja()) {
      _koniec();
      return;
    }

    setState(() {});
  }

  bool _kolizja() {
    // Postac: srodek w postacX, szerokosc liczona od jej wysokosci,
    // przeliczona na ulamek szerokosci pola.
    final polSzerPostaci = postacBok * 0.24 * _naSzerokosc;
    final pLewy = postacX - polSzerPostaci;
    final pPrawy = postacX + polSzerPostaci;

    final pyDol = _y; // dol postaci nad ziemia
    final pyGora = _y + postacBok; // gora postaci nad ziemia

    for (final p in _przeszkody) {
      final przLewy = p.x;
      final przPrawy = p.x + p.szerokosc * _naSzerokosc;
      final naklada = pPrawy > przLewy && pLewy < przPrawy;
      if (!naklada) continue;

      if (p.latajaca) {
        if (pyGora > p.yDol && pyDol < p.yGora) return true;
      } else {
        if (pyDol < p.wysokosc) return true;
      }
    }
    return false;
  }

  void _koniec() {
    _ticker.stop();
    setState(() {
      _faza = _Faza.koniec;
      if (UstawieniaRekordow.instance.wlaczone(Gry.biegacz) &&
          _wynik > _rekord) _rekord = _wynik;
    });
    Rekordy.zglos(context, Gry.biegacz, _wynik);
  }

  @override
  Widget build(BuildContext context) {
    final poziomo =
        MediaQuery.of(context).orientation == Orientation.landscape;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Biegacz'),
        // W poziomie wysokosc jest na wage zlota - chudszy pasek.
        toolbarHeight: poziomo ? 40 : null,
        actions: [
          const RekordyPrzycisk(gra: Gry.biegacz),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Nowa gra',
            onPressed: _nowaGra,
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Zapamietujemy rozmiar pola, by fizyka wiedziala,
          // jak przeliczac wysokosc na szerokosc.
          _szerPola = constraints.maxWidth;
          _wysPola = constraints.maxHeight;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (_) => _skok(),
            child: Stack(
              children: [
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
                Positioned(
                  top: 12,
                  right: 16,
                  child: Text(
                    (UstawieniaRekordow.instance.wlaczone(Gry.biegacz)
                        ? 'HI ${_rekord.toString().padLeft(5, '0')}   '
                        : '') +
                    _wynik.toString().padLeft(5, '0'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.tekstSzary,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                if (_faza != _Faza.gra) _nakladka(poziomo),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _nakladka(bool poziomo) {
    final koniec = _faza == _Faza.koniec;
    return Center(
      child: Container(
        padding: EdgeInsets.all(poziomo ? 18 : 28),
        margin: EdgeInsets.all(poziomo ? 16 : 32),
        decoration: BoxDecoration(
          color: AppColors.tloJasniejsze.withOpacity(0.95),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              koniec ? 'Koniec gry' : 'Biegacz',
              style: TextStyle(
                  fontSize: poziomo ? 21 : 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.tekst),
            ),
            const SizedBox(height: 8),
            Text(
              koniec
                  ? 'Wynik: $_wynik${UstawieniaRekordow.instance.wlaczone(Gry.biegacz) ? '   Rekord: $_rekord' : ''}'
                  : 'Dotknij ekran, aby skoczyć.\nOmijaj przeszkody!',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 15, color: AppColors.tekstSzary, height: 1.4),
            ),
            SizedBox(height: poziomo ? 12 : 18),
            ElevatedButton(
              onPressed: _nowaGra,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.zielen,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                    horizontal: 32, vertical: poziomo ? 10 : 14),
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
  double x; // ulamek szerokosci pola
  final double wysokosc; // ulamek wysokosci pola
  final double szerokosc; // ulamek WYSOKOSCI pola (nie szerokosci!)
  final bool latajaca;
  final double yDol;
  final double yGora;
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

    // Przeszkody - pozycja w poziomie od szerokosci, rozmiar od wysokosci
    for (final p in przeszkody) {
      final px = p.x * w;
      final szer = p.szerokosc * h;
      if (p.latajaca) {
        _rysujPocisk(canvas, px, ziemiaY - ((p.yDol + p.yGora) / 2) * h,
            szer, (p.yGora - p.yDol) * h);
      } else {
        _rysujKaktus(canvas, px, ziemiaY, szer, p.wysokosc * h);
      }
    }

    // Postac - ludzik (x = srodek)
    _rysujLudzika(canvas, postacX * w, ziemiaY - y * h, postacBok * h);
  }

  void _rysujKaktus(
      Canvas canvas, double x, double ziemiaY, double szer, double wys) {
    final farba = Paint()..color = zielen;
    final grubosc = szer * 0.55;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x + (szer - grubosc) / 2, ziemiaY - wys, grubosc, wys),
        Radius.circular(grubosc * 0.5),
      ),
      farba,
    );
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

  void _rysujPocisk(
      Canvas canvas, double x, double srodekY, double szer, double wys) {
    final farba = Paint()..color = koral;
    final cx = x + szer / 2;
    final dlugosc = szer * 0.95;
    final grubosc = wys * 0.52;
    final lewy = cx - dlugosc / 2;
    final prawy = cx + dlugosc / 2;
    final gora = srodekY - grubosc / 2;

    final granicaCzubka = lewy + dlugosc * 0.42;

    final luska = RRect.fromRectAndCorners(
      Rect.fromLTRB(granicaCzubka, gora, prawy, gora + grubosc),
      topRight: Radius.circular(grubosc * 0.12),
      bottomRight: Radius.circular(grubosc * 0.12),
    );
    canvas.drawRRect(luska, farba);

    final czubek = Path()
      ..moveTo(granicaCzubka, gora)
      ..lineTo(lewy + dlugosc * 0.06, gora + grubosc * 0.14)
      ..quadraticBezierTo(
          lewy, srodekY, lewy + dlugosc * 0.06, gora + grubosc * 0.86)
      ..lineTo(granicaCzubka, gora + grubosc)
      ..close();
    canvas.drawPath(czubek, farba);

    final kreska = Paint()
      ..color = koral.withOpacity(0.6)
      ..strokeWidth = grubosc * 0.12
      ..strokeCap = StrokeCap.round;
    final dl = dlugosc * 0.5;
    canvas.drawLine(Offset(prawy + dlugosc * 0.12, srodekY - grubosc * 0.5),
        Offset(prawy + dlugosc * 0.12 + dl, srodekY - grubosc * 0.5), kreska);
    canvas.drawLine(Offset(prawy + dlugosc * 0.18, srodekY),
        Offset(prawy + dlugosc * 0.18 + dl * 0.8, srodekY), kreska);
    canvas.drawLine(Offset(prawy + dlugosc * 0.12, srodekY + grubosc * 0.5),
        Offset(prawy + dlugosc * 0.12 + dl, srodekY + grubosc * 0.5), kreska);
  }

  // cx = SRODEK postaci w poziomie, cyDol = poziom stop, bok = wysokosc postaci
  void _rysujLudzika(Canvas canvas, double cx, double cyDol, double bok) {
    final farba = Paint()
      ..color = bursztyn
      ..style = PaintingStyle.stroke
      ..strokeWidth = bok * 0.11
      ..strokeCap = StrokeCap.round;
    final wypelnienie = Paint()..color = bursztyn;

    final cyGora = cyDol - bok; // czubek glowy

    final rGlowa = bok * 0.2;
    canvas.drawCircle(Offset(cx, cyGora + rGlowa), rGlowa, wypelnienie);

    final szyja = cyGora + rGlowa * 2;
    final biodra = cyDol - bok * 0.28;
    canvas.drawLine(Offset(cx, szyja), Offset(cx, biodra), farba);

    final barki = szyja + bok * 0.08;
    canvas.drawLine(Offset(cx, barki),
        Offset(cx + bok * 0.26, barki + bok * 0.14), farba);
    canvas.drawLine(Offset(cx, barki),
        Offset(cx - bok * 0.24, barki - bok * 0.05), farba);

    canvas.drawLine(Offset(cx, biodra), Offset(cx + bok * 0.2, cyDol), farba);
    canvas.drawLine(Offset(cx, biodra), Offset(cx - bok * 0.18, cyDol), farba);
  }

  @override
  bool shouldRepaint(covariant _BiegaczPainter old) => true;
}
