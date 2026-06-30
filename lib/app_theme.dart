import 'package:flutter/material.dart';

// Wspolna paleta i styl aplikacji "Gry podrozne".
// Tlo: gleboki granat (spokojny, nie meczy oczu w aucie/wieczorem).
// Kazda gra ma swoj zywy kolor-akcent, ale uklad je spina.
class AppColors {
  static const tlo = Color(0xFF161A2B); // gleboki granat
  static const tloJasniejsze = Color(0xFF1F2438); // karty, panele
  static const tekst = Color(0xFFF2F3F8);
  static const tekstSzary = Color(0xFF9AA0B8);

  // Akcenty gier
  static const bursztyn = Color(0xFFE8A33D); // kolko-krzyzyk
  static const koral = Color(0xFFE85D5D); // connect 4 / gracz 2
  static const zielen = Color(0xFF4CB782); // reaction duel
  static const fiolet = Color(0xFF8B7BD8); // tap battle

  // Gracze (wspolne oznaczenia)
  static const gracz1 = Color(0xFF4CB782); // zielony
  static const gracz2 = Color(0xFFE85D5D); // czerwony
}

class AppTheme {
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.tlo,
        colorScheme: const ColorScheme.dark(
          surface: AppColors.tlo,
          primary: AppColors.bursztyn,
        ),
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.tlo,
          foregroundColor: AppColors.tekst,
          elevation: 0,
          centerTitle: true,
        ),
      );
}
