import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'rekordy.dart';

class UstawieniaScreen extends StatefulWidget {
  const UstawieniaScreen({super.key});

  @override
  State<UstawieniaScreen> createState() => _UstawieniaScreenState();
}

class _UstawieniaScreenState extends State<UstawieniaScreen> {
  final _ustawienia = UstawieniaRekordow.instance;
  bool _zapisywanie = false;

  Future<void> _ustaw(bool wartosc, {Gra? gra}) async {
    setState(() => _zapisywanie = true);
    try {
      await _ustawienia.ustaw(wartosc, gra: gra);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
            'Nie udało się zapisać ustawień. Spróbuj ponownie.',
          )),
        );
      }
    } finally {
      if (mounted) setState(() => _zapisywanie = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ustawienia')),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _ustawienia,
          builder: (context, _) => ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text('HIGH-SCORE',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.bursztyn,
                  )),
              const SizedBox(height: 8),
              const Text(
                'Włącz lub wyłącz rekordy we wszystkich grach albo wybierz '
                'poszczególne gry. Po wyłączeniu nie pojawiają się tabele '
                'rekordów ani pytania o imię, a nowe rekordy nie są zapisywane. '
                'Dotychczasowe rekordy zostają zachowane.',
                style: TextStyle(color: AppColors.tekstSzary, height: 1.4),
              ),
              const SizedBox(height: 20),
              Card(
                child: SwitchListTile(
                  title: const Text('Wszystkie gry'),
                  subtitle: Text(
                    'Włączone: ${_ustawienia.liczbaWlaczonych} '
                    'z ${UstawieniaRekordow.gry.length}',
                  ),
                  value: _ustawienia.wszystkieWlaczone,
                  onChanged: _zapisywanie ? null : (v) => _ustaw(v),
                ),
              ),
              // Przy mieszanym wyborze oba działania są dostępne jednym kliknięciem.
              Wrap(
                spacing: 8,
                children: [
                  TextButton(
                    onPressed: _zapisywanie ? null : () => _ustaw(true),
                    child: const Text('Włącz wszystkie'),
                  ),
                  TextButton(
                    onPressed: _zapisywanie ? null : () => _ustaw(false),
                    child: const Text('Wyłącz wszystkie'),
                  ),
                ],
              ),
              const Divider(height: 28),
              for (final gra in UstawieniaRekordow.gry)
                SwitchListTile(
                  title: Text(gra.nazwa),
                  value: _ustawienia.wlaczone(gra),
                  onChanged: _zapisywanie ? null : (v) => _ustaw(v, gra: gra),
                ),
              const SizedBox(height: 16),
              const Text(
                'Kółko i krzyżyk oraz Czwórki nie mają tabeli HIGH-SCORE.',
                style: TextStyle(color: AppColors.tekstSzary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
