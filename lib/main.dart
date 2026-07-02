import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'games/tic_tac_toe.dart';
import 'games/connect_four.dart';
import 'games/reaction_duel.dart';
import 'games/tap_battle.dart';
import 'games/zgadywanka.dart';
import 'games/simon.dart';
import 'games/popit.dart';

void main() {
  runApp(const GryApp());
}

class GryApp extends StatelessWidget {
  const GryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gry podróżne',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const MenuScreen(),
    );
  }
}

// Opis pojedynczej gry w menu
class GameEntry {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final Widget Function() builder;

  const GameEntry({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.builder,
  });
}

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  static final List<GameEntry> games = [
    GameEntry(
      title: 'Kółko i krzyżyk',
      subtitle: '2 graczy · klasyka na 3 w rzędzie',
      icon: Icons.grid_3x3,
      accent: AppColors.bursztyn,
      builder: () => const TicTacToeScreen(),
    ),
    GameEntry(
      title: 'Czwórki',
      subtitle: '2 graczy · ułóż 4 w linii',
      icon: Icons.view_column,
      accent: AppColors.koral,
      builder: () => const ConnectFourScreen(),
    ),
    GameEntry(
      title: 'Pojedynek refleksu',
      subtitle: '2 graczy · kto szybciej, gdy zmieni kolor',
      icon: Icons.bolt,
      accent: AppColors.zielen,
      builder: () => const ReactionDuelScreen(),
    ),
    GameEntry(
      title: 'Bitwa klikania',
      subtitle: '2 graczy · kto więcej w 10 sekund',
      icon: Icons.touch_app,
      accent: AppColors.fiolet,
      builder: () => const TapBattleScreen(),
    ),
    GameEntry(
      title: 'Zgadywanka',
      subtitle: 'Dla 1 gracza · odgadnij słowo z podpowiedzi',
      icon: Icons.abc,
      accent: AppColors.bursztyn,
      builder: () => const ZgadywankaScreen(),
    ),
    GameEntry(
      title: 'Simon',
      subtitle: '1 gracz · zapamiętaj i powtórz kolory',
      icon: Icons.gamepad,
      accent: AppColors.zielen,
      builder: () => const SimonScreen(),
    ),
    GameEntry(
      title: 'Szybkie klikanie',
      subtitle: '1 gracz · klikaj podświetlone kółka na czas',
      icon: Icons.ads_click,
      accent: AppColors.koral,
      builder: () => const PopItScreen(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              const Text(
                'Gry podróżne',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: AppColors.tekst,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Jeden telefon, dwoje graczy. Podajcie sobie ekran.',
                style: TextStyle(fontSize: 15, color: AppColors.tekstSzary),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ShaderMask(
                  shaderCallback: (rect) {
                    return const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black,
                        Colors.black,
                        Colors.transparent,
                      ],
                      stops: [0.0, 0.03, 0.92, 1.0],
                    ).createShader(rect);
                  },
                  blendMode: BlendMode.dstIn,
                  child: ListView.separated(
                    padding: const EdgeInsets.only(top: 4, bottom: 20),
                    itemCount: games.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (_, i) => _GameTile(entry: games[i]),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GameTile extends StatelessWidget {
  final GameEntry entry;
  const _GameTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.tloJasniejsze,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => entry.builder()),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: entry.accent.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(entry.icon, color: entry.accent, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.title,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w600,
                        color: AppColors.tekst,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      entry.subtitle,
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: AppColors.tekstSzary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: entry.accent),
            ],
          ),
        ),
      ),
    );
  }
}
