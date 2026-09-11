import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import 'dart:math';
import '../app_theme.dart';
import '../rekordy.dart';

class BalonScreen extends StatefulWidget {
  const BalonScreen({super.key});

  @override
  State<BalonScreen> createState() => _BalonScreenState();
}

enum _Faza { start, gra, koniec }

class _BalonScreenState extends State<BalonScreen>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _ostatni = Duration.zero;
  final _rng = Random();

  _Faza _faza = _Faza.start;

  // UKLAD WSPOLRZEDNYCH
  // Polozenie w poziomie (x) = ulamek SZEROKOSCI pola.
  // Polozenie w pionie (y) i WSZYSTKIE ROZMIARY = ulamek WYSOKOSCI pola.
  //   Dzieki temu balon, kulki i platformy nie rozciagaja sie na boki
  //   po obroceniu telefonu - maja te same proporcje co w pionie.
  static const double balonY = 0.62; // stala wysokosc balonu na ekranie
  static const double balonPromien = 0.039; // promien (ulamek wysokosci)
  static const double kulkaPromien = 0.012;
  static const double platformaGrubosc = 0.02;

  double _balonX = 0.5; // pozycja pozioma (0..1 szerokosci)

  final List<_Platforma> _platformy = [];
  final List<_Kulka> _kulki = [];

  double _predkosc = 0.30; // ulamek wysokosci na sekunde
  double _doNastepnej = 0;

  int _wynik = 0;
  int _rekord = 0;

  double _szerPola = 1;
  double _wysPola = 1;

  // 1 jednostka rozmiaru (wysokosc pola) wyrazona w ulamku szerokosci
  double get _naSzerokosc => _wysPola / _szerPola;
  // Szerokosc pola wyrazona w jednostkach rozmiaru
  double get _szerWJednostkach => _szerPola / _wysPola;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tik);
    // Ta gra MOZE sie obracac.
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    _ticker.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  void _nowaGra() {
    setState(() {
      _faza = _Faza.gra;
      _balonX = 0.5;
      _platformy.clear();
      _kulki.clear();
      _predkosc = 0.30;
      _doNastepnej = 0.3;
      _wynik = 0;
    });
    _ostatni = Duration.zero;
    _ticker.stop();
    _ticker.start();
  }

  void _tik(Duration czas) {
    if (_ostatni == Duration.zero) {
      _ostatni = czas;
      return;
    }
    final dt = (czas - _ostatni).inMicroseconds / 1e6;
    _ostatni = czas;
    if (_faza != _Faza.gra) return;

    for (final p in _platformy) {
      p.y += _predkosc * dt;
    }
    for (final k in _kulki) {
      k.y += _predkosc * dt;
    }
    _platformy.removeWhere((p) => p.y > 1.2);
    _kulki.removeWhere((k) => k.y > 1.2 || k.zebrana);

    _doNastepnej -= _predkosc * dt;
    if (_doNastepnej <= 0) {
      _nowaFala();
      _doNastepnej = 0.32 + _rng.nextDouble() * 0.16;
    }

    _predkosc += 0.010 * dt;

    // Zbieranie kulek - odleglosc liczona w jednostkach rozmiaru,
    // wiec x trzeba przeliczyc ze szerokosci na te jednostki.
    for (final k in _kulki) {
      if (k.zebrana) continue;
      final dx = (k.x - _balonX).abs() / _naSzerokosc;
      final dy = (k.y - balonY).abs();
      if (dx < balonPromien + kulkaPromien + 0.012 &&
          dy < balonPromien + kulkaPromien + 0.012) {
        k.zebrana = true;
        _wynik += 1;
      }
    }

    if (_kolizja()) {
      _koniec();
      return;
    }

    setState(() {});
  }

  // Nowa fala przeszkod. Im szersze pole (telefon w poziomie),
  // tym wiecej platform i kulek - zeby gestosc byla taka sama jak w pionie.
  void _nowaFala() {
    final szer = _szerWJednostkach;

    final ilePlatform =
        max(1, (szer * (2.2 + _rng.nextDouble() * 1.5)).round());
    for (int i = 0; i < ilePlatform; i++) {
      final szerPlat = 0.085 + _rng.nextDouble() * 0.070; // w jednostkach
      final double szerPlatUlamek =
          (szerPlat * _naSzerokosc).clamp(0.05, 0.9).toDouble();
      _platformy.add(_Platforma(
        x: _rng.nextDouble() * (1 - szerPlatUlamek),
        szer: szerPlat,
        y: -0.03 - _rng.nextDouble() * 0.12,
      ));
    }

    final int ileKulek = (szer * 5.8).round().clamp(2, 14).toInt();
    for (int i = 0; i < ileKulek; i++) {
      _kulki.add(_Kulka(
        x: 0.06 + _rng.nextDouble() * 0.88,
        y: -0.05 - 0.12 * _rng.nextDouble(),
      ));
    }
  }

  bool _kolizja() {
    for (final p in _platformy) {
      final wPionie =
          (p.y - balonY).abs() < balonPromien + platformaGrubosc / 2;
      if (!wPionie) continue;
      // Zakres platformy w ulamkach szerokosci
      final platLewy = p.x;
      final platPrawy = p.x + p.szer * _naSzerokosc;
      final balonLewy = _balonX - balonPromien * 0.7 * _naSzerokosc;
      final balonPrawy = _balonX + balonPromien * 0.7 * _naSzerokosc;
      if (balonPrawy > platLewy && balonLewy < platPrawy) return true;
    }
    return false;
  }

  void _koniec() {
    _ticker.stop();
    setState(() {
      _faza = _Faza.koniec;
      if (_wynik > _rekord) _rekord = _wynik;
    });
    Rekordy.zglos(context, Gry.balon, _wynik);
  }

  void _przesun(double dx, double szerPola) {
    if (_faza != _Faza.gra) return;
    setState(() {
      _balonX += dx / szerPola;
      final double margines =
          (balonPromien * _naSzerokosc).clamp(0.0, 0.45).toDouble();
      _balonX = _balonX.clamp(margines, 1 - margines).toDouble();
    });
  }

  @override
  Widget build(BuildContext context) {
    final poziomo =
        MediaQuery.of(context).orientation == Orientation.landscape;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Balon'),
        toolbarHeight: poziomo ? 40 : null,
        actions: [
          const RekordyPrzycisk(gra: Gry.balon),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Nowa gra',
            onPressed: _nowaGra,
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          _szerPola = constraints.maxWidth;
          _wysPola = constraints.maxHeight;
          final szer = constraints.maxWidth;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragUpdate: (d) => _przesun(d.delta.dx, szer),
            onTapDown: (_) {
              if (_faza != _Faza.gra) _nowaGra();
            },
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _BalonPainter(
                      balonX: _balonX,
                      platformy: _platformy,
                      kulki: _kulki,
                      bursztyn: AppColors.bursztyn,
                      koral: AppColors.koral,
                      zielen: AppColors.zielen,
                      fiolet: AppColors.fiolet,
                      tlo: AppColors.tlo,
                      tekstSzary: AppColors.tekstSzary,
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 16,
                  child: Text(
                    'Rekord $_rekord   Punkty $_wynik',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.tekstSzary,
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
              koniec ? 'Koniec gry' : 'Balon',
              style: TextStyle(
                  fontSize: poziomo ? 21 : 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.tekst),
            ),
            const SizedBox(height: 8),
            Text(
              koniec
                  ? 'Zebrane punkty: $_wynik   Rekord: $_rekord'
                  : 'Przesuwaj balon palcem w bok.\n'
                      'Wlatuj w przerwy i zbieraj kółka!',
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

class _Platforma {
  double y; // ulamek wysokosci
  final double x; // ulamek szerokosci (lewa krawedz)
  final double szer; // ulamek WYSOKOSCI (nie szerokosci!)
  _Platforma({required this.y, required this.x, required this.szer});
}

class _Kulka {
  final double x;
  double y;
  bool zebrana = false;
  _Kulka({required this.x, required this.y});
}

class _BalonPainter extends CustomPainter {
  final double balonX;
  final List<_Platforma> platformy;
  final List<_Kulka> kulki;
  final Color bursztyn, koral, zielen, fiolet, tlo, tekstSzary;

  _BalonPainter({
    required this.balonX,
    required this.platformy,
    required this.kulki,
    required this.bursztyn,
    required this.koral,
    required this.zielen,
    required this.fiolet,
    required this.tlo,
    required this.tekstSzary,
  });

  static const double balonY = 0.62;
  static const double balonPromien = 0.039;
  static const double kulkaPromien = 0.012;
  static const double platformaGrubosc = 0.02;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Platformy - polozenie w poziomie od szerokosci, rozmiar od wysokosci
    final farbaPlat = Paint()..color = koral;
    for (final p in platformy) {
      final py = p.y * h;
      final gr = platformaGrubosc * h;
      final px = p.x * w;
      final szerP = p.szer * h;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(px, py - gr / 2, szerP, gr),
          Radius.circular(gr * 0.3),
        ),
        farbaPlat,
      );
      final ileZabkow = (szerP / (gr * 1.4)).floor().clamp(2, 20);
      final szerZabka = szerP / ileZabkow;
      for (int i = 0; i < ileZabkow; i++) {
        final zx = px + i * szerZabka;
        final zab = Path()
          ..moveTo(zx, py + gr / 2)
          ..lineTo(zx + szerZabka / 2, py + gr / 2 + gr * 0.9)
          ..lineTo(zx + szerZabka, py + gr / 2)
          ..close();
        canvas.drawPath(zab, farbaPlat);
      }
    }

    // Kulki
    final farbaKulka = Paint()..color = bursztyn;
    final obwodka = Paint()
      ..color = bursztyn
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (final k in kulki) {
      if (k.zebrana) continue;
      final kx = k.x * w;
      final ky = k.y * h;
      final r = kulkaPromien * h;
      canvas.drawCircle(Offset(kx, ky), r, farbaKulka);
      canvas.drawCircle(Offset(kx, ky), r + 3, obwodka);
    }

    // Balon
    _rysujBalon(canvas, balonX * w, balonY * h, balonPromien * h);
  }

  void _rysujBalon(Canvas canvas, double cx, double cy, double r) {
    final farba = Paint()..color = zielen;
    final czasza = Rect.fromCenter(
        center: Offset(cx, cy - r * 0.2), width: r * 2, height: r * 2.1);
    canvas.drawArc(czasza, 0, 3.14159 * 2, true, farba);

    final pas = Paint()..color = fiolet.withOpacity(0.7);
    final pasPath = Path()
      ..moveTo(cx, cy - r * 1.25)
      ..quadraticBezierTo(cx - r * 0.5, cy - r * 0.2, cx, cy + r * 0.85)
      ..quadraticBezierTo(cx + r * 0.5, cy - r * 0.2, cx, cy - r * 1.25)
      ..close();
    canvas.drawPath(pasPath, pas);

    final kosz = Paint()..color = bursztyn;
    final koszRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
          center: Offset(cx, cy + r * 1.15), width: r * 0.7, height: r * 0.5),
      Radius.circular(r * 0.1),
    );
    final linka = Paint()
      ..color = tekstSzary
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(cx - r * 0.5, cy + r * 0.7),
        Offset(cx - r * 0.28, cy + r * 0.95), linka);
    canvas.drawLine(Offset(cx + r * 0.5, cy + r * 0.7),
        Offset(cx + r * 0.28, cy + r * 0.95), linka);
    canvas.drawRRect(koszRect, kosz);
  }

  @override
  bool shouldRepaint(covariant _BalonPainter old) => true;
}
