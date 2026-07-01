import 'package:flutter/material.dart';
import '../app_theme.dart';

class TicTacToeScreen extends StatefulWidget {
  const TicTacToeScreen({super.key});

  @override
  State<TicTacToeScreen> createState() => _TicTacToeScreenState();
}

class _TicTacToeScreenState extends State<TicTacToeScreen> {
  // null = puste, 'X' lub 'O'
  List<String?> _board = List.filled(9, null);
  String _current = 'X';
  String? _winner; // 'X', 'O' albo 'remis'
  List<int>? _winLine; // indeksy zwycieskiej linii (do podswietlenia)

  static const _lines = [
    [0, 1, 2], [3, 4, 5], [6, 7, 8], // wiersze
    [0, 3, 6], [1, 4, 7], [2, 5, 8], // kolumny
    [0, 4, 8], [2, 4, 6], // skosy
  ];

  Color _markColor(String mark) =>
      mark == 'X' ? AppColors.gracz1 : AppColors.gracz2;

  void _tap(int i) {
    if (_board[i] != null || _winner != null) return;
    setState(() {
      _board[i] = _current;
      _checkEnd();
      if (_winner == null) {
        _current = _current == 'X' ? 'O' : 'X';
      }
    });
  }

  void _checkEnd() {
    for (final line in _lines) {
      final a = _board[line[0]];
      if (a != null && a == _board[line[1]] && a == _board[line[2]]) {
        _winner = a;
        _winLine = line;
        return;
      }
    }
    if (!_board.contains(null)) _winner = 'remis';
  }

  void _reset() {
    setState(() {
      _board = List.filled(9, null);
      _current = 'X';
      _winner = null;
      _winLine = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kółko i krzyżyk'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Nowa gra',
            onPressed: _reset,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _statusBar(),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: _grid(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _statusBar() {
    String text;
    Color color;
    if (_winner == null) {
      text = 'Tura gracza';
      color = _markColor(_current);
    } else if (_winner == 'remis') {
      text = 'Remis!';
      color = AppColors.tekstSzary;
    } else {
      text = 'Wygrywa';
      color = _markColor(_winner!);
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.tloJasniejsze,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(text,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.tekst)),
          if (_winner != 'remis') ...[
            const SizedBox(width: 12),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.18),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  _winner ?? _current,
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: color),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _grid() {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: 9,
      itemBuilder: (_, i) {
        final mark = _board[i];
        final isWin = _winLine?.contains(i) ?? false;
        return GestureDetector(
          onTap: () => _tap(i),
          child: Container(
            decoration: BoxDecoration(
              color: isWin
                  ? (_winner != null
                      ? _markColor(_winner!).withOpacity(0.25)
                      : AppColors.tloJasniejsze)
                  : AppColors.tloJasniejsze,
              borderRadius: BorderRadius.circular(16),
              border: isWin
                  ? Border.all(color: _markColor(_winner!), width: 3)
                  : null,
            ),
            child: Center(
              child: mark == null
                  ? null
                  : Text(
                      mark,
                      style: TextStyle(
                        fontSize: 64,
                        fontWeight: FontWeight.bold,
                        color: _markColor(mark),
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }
}
