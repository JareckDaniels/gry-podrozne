import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gry_podrozne/app_theme.dart';
import 'package:gry_podrozne/games/arkanoid.dart';
import 'package:gry_podrozne/rekordy.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({'arkanoid_odblokowany_poziom': 12});
    await UstawieniaRekordow.instance.wczytaj();
  });

  Future<void> openGame(WidgetTester tester, Size size) async {
    await tester.binding.setSurfaceSize(size);
    await tester.pumpWidget(
        MaterialApp(theme: AppTheme.dark, home: const ArkanoidScreen()));
    await tester.pumpAndSettle();
  }

  testWidgets('Start, ruch, pauza, wznowienie i odblokowane poziomy',
      (tester) async {
    await openGame(tester, const Size(360, 720));
    expect(find.text('Wypuść piłkę'), findsOneWidget);
    await tester.tap(find.text('Wypuść piłkę'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.drag(find.text('←  PRZESUWAJ PALCEM  →'), const Offset(50, 0));
    await tester.tap(find.text('Pauza'));
    await tester.pump();
    expect(find.text('PAUZA'), findsOneWidget);
    await tester.tap(find.text('Wznów'));
    await tester.pump();
    expect(find.text('Pauza'), findsOneWidget);
    await tester.tap(find.byTooltip('Poziomy'));
    await tester.pumpAndSettle();
    expect(find.text('12'), findsOneWidget);
    expect(find.text('13'), findsNothing);
    await tester.tap(find.text('12'));
    await tester.pumpAndSettle();
    expect(find.text('Poziom 12/30'), findsOneWidget);
    expect(find.text('♥ 3'), findsOneWidget);
    expect(find.text('0 pkt'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('Mały ekran i wyłączone rekordy', (tester) async {
    await UstawieniaRekordow.instance.ustaw(false, gra: Gry.arkanoid);
    await openGame(tester, const Size(320, 568));
    expect(find.byTooltip('Najlepsze wyniki'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('Zasady'));
    await tester.pumpAndSettle();
    expect(find.text('Jak grać?'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('Przejście do tła zatrzymuje grę do ręcznego wznowienia',
      (tester) async {
    await openGame(tester, const Size(360, 720));
    await tester.tap(find.text('Wypuść piłkę'));
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    expect(find.text('PAUZA'), findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(find.text('Wznów'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.binding.setSurfaceSize(null);
  });
}
