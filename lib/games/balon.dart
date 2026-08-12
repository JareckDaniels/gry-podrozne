import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'dart:math';
import '../app_theme.dart';

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

  // Wszystko w ulamkach rozmiaru pola (szerokosc/wysokosc = 1.0).
  // Balon trzyma stala wysokosc na ekranie (60% od gory), swiat plynie w dol.
  static const double balonY = 0.62; // pozycja balonu w pionie (staly)
  static const double balonPromien = 0.075; // rozmiar balonu (ulamek szer.)

  double _balonX = 0.5; // pozycja pozioma (0..1), sterowana palcem

  // Przeszkody: KROTKIE poziome platformy rozrzucone w polu (jak w oryginale).
  // Balon je omija, lecac w otwartej przestrzeni.
  final List<_Platforma> _platformy = [];
  // Kolka do zebrania, rozsypane po polu
  final List<_Kulka> _kulki = [];

  double _predkosc = 0.30; // predkosc plyniecia swiata w dol (ulamek wys./s)
  double _doNastepnej = 0; // odliczanie do kolejnej fali przeszkod

  int _wynik = 0;
  int _rekord = 0;

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

    // Swiat plynie w dol: wszystko przesuwamy w dol, balon stoi w miejscu.
    for (final p in _platformy) {
      p.y += _predkosc * dt;
    }
    for (final k in _kulki) {
      k.y += _predkosc * dt;
    }
    _platformy.removeWhere((p) => p.y > 1.2);
    _kulki.removeWhere((k) => k.y > 1.2 || k.zebrana);

    // Generowanie nowych przeszkod (u gory, wplywaja z gory).
    // Za kazdym razem 1-2 krotkie platformy w losowych miejscach + kulki.
    _doNastepnej -= _predkosc * dt;
    if (_doNastepnej <= 0) {
      final ile = 1 + _rng.nextInt(2); // 1 lub 2 platformy naraz
      for (int i = 0; i < ile; i++) {
        final szer = 0.16 + _rng.nextDouble() * 0.14; // krotka platforma
        final x = _rng.nextDouble() * (1 - szer);
        _platformy.add(_Platforma(
          x: x,
          szer: szer,
          y: -0.03 - 0.10 * i,
        ));
      }
      // Kilka kulek rozsypanych w tej strefie (w otwartej przestrzeni)
      final ileKulek = 2 + _rng.nextInt(3);
      for (int i = 0; i < ileKulek; i++) {
        _kulki.add(_Kulka(
          x: 0.1 + _rng.nextDouble() * 0.8,
          y: -0.05 - 0.12 * _rng.nextDouble(),
        ));
      }
      // Odstep do nastepnej fali
      _doNastepnej = 0.32 + _rng.nextDouble() * 0.16;
    }

    // Predkosc rosnie z czasem
    _predkosc += 0.010 * dt;

    // Zbieranie kulek
    for (final k in _kulki) {
      if (k.zebrana) continue;
      final dx = (k.x - _balonX).abs();
      final dy = (k.y - balonY).abs();
      // odleglosc w przyblizeniu (x w ulamkach szer, y w ulamkach wys - ok dla gry)
      if (dx < balonPromien + 0.03 && dy < balonPromien + 0.03) {
        k.zebrana = true;
        _wynik += 1;
      }
    }

    // Kolizja z platforma = koniec
    if (_kolizja()) {
      _koniec();
      return;
    }

    setState(() {});
  }

  bool _kolizja() {
    // Balon: srodek (_balonX, balonY), promien balonPromien.
    // Platforma: krotka belka od p.x do p.x+p.szer, na wysokosci p.y.
    const grubosc = 0.02; // grubosc platformy (ulamek wys.)
    for (final p in _platformy) {
      // Nakladanie w pionie
      final wPionie = (p.y - balonY).abs() < balonPromien + grubosc;
      // Nakladanie w poziomie (balon vs zakres platformy)
      final balonLewy = _balonX - balonPromien * 0.7;
      final balonPrawy = _balonX + balonPromien * 0.7;
      final wPoziomie = balonPrawy > p.x && balonLewy < p.x + p.szer;
      if (wPionie && wPoziomie) return true;
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

  void _przesun(double dx, double szerPola) {
    if (_faza != _Faza.gra) return;
    setState(() {
      _balonX += dx / szerPola;
      _balonX = _balonX.clamp(balonPromien, 1 - balonPromien);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Balon'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Nowa gra',
            onPressed: _nowaGra,
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
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
                // Wynik
                Positioned(
                  top: 12,
                  right: 16,
                  child: Text(
                    'Rekord $_rekord   Punkty $_wynik',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.tekstSzary,
                    ),
                  ),
                ),
                if (_faza != _Faza.gra) _nakladka(),
              ],
            ),
          );
        },
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
              koniec ? 'Koniec gry' : 'Balon',
              style: const TextStyle(
                  fontSize: 26,
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

class _Platforma {
  double y;
  final double x;
  final double szer;
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
  static const double balonPromien = 0.075;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Platformy (krotkie belki z zabkami u dolu - jak w oryginale)
    const grubosc = 0.02;
    final farbaPlat = Paint()..color = koral;
    for (final p in platformy) {
      final py = p.y * h;
      final gr = grubosc * h;
      final px = p.x * w;
      final szerP = p.szer * w;
      // glowna belka
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(px, py - gr / 2, szerP, gr),
          Radius.circular(gr * 0.3),
        ),
        farbaPlat,
      );
      // zabki pod belka (male trojkaty w dol)
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

    // Kulki (punkty)
    final farbaKulka = Paint()..color = bursztyn;
    final obwodka = Paint()
      ..color = bursztyn
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (final k in kulki) {
      if (k.zebrana) continue;
      final kx = k.x * w;
      final ky = k.y * h;
      final r = 0.022 * w;
      canvas.drawCircle(Offset(kx, ky), r, farbaKulka);
      canvas.drawCircle(Offset(kx, ky), r + 3, obwodka);
    }

    // Balon
    _rysujBalon(canvas, balonX * w, balonY * h, balonPromien * w);
  }

  void _rysujBalon(Canvas canvas, double cx, double cy, double r) {
    // Czasza balonu (okrag lekko splaszczony u dolu)
    final farba = Paint()..color = zielen;
    final czasza = Rect.fromCenter(
        center: Offset(cx, cy - r * 0.2), width: r * 2, height: r * 2.1);
    canvas.drawArc(czasza, 0, 3.14159 * 2, true, farba);

    // Pasy na balonie (dla charakteru) - jasniejszy odcien
    final pas = Paint()..color = fiolet.withOpacity(0.7);
    final pasPath = Path()
      ..moveTo(cx, cy - r * 1.25)
      ..quadraticBezierTo(
          cx - r * 0.5, cy - r * 0.2, cx, cy + r * 0.85)
      ..quadraticBezierTo(
          cx + r * 0.5, cy - r * 0.2, cx, cy - r * 1.25)
      ..close();
    canvas.drawPath(pasPath, pas);

    // Kosz (maly prostokat pod balonem)
    final kosz = Paint()..color = bursztyn;
    final koszRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
          center: Offset(cx, cy + r * 1.15),
          width: r * 0.7,
          height: r * 0.5),
      Radius.circular(r * 0.1),
    );
    // Linki od balonu do kosza
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
