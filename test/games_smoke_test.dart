import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gry_podrozne/app_theme.dart';
import 'package:gry_podrozne/rekordy.dart';
import 'package:gry_podrozne/games/arkanoid.dart';
import 'package:gry_podrozne/games/balon.dart';
import 'package:gry_podrozne/games/biegacz.dart';
import 'package:gry_podrozne/games/connect_four.dart';
import 'package:gry_podrozne/games/popit.dart';
import 'package:gry_podrozne/games/reaction_duel.dart';
import 'package:gry_podrozne/games/simon.dart';
import 'package:gry_podrozne/games/snake.dart';
import 'package:gry_podrozne/games/tap_battle.dart';
import 'package:gry_podrozne/games/tic_tac_toe.dart';
import 'package:gry_podrozne/games/zgadywanka.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await UstawieniaRekordow.instance.wczytaj();
    await UstawieniaRekordow.instance.ustaw(false);
  });
  Future<void> open(WidgetTester t, Widget game,
      {Size size = const Size(320, 568), double textScale = 1}) async {
    await t.binding.setSurfaceSize(size);
    await t.pumpWidget(MaterialApp(
        theme: AppTheme.dark,
        builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(textScale)),
              child: GameBackdrop(child: child!),
            ),
        home: game));
    await t.pumpAndSettle();
  }

  Future<void> close(WidgetTester t) async {
    await t.pumpWidget(const SizedBox.shrink());
    await t.binding.setSurfaceSize(null);
  }

  final games = <String, Widget>{
    'Kółko i krzyżyk': const TicTacToeScreen(),
    'Czwórki': const ConnectFourScreen(),
    'Refleks': const ReactionDuelScreen(),
    'Bitwa': const TapBattleScreen(),
    'Zgadywanka': const ZgadywankaScreen(),
    'Simon': const SimonScreen(),
    'PopIt': const PopItScreen(),
    'Wąż': const SnakeScreen(),
    'Arkanoid': const ArkanoidScreen(),
    'Balon': const BalonScreen(),
    'Biegacz': const BiegaczScreen(),
  };
  for (final entry in games.entries) {
    testWidgets('${entry.key}: mały ekran bez błędów układu', (t) async {
      await open(t, entry.value);
      expect(t.takeException(), isNull);
      await close(t);
    });
  }
  for (final game in [const BalonScreen(), const BiegaczScreen()]) {
    testWidgets('${game.runtimeType}: poziomo, start i pauza', (t) async {
      await open(t, game, size: const Size(740, 360));
      await t.tap(find.text('Start'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 250));
      await t.tap(find.byTooltip('Pauza'));
      await t.pump();
      expect(find.text('Chwila przerwy'), findsOneWidget);
      expect(t.takeException(), isNull);
      await close(t);
    });
  }
  testWidgets('Simon: wiele szybkich wejść i restart nie pozostawia timerów',
      (t) async {
    await open(t, const SimonScreen());
    await t.tap(find.text('Start'));
    await t.pump(const Duration(milliseconds: 750));
    await t.tap(find.byTooltip('Nowa gra'));
    await t.pump(const Duration(milliseconds: 250));
    await t.tap(find.byTooltip('Pauza'));
    await t.pump();
    expect(find.text('Wznów'), findsOneWidget);
    expect(t.takeException(), isNull);
    await close(t);
  });
  testWidgets('Kółko i krzyżyk: zwycięstwo oraz nowa runda', (t) async {
    await open(t, const TicTacToeScreen());
    for (final index in [0, 3, 1, 4, 2]) {
      await t.tap(find.byKey(ValueKey('tic-$index')));
      await t.pumpAndSettle();
    }
    expect(find.text('Wygrywa'), findsOneWidget);
    await t.tap(find.byTooltip('Nowa gra'));
    await t.pumpAndSettle();
    expect(find.text('Tura gracza'), findsOneWidget);
    await close(t);
  });

  for (final game in [const TicTacToeScreen(), const ConnectFourScreen()]) {
    for (final width in [280.0, 320.0]) {
      for (final scale in [1.0, 1.5]) {
        testWidgets('${game.runtimeType}: szerokość $width, tekst ×$scale',
            (t) async {
          await open(t, game, size: Size(width, 568), textScale: scale);
          expect(find.text('Tura gracza'), findsOneWidget);
          expect(t.takeException(), isNull);
          await close(t);
        });
      }
    }
  }
  testWidgets('Czwórki: zwycięstwo oraz nowa runda', (t) async {
    await open(t, const ConnectFourScreen());
    for (final col in [0, 1, 0, 1, 0, 1, 0]) {
      await t.tap(find.byKey(ValueKey('connect-0-$col')));
      await t.pumpAndSettle();
    }
    expect(find.text('Wygrywa gracz'), findsOneWidget);
    expect(t.takeException(), isNull);
    await t.tap(find.byTooltip('Nowa gra'));
    await t.pumpAndSettle();
    expect(find.text('Tura gracza'), findsOneWidget);
    expect(t.takeException(), isNull);
    await close(t);
  });
}
