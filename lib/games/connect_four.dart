import 'package:flutter/material.dart';
import '../app_theme.dart';

class ConnectFourScreen extends StatefulWidget {
  const ConnectFourScreen({super.key});

  @override
  State<ConnectFourScreen> createState() => _ConnectFourScreenState();
}

class _ConnectFourScreenState extends State<ConnectFourScreen> {
  static const cols = 7;
  static const rows = 6;

  // board[r][c]: 0 = puste, 1 = gracz1, 2 = gracz2. Rzad 0 = gora.
  late List<List<int>> _board;
  int _current = 1;
  int? _winner; // 1, 2 albo 0 (remis)
  List<List<int>>? _winCells;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  Color _color(int p) => p == 1 ? AppColors.gracz1 : AppColors.gracz2;

  void _reset() {
    setState(() {
      _board = List.generate(rows, (_) => List.filled(cols, 0));
      _current = 1;
      _winner = null;
      _winCells = null;
    });
  }

  void _drop(int col) {
    if (_winner != null) return;
    // Znajdz najnizszy wolny wiersz w kolumnie
    for (int r = rows - 1; r >= 0; r--) {
      if (_board[r][col] == 0) {
        setState(() {
          _board[r][col] = _current;
          final win = _winningCells(r, col, _current);
          if (win != null) {
            _winner = _current;
            _winCells = win;
          } else if (_isFull()) {
            _winner = 0;
          } else {
            _current = _current == 1 ? 2 : 1;
          }
        });
        return;
      }
    }
  }

  bool _isFull() => !_board[0].contains(0);

  // Sprawdza, czy ruch w (r,c) tworzy 4 w linii; zwraca komorki albo null
  List<List<int>>? _winningCells(int r, int c, int p) {
    const dirs = [
      [0, 1], // poziomo
      [1, 0], // pionowo
      [1, 1], // skos \
      [1, -1], // skos /
    ];
    for (final d in dirs) {
      final cells = <List<int>>[
        [r, c]
      ];
      // w jedna strone
      for (int k = 1; k < 4; k++) {
        final nr = r + d[0] * k, nc = c + d[1] * k;
        if (_inside(nr, nc) && _board[nr][nc] == p) {
          cells.add([nr, nc]);
        } else {
          break;
        }
      }
      // w druga strone
      for (int k = 1; k < 4; k++) {
        final nr = r - d[0] * k, nc = c - d[1] * k;
        if (_inside(nr, nc) && _board[nr][nc] == p) {
          cells.add([nr, nc]);
        } else {
          break;
        }
      }
      if (cells.length >= 4) return cells;
    }
    return null;
  }

  bool _inside(int r, int c) => r >= 0 && r < rows && c >= 0 && c < cols;

  bool _isWinCell(int r, int c) =>
      _winCells?.any((e) => e[0] == r && e[1] == c) ?? false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Czworki'),
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
                  padding: const EdgeInsets.all(12),
                  child: AspectRatio(
                    aspectRatio: cols / rows,
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
      color = _color(_current);
    } else if (_winner == 0) {
      text = 'Remis!';
      color = AppColors.tekstSzary;
    } else {
      text = 'Wygrywa gracz';
      color = _color(_winner!);
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
          if (_winner != 0) ...[
            const SizedBox(width: 14),
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _grid() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.tloJasniejsze,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: List.generate(rows, (r) {
          return Expanded(
            child: Row(
              children: List.generate(cols, (c) {
                final v = _board[r][c];
                final win = _isWinCell(r, c);
                return Expanded(
                  child: GestureDetector(
                    onTap: () => _drop(c),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Container(
                        decoration: BoxDecoration(
                          color: v == 0
                              ? AppColors.tlo
                              : _color(v),
                          shape: BoxShape.circle,
                          border: win
                              ? Border.all(
                                  color: AppColors.tekst, width: 3)
                              : null,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          );
        }),
      ),
    );
  }
}
