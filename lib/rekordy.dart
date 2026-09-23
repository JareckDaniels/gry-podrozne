import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart';

// Opis jednej gry na potrzeby tabeli rekordow.
class Gra {
  final String klucz; // nazwa pod ktora zapisujemy w pamieci telefonu
  final String nazwa; // tytul w okienku
  final String jednostka; // np. 'pkt', 'm', 'poziom'
  final bool mniejLepiej; // true = nizszy wynik jest lepszy (czas reakcji)
  const Gra(this.klucz, this.nazwa, this.jednostka, {this.mniejLepiej = false});
}

// Lista gier, ktore maja tabele rekordow.
class Gry {
  static const arkanoid = Gra('arkanoid', 'Arkanoid', 'pkt');
  static const snake = Gra('snake', 'Wąż', 'pkt');
  static const biegacz = Gra('biegacz', 'Biegacz', 'm');
  static const balon = Gra('balon', 'Balon', 'pkt');
  static const simon = Gra('simon', 'Simon', 'poziom');
  static const popit = Gra('popit', 'Szybkie klikanie', 'poziom');
  static const bitwa = Gra('bitwa', 'Bitwa klikania', 'kliknięć');
  static const refleks =
      Gra('refleks', 'Pojedynek refleksu', 'ms', mniejLepiej: true);
  static const zgadywanka = Gra('zgadywanka', 'Zgadywanka', 'słów');
}

// Ustawienia są niezależne od zapisanych wyników: wyłączenie niczego nie kasuje.
class UstawieniaRekordow extends ChangeNotifier {
  static final instance = UstawieniaRekordow();
  static const _klucz = 'high_score_wylaczone_gry';
  static const gry = [
    Gry.refleks, Gry.bitwa, Gry.zgadywanka, Gry.simon,
    Gry.popit, Gry.biegacz, Gry.balon, Gry.snake, Gry.arkanoid,
  ];
  Set<String> _wylaczone = {};

  bool wlaczone(Gra gra) => !_wylaczone.contains(gra.klucz);
  bool get wszystkieWlaczone => gry.every(wlaczone);
  int get liczbaWlaczonych => gry.where(wlaczone).length;

  Future<void> wczytaj() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _wylaczone = (prefs.getStringList(_klucz) ?? <String>[]).toSet();
      notifyListeners();
    } catch (_) {
      // Brak ustawień zachowuje dotychczasowe działanie aplikacji.
    }
  }

  Future<void> ustaw(bool wartosc, {Gra? gra}) async {
    final nowe = Set<String>.from(_wylaczone);
    for (final g in gra == null ? gry : [gra]) {
      if (wartosc) {
        nowe.remove(g.klucz);
      } else {
        nowe.add(g.klucz);
      }
    }
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setStringList(_klucz, nowe.toList())) {
      throw StateError('Nie udało się zapisać ustawień.');
    }
    _wylaczone = nowe;
    notifyListeners();
  }
}

// Pojedynczy zapisany rekord.
class Wpis {
  final String imie;
  final int wynik;
  final String data;
  const Wpis({required this.imie, required this.wynik, required this.data});

  Map<String, dynamic> doMapy() =>
      {'imie': imie, 'wynik': wynik, 'data': data};

  static Wpis zMapy(Map<String, dynamic> m) {
    final w = m['wynik'];
    return Wpis(
      imie: m['imie'] is String ? m['imie'] as String : '?',
      wynik: w is int ? w : (w is num ? w.toInt() : 0),
      data: m['data'] is String ? m['data'] as String : '',
    );
  }
}

class Rekordy {
  static const int ile = 5; // ile rekordow trzymamy na gre
  static const String _kluczImienia = 'ostatnie_imie';

  static String _klucz(Gra gra) => 'rekordy_${gra.klucz}';

  static String _dzisiaj() {
    final d = DateTime.now();
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '$dd.$mm.${d.year}';
  }

  static void _posortuj(Gra gra, List<Wpis> lista) {
    lista.sort((a, b) => gra.mniejLepiej
        ? a.wynik.compareTo(b.wynik)
        : b.wynik.compareTo(a.wynik));
  }

  // Wczytuje zapisane rekordy. Przy jakimkolwiek problemie zwraca pusta liste,
  // zeby gra nigdy nie wywalila sie przez uszkodzony zapis.
  static Future<List<Wpis>> wczytaj(Gra gra) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tekst = prefs.getString(_klucz(gra));
      if (tekst == null || tekst.isEmpty) return <Wpis>[];
      final dane = jsonDecode(tekst);
      if (dane is! List) return <Wpis>[];
      final lista = <Wpis>[];
      for (final e in dane) {
        if (e is Map) lista.add(Wpis.zMapy(Map<String, dynamic>.from(e)));
      }
      _posortuj(gra, lista);
      return lista;
    } catch (_) {
      return <Wpis>[];
    }
  }

  static Future<void> wyczysc(Gra gra) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_klucz(gra));
    } catch (_) {}
  }

  // Zglasza wynik po skonczonej grze.
  // Okienko z imieniem pojawia sie TYLKO gdy to nowy najlepszy wynik.
  static Future<void> zglos(BuildContext context, Gra gra, int wynik) async {
    if (wynik <= 0 || !UstawieniaRekordow.instance.wlaczone(gra)) return;
    final lista = await wczytaj(gra);
    final czyRekord = lista.isEmpty
        ? true
        : (gra.mniejLepiej
            ? wynik < lista.first.wynik
            : wynik > lista.first.wynik);
    if (!czyRekord) return;
    if (!context.mounted) return;

    final imie = await _zapytajOImie(context, gra, wynik);
    if (imie == null) return;
    final czyste = imie.trim().isEmpty ? 'Bez imienia' : imie.trim();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kluczImienia, czyste);
      lista.add(Wpis(imie: czyste, wynik: wynik, data: _dzisiaj()));
      _posortuj(gra, lista);
      if (lista.length > ile) lista.removeRange(ile, lista.length);
      await prefs.setString(
        _klucz(gra),
        jsonEncode(lista.map((w) => w.doMapy()).toList()),
      );
    } catch (_) {}
  }

  static Future<String?> _zapytajOImie(
      BuildContext context, Gra gra, int wynik) async {
    String poprzednie = '';
    try {
      final prefs = await SharedPreferences.getInstance();
      poprzednie = prefs.getString(_kluczImienia) ?? '';
    } catch (_) {}
    if (!context.mounted) return null;

    final pole = TextEditingController(text: poprzednie);
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.tloJasniejsze,
        title: const Text('Nowy rekord!',
            style: TextStyle(
                color: AppColors.bursztyn, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$wynik ${gra.jednostka} — najlepszy wynik w grze ${gra.nazwa}.',
                style: const TextStyle(color: AppColors.tekstSzary)),
            const SizedBox(height: 14),
            TextField(
              controller: pole,
              autofocus: true,
              maxLength: 14,
              textCapitalization: TextCapitalization.words,
              style: const TextStyle(color: AppColors.tekst),
              decoration: const InputDecoration(
                labelText: 'Kto to zrobił?',
                labelStyle: TextStyle(color: AppColors.tekstSzary),
                counterText: '',
              ),
              onSubmitted: (v) => Navigator.pop(ctx, v),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Pomiń',
                style: TextStyle(color: AppColors.tekstSzary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, pole.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.zielen,
              foregroundColor: Colors.white,
            ),
            child: const Text('Zapisz'),
          ),
        ],
      ),
    );
  }

  // Okienko z tabela najlepszych wynikow.
  static Future<void> pokaz(BuildContext context, Gra gra) async {
    if (!UstawieniaRekordow.instance.wlaczone(gra)) return;
    final lista = await wczytaj(gra);
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.tloJasniejsze,
        title: Text('Najlepsze wyniki',
            style: const TextStyle(
                color: AppColors.tekst, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(gra.nazwa,
                  style: const TextStyle(
                      color: AppColors.tekstSzary, fontSize: 13)),
              const SizedBox(height: 10),
              if (lista.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('Jeszcze nikt nie ustanowił rekordu.',
                      style: TextStyle(color: AppColors.tekstSzary)),
                )
              else
                for (int i = 0; i < lista.length; i++)
                  _wiersz(i + 1, lista[i], gra),
            ],
          ),
        ),
        actions: [
          if (lista.isNotEmpty)
            TextButton(
              onPressed: () async {
                final potwierdzone = await _potwierdz(ctx);
                if (potwierdzone != true) return;
                await wyczysc(gra);
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
              },
              child: const Text('Wyczyść',
                  style: TextStyle(color: AppColors.koral)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Zamknij',
                style: TextStyle(color: AppColors.tekst)),
          ),
        ],
      ),
    );
  }

  static Widget _wiersz(int miejsce, Wpis w, Gra gra) {
    final kolor = miejsce == 1 ? AppColors.bursztyn : AppColors.tekst;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            child: Text('$miejsce.',
                style: const TextStyle(
                    color: AppColors.tekstSzary, fontSize: 14)),
          ),
          Expanded(
            child: Text(w.imie,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: kolor,
                    fontSize: 15,
                    fontWeight:
                        miejsce == 1 ? FontWeight.bold : FontWeight.normal)),
          ),
          Text('${w.wynik} ${gra.jednostka}',
              style: TextStyle(
                  color: kolor,
                  fontSize: 15,
                  fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          SizedBox(
            width: 72,
            child: Text(w.data,
                textAlign: TextAlign.right,
                style: const TextStyle(
                    color: AppColors.tekstSzary, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  static Future<bool?> _potwierdz(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.tloJasniejsze,
        content: const Text('Skasować wszystkie wyniki tej gry?',
            style: TextStyle(color: AppColors.tekst)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Nie',
                style: TextStyle(color: AppColors.tekstSzary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Tak, skasuj',
                style: TextStyle(color: AppColors.koral)),
          ),
        ],
      ),
    );
  }
}

// Guzik do paska gry - pokazuje tabele rekordow.
class RekordyPrzycisk extends StatelessWidget {
  final Gra gra;
  const RekordyPrzycisk({super.key, required this.gra});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: UstawieniaRekordow.instance,
      builder: (context, _) => UstawieniaRekordow.instance.wlaczone(gra)
          ? IconButton(
              icon: const Icon(Icons.emoji_events_outlined),
              tooltip: 'Najlepsze wyniki',
              onPressed: () => Rekordy.pokaz(context, gra),
            )
          : const SizedBox.shrink(),
    );
  }
}
