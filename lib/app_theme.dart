import 'package:flutter/material.dart';

class AppColors {
  static const tlo = Color(0xFF101827);
  static const tloJasniejsze = Color(0xFF1D293C);
  static const tekst = Color(0xFFF2F5FA);
  static const tekstSzary = Color(0xFFA9B7CC);
  static const bursztyn = Color(0xFFF1BC68);
  static const koral = Color(0xFFF1828D);
  static const zielen = Color(0xFF6BD4B3);
  static const fiolet = Color(0xFFA89AF3);
  static const gracz1 = zielen;
  static const gracz2 = koral;
}

class AppTheme {
  static BoxDecoration panel([Color accent = AppColors.fiolet]) =>
      BoxDecoration(
        gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.alphaBlend(
                  accent.withOpacity(0.08), AppColors.tloJasniejsze),
              AppColors.tloJasniejsze
            ]),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accent.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 18,
              offset: const Offset(0, 6))
        ],
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.transparent,
        colorScheme: const ColorScheme.dark(
            surface: AppColors.tlo,
            primary: AppColors.bursztyn,
            secondary: AppColors.zielen,
            onSurface: AppColors.tekst,
            onPrimary: AppColors.tlo),
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            foregroundColor: AppColors.tekst,
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: false,
            titleTextStyle:
                TextStyle(fontSize: 21, fontWeight: FontWeight.w700)),
        elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
                elevation: 0,
                minimumSize: const Size(48, 48),
                textStyle:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)))),
        outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
                minimumSize: const Size(44, 44),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)))),
        dialogTheme: DialogTheme(
            backgroundColor: AppColors.tloJasniejsze,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24))),
        cardTheme: CardTheme(
            color: AppColors.tloJasniejsze,
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20))),
        snackBarTheme: SnackBarThemeData(
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.tloJasniejsze,
            contentTextStyle: const TextStyle(color: AppColors.tekst),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14))),
      );
}

class GameBackdrop extends StatelessWidget {
  final Widget child;
  const GameBackdrop({super.key, required this.child});
  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: const BoxDecoration(
            gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF18253B), AppColors.tlo, Color(0xFF151D30)],
        )),
        child: child,
      );
}
